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
- Load `hyperref` late in the preamble (a few packages go after it; see the hyperref manual); load `cleveref` last, after `hyperref`
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

## Sources

Locators refer to the copies in the personal library (athenaeum), where available: section numbers or printed pages; "PDF p." marks a PDF page index.

- UTF-8 is the default input encoding, no `inputenc`: LaTeX Project Team, "LaTeX News" (Issue 28, April 2018), "UTF-8: the new default input encoding", p. 1-2
- LuaLaTeX/XeLaTeX with `fontspec`: Will Robertson, "The fontspec package: Font selection for XeLaTeX and LuaLaTeX" (v2.9h, 2026/08/11), Sec. 3 "Package loading and options"
- `\include` starts a new page: Tobias Oetiker, Hubert Partl, Irene Hyna and Elisabeth Schlegl, "The Not So Short Introduction to LaTeX2e" (Version 6.4, March 09, 2021), Sec. 1.8 "Big Projects", p. 14
- Packages loaded before or after `hyperref`: Sebastian Rahtz, Heiko Oberdiek and The LaTeX3 Project, "Hypertext marks in LaTeX: a manual for hyperref" (v7.01t, 2026-11-03), Sec. 11 "Special support for other packages"
- Load `cleveref` last: Toby Cubitt, "The cleveref package" (2018/03/27), Sec. 13 "Interaction with Other Packages"
- Overfull boxes: Oetiker et al., "The Not So Short Introduction to LaTeX2e" (Version 6.4, 2021), Chapter 2 "Typesetting Text", p. 18
- Prefer `biblatex` with `biber`: Philip Kime and Francois Charette, "biber: A backend bibliography processor for biblatex" (biber 2.22, 13th August 2026), Sec. 2.5 "History"
- `booktabs` tables: Simon Fear, "Publication quality tables in LaTeX" (printed January 14, 2020), abstract and PDF p. 3
- `siunitx` for numbers and units: Joseph Wright, "siunitx - A comprehensive (SI) units package" (released 2026-11-06), Abstract
- `amsmath` display environments: American Mathematical Society and LaTeX Project, "User's Guide for the amsmath Package" (Version 2.1, revised 2020-02-18), Sec. 3 "Displayed equations"
- Avoid `eqnarray`: Oetiker et al., "The Not So Short Introduction to LaTeX2e" (Version 6.4, 2021), Sec. 3.5 "Multiple Equations", p. 52-53
- Obsolete commands in review (general): Mark Trettin (transl. Juergen Fenn), "An essential guide to LaTeX2e usage: Obsolete commands and packages" (version 1.8.5.7, June 17, 2007), Sec. 1 "Deadly sins"
- `\label` after `\caption`: Oetiker et al., "The Not So Short Introduction to LaTeX2e" (Version 6.4, 2021), Sec. 2.13 "Floating Bodies", p. 41
- `latexmk` as build driver and rerun handling: John Collins, "latexmk" (manual page), DESCRIPTION, PDF p. 2
- `latexmk -xelatex` and `$pdf_mode`: John Collins, "latexmk" (manual page), PDF p. 21 and p. 48
- `chktex` suppression and rc files: Jens T. Berger Thielemann, "ChkTeX" (v1.7.10, February 26, 2026), `% chktex N` PDF p. 11, named user warnings PDF p. 39, `chktexrc`/`-l` PDF p. 6
- `latexindent` configuration: Chris Hughes, "latexindent.pl" (V4.0.3, 2026-10-04), Section H "indentconfig options"
