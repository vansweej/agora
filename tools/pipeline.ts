import { tool } from "@opencode-ai/plugin";
import { homedir } from "os";
import { join, resolve } from "path";

/**
 * Custom tool that runs an ai-coding pipeline from within OpenCode.
 *
 * The LLM can call this tool when it determines that a pipeline is the right
 * action -- for example, when asked to scaffold a new project or run a dev
 * cycle on a workspace.
 *
 * The monorepo root is resolved from the AI_CODING_MONOREPO environment
 * variable, which is set globally by Home Manager. This allows the tool to
 * work from any project directory.
 *
 * The tool shells out to `bun run pipeline` in the monorepo root and returns
 * the full pipeline output for the LLM to summarise.
 *
 * Bun is resolved by probing known Nix and system locations so the tool
 * works even when OpenCode does not inherit the full login PATH.
 */

/** Candidate locations for the bun binary, in priority order. */
const BUN_CANDIDATES = [
  join(homedir(), ".bun", "bin", "bun"),           // default bun installer (WSL/Linux)
  join(homedir(), ".nix-profile", "bin", "bun"),   // Nix user profile
  "/nix/var/nix/profiles/default/bin/bun",         // Nix system profile
  "/usr/local/bin/bun",
  "/usr/bin/bun",
  "bun", // fallback: rely on PATH
];

async function resolveBun(): Promise<string> {
  for (const candidate of BUN_CANDIDATES) {
    if (await Bun.file(candidate).exists()) {
      return candidate;
    }
  }
  return "bun";
}

export default tool({
  description:
    "Run an ai-coding pipeline (scaffold-rust, scaffold-cpp, rust-plan-cycle). " +
    "Use this when asked to scaffold a new project or execute a pre-written plan.",
  args: {
    name: tool.schema
      .enum([
        "scaffold-rust",
        "scaffold-cpp",
        "rust-plan-cycle",
      ])
      .describe("Pipeline to run"),
    workspace: tool.schema
      .string()
      .describe("Absolute path to an existing local directory. Use '.' for the current project directory. Never invent or guess a path."),
    input: tool.schema
      .string()
      .optional()
      .describe(
        "Optional request text for rust-plan-cycle (e.g. 'Add error handling to the parser')",
      ),
    plan: tool.schema
      .string()
      .optional()
      .describe("Path to a plan file for rust-plan-cycle (e.g. './plan.md'). Resolved to absolute path."),
    maxRetries: tool.schema
      .number()
      .int()
      .min(0)
      .optional()
      .describe("Maximum number of retries for resumable failures (rust-plan-cycle only)."),
    profile: tool.schema
      .enum(["local", "copilot-default", "hybrid"])
      .optional()
      .describe("Model profile to use (local, copilot-default, or hybrid). Defaults to copilot-default if unset."),
  },
  async execute(args) {
    const monorepoRoot = process.env.AI_CODING_MONOREPO;
    if (!monorepoRoot) {
      return (
        "Error: AI_CODING_MONOREPO environment variable is not set. " +
        "It should be set globally by Home Manager to the path of the ai-coding monorepo."
      );
    }

    // Guard: rust-plan-cycle requires either a plan file or input
    if (args.name === "rust-plan-cycle" && !args.plan && !args.input) {
      return (
        "Error: rust-plan-cycle requires either a plan file (--plan) or input text (--input). " +
        "Provide at least one."
      );
    }

    const bunBin = await resolveBun();
    const workspace = resolve(args.workspace);
    const argv = ["run", "pipeline", args.name, workspace];

    // Add plan flag if provided (resolve to absolute path)
    if (args.plan) {
      const absolutePlan = resolve(args.plan);
      argv.push("--plan", absolutePlan);
    }

    // Add input flag if provided
    if (args.input) {
      argv.push("--input", args.input);
    }

    // Add max-retries flag if provided
    if (args.maxRetries !== undefined) {
      argv.push("--max-retries", String(args.maxRetries));
    }

    // Add profile flag if provided (do NOT default it — let CLI and env override handle defaults)
    if (args.profile) {
      argv.push("--profile", args.profile);
    }

    const cmd = `${bunBin} ${argv.join(" ")}`;

    try {
      const proc = await Bun.$`${bunBin} ${argv}`.cwd(monorepoRoot).nothrow().quiet();
      const exitCode = proc.exitCode;

      if (exitCode === 0) {
        // Success
        const output = proc.stdout.toString().trim();
        return output || "Pipeline completed successfully.";
      } else if (exitCode === 2) {
        // Resumable failure
        const output = proc.stdout.toString().trim();
        const stderr = proc.stderr.toString().trim();
        const details = stderr || output || "Unknown error";
        return (
          "Pipeline encountered a resumable failure (exit code 2). " +
          "You can run the pipeline again to resume from where it stopped.\n\n" +
          `Details:\n${details}`
        );
      } else if (exitCode === 3) {
        // Environment/input error (e.g., protected branch)
        const stderr = proc.stderr.toString().trim();
        const output = proc.stdout.toString().trim();
        const details = stderr || output || "Unknown error";
        return (
          "Pipeline encountered an environment or input error (exit code 3). " +
          "Check the workspace, branch, or plan file and try again.\n\n" +
          `Details:\n${details}`
        );
      } else {
        // Other non-zero exit code
        const stderr = proc.stderr.toString().trim();
        const output = proc.stdout.toString().trim();
        const details = stderr || output || "Unknown error";
        return (
          `Pipeline failed with exit code ${exitCode}.\n\n` +
          `Details:\n${details}\n\n` +
          `Command: ${cmd}`
        );
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      return `Pipeline execution error: ${message}\nCommand: ${cmd}`;
    }
  },
});
