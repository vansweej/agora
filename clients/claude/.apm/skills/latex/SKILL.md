---
name: latex
description: >
  Use when working in a LaTeX project or when the task involves LaTeX or TeX
  documents, packages, or bibliographies. Triggers on: latex, tex, .tex,
  latexmk, pdflatex, lualatex, xelatex, bibtex, biblatex, biber, beamer,
  tikz, chktex, latexindent.
---

<!-- DO NOT EDIT — generated from .apm/skills/latex/SKILL.md by agora/renderers/opencode-to-claude.md -->

# LaTeX

Language-specific rules for LaTeX documents. Load this skill when working in
any repository that contains `.tex` sources.

## Companion Skills

- `academic-writing` for the prose of papers and theses
- `bibliography` for sources, `.bib` files, and citation practice

## Core Principles

- Prefer semantic markup over visual formatting (`\emph`, sectioning, custom macros)
- For new documents, prefer one sentence per line for cleaner diffs; never reflow existing files that use another style
- Label every referenced float, equation, and section; reference with `\ref`/`\cref`
- Never hard-code numbers for sections, figures, tables, or equations
- Define document-wide macros once, in the preamble

## Engine Choice

- Match the project's existing engine: check `latexmkrc`, `Makefile`, `% !TEX program` magic comments, and whether `fontspec` is loaded
- For new documents choose deliberately; there is no default
- pdfLaTeX: broadest template and journal compatibility, fastest; use `\usepackage[T1]{fontenc}`; do not load `inputenc` (UTF-8 is the default since LaTeX 2018)
- LuaLaTeX: Unicode and system/OpenType fonts via `fontspec`, Lua scripting; do not load `fontenc` or `inputenc`
- XeLaTeX: Unicode and `fontspec`; prefer LuaLaTeX unless a template requires XeLaTeX

## Document Structure & Preamble

- Keep one root document and respect its existing name
- Use `\include` for chapters (forces a page break; enables `\includeonly`) and `\input` for fragments
- Keep the package list minimal, grouped, and commented where non-obvious
- Load `hyperref` late in the preamble; the few packages that must come after it (e.g. `cleveref`) go after it
- Do not load packages that conflict or duplicate functionality
- Respect the document class the project already uses

## Error Handling

- Read the `.log` file; fix the FIRST error before anything else
- Non-stop mode is right for automated builds; what hides errors is not halting or ignoring the exit code
- Build with `-interaction=nonstopmode -halt-on-error -file-line-error` and always check the exit code
- `\batchmode` additionally suppresses terminal output; avoid it when diagnosing
- Treat undefined references and undefined citations as defects
- Treat overfull boxes that are visibly too wide (e.g. > 1pt) as defects; review the rest
- Do not silence warnings by deleting content or disabling packages without reason

## Bibliography

- Prefer `biblatex` with `biber` for new documents
- Respect an existing BibTeX setup; do not migrate without being asked
- Use consistent, meaningful citation keys (e.g. `author2024keyword`)
- See the `bibliography` skill for sourcing and `.bib` hygiene

## Figures, Tables & Math

- Use `booktabs` rules for tables; avoid vertical rules
- Use `siunitx` for numbers and units
- Prefer vector graphics (PDF, TikZ, pgfplots) over raster images
- Use `amsmath` environments (`align`, `gather`); never `eqnarray`
- Use `\[ ... \]` for display math, never `$$ ... $$`
- Place captions consistently and put `\label` after `\caption`

## Build & Tooling

- Use `latexmk` as the build driver with the project's engine: `latexmk -pdf`, `latexmk -lualatex`, or `latexmk -xelatex`
- Respect an existing `latexmkrc`, `Makefile`, or Tectonic setup
- Run `chktex`; fix warnings or suppress them deliberately via `.chktexrc` or `% chktex N` comments with a reason
- Format with `latexindent` when the project uses it
- Provide TeX Live through the project flake (e.g. nixpkgs `texlive.combine` or `texlive.withPackages`) with only the needed packages
- Always run inside the Nix dev shell if a `flake.nix` is present: `nix develop --command <cmd>`

## Testing

- A clean build is the test: zero errors, zero undefined references or citations
- Pair `-halt-on-error` with `-interaction=nonstopmode` so the build stops at the first error instead of continuing
- Ensure no "rerun" warnings remain after the final pass
- Keep `chktex` output clean or deliberately suppressed

## Code Review

- Flag hard-coded numbering and missing `\label`/`\ref` pairs
- Flag visual formatting where semantic markup belongs
- Flag unused, duplicate, or conflicting packages, and `inputenc` in new documents
- Check tables for vertical rules and math for `$$` or `eqnarray`
- Verify the document builds without warnings that indicate defects

## Code Generation

- Always generate source that compiles with the project's engine
- Final, submission-ready content has no placeholder text or `TODO` markers; drafts may carry clearly flagged notes for missing sources or evidence
- Prefer clarity over clever macro tricks
- Add any required package to the preamble together with the code that needs it
