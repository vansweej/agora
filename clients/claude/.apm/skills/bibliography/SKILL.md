---
name: bibliography
description: >
  Use when finding sources for claims, managing .bib files, or adding
  citations to a paper, thesis, or report. Triggers on: bibliography,
  citation, cite, cite key, .bib, bibtex, biblatex, biber, zotero,
  better bibtex, doi, isbn, literature search, related sources.
---

<!-- DO NOT EDIT — generated from .apm/skills/bibliography/SKILL.md by agora/renderers/opencode-to-claude.md -->

# Bibliography

Rules for sources, reference data, and citations. Typesetting lives in the
`latex` skill; prose lives in the `academic-writing` skill.

## Core Principles

- Never invent a reference, author, title, year, page, DOI, or ISBN; the only exception is an unverified suggestion of a work for the human to check (see Finding Where Concepts Come From), never a citation
- Cite only sources you (or the author) have actually seen
- Every concept or claim taken from a source gets a citation with a locator
- One `.bib` entry per source; one consistent citation key scheme
- Unknown metadata is flagged for the human, never filled in by guesswork

## Finding Where Concepts Come From

- If a personal library search tool (athenaeum) is available, search it first for each concept or claim
- Record the hit's source name and its location next to the claim; use a page as the locator, or a section/heading (e.g. `[Section 3.2]`) when no page is given
- Verify the passage in the original before citing; a search hit is a lead, not a citation
- Use the page as the citation locator: with biblatex `\autocite[139]{saltzer2009principles}` (a bare number gets "p." added automatically); with classic BibTeX `\cite[p.~139]{saltzer2009principles}`
- If nothing relevant is found, say so and leave the claim marked as needing a source
- When the library has no source for a concept, propose at most three well-known candidate works that fit the project's paradigm and build on or sit alongside its core references (judge fit from the project's .bib, ledger, and library hits), as unverified suggestions, each labelled "UNVERIFIED suggestion", giving author and title only (no year, edition, page, DOI, or ISBN), for the human to check and ingest; never place them in the document text or the .bib; if no fitting work is known, say so instead of suggesting off-paradigm works; if there is no .bib, ledger, or relevant library hit to judge fit from, ask the human for the core references instead of suggesting
- Library search matches passage content, not titles: to check whether a work is already present, search for its distinctive topics, not its title
- Prefer primary sources over surveys and secondary summaries

## Concept Ledger

- Keep a per-project ledger `sources.md` at the document root when the user asks to track sources; create it if missing
- One row per concept or claim, with columns: concept | source | locator (page or section) | cite key | verified (yes/no)
- Add a row whenever a concept is taken from a source
- Set `verified` to `yes` only after the passage was checked in the original
- The ledger and the `.bib` must agree: every cite key in the ledger exists in the `.bib`
- If the project already has a ledger, respect its format and location
- Record library gaps in a `## Gaps` section of the ledger: concept | suggested works (unverified) | status (suggested, acquired, ingested); an entry is open until its status is ingested; if no ledger is kept, list the gaps in your reply instead and do not create the ledger for them
- A suggested work never enters the `.bib` or the ledger rows until it is ingested or otherwise obtained and the passage is verified

## Reference Metadata

- Take author, title, year, publisher, edition, DOI, and ISBN from the title page, copyright page, publisher record, or a DOI lookup
- A library search hit names a source and a location; it is not complete metadata
- Mark any field you could not verify with a comment such as `% TODO verify: year` for the human
- Use the correct entry type and its required fields: biblatex `@book`, `@article`, `@inproceedings`, `@incollection`, `@thesis`, `@online`; classic BibTeX uses `@phdthesis`/`@mastersthesis` and `@misc` instead
- With biblatex, give `@online` entries a `url` and a `urldate`; with classic BibTeX put the access date in `note`

## .bib Hygiene

- Use a stable key scheme such as `authorYEARword` (e.g. `knuth1984texbook`)
- If the project uses Zotero with Better BibTeX auto-export, edit in Zotero and keep its keys; do not hand-edit the exported file
- Protect capitalisation in titles with braces, e.g. `{TeX}`, `{Unix}`
- Keep the file UTF-8; with biblatex use the `biber` backend
- No duplicate entries; merge them and update every cite key
- Remove unused entries unless the project keeps a shared library file

## Citation Practice

- Cite at the point where the claim is made, not in a block at the end of a paragraph
- Give page or section locators for books and long documents
- No citation dumps: cite the few sources that actually support the claim
- Quote sparingly and always with a locator

## Tooling

- Verify that every cite key resolves: zero undefined citations in the build log
- Find unused or undefined entries with `checkcites` (CTAN) if it is available
- Validate entries with `biber --validate-datamodel <jobname>` after a LaTeX run
- Always run inside the Nix dev shell if a `flake.nix` is present: `nix develop --command <cmd>`

## Review

- Flag any reference whose metadata cannot be traced to a real source
- Flag claims without a citation and citations without a locator where one is needed
- Flag concepts in the text that are missing from the ledger, and ledger rows with `verified: no` before submission
- Flag open rows in the ledger's `## Gaps` section before submission
- Flag duplicate entries, inconsistent keys, and missing required fields
- Flag citation dumps and secondary sources where the primary is available

## Generation

- Never invent a reference; if no source is known, mark the claim as needing one, and offer candidate works only as unverified suggestions outside the document and the .bib
- Produce `.bib` entries only from verified metadata, with unknown fields flagged
- Keep the existing key scheme and file layout of the project

## Sources

Locators refer to the copies in the personal library (athenaeum), where available: section numbers or printed pages; "PDF p." marks a PDF page index.

- Page locators in `\autocite` postnotes: Philip Kime, Moritz Wemheuer and Philipp Lehman, "The biblatex Package: Programmable Bibliographies and Citations" (Version 3.22a, September 24, 2026), Sec. 3.15.3 "Page Numbers in Citations"
- `urldate` for online entries: Kime, Wemheuer and Lehman, "The biblatex Package" (Version 3.22a, 2026), PDF p. 181
- Protect capitalisation with braces: Kime, Wemheuer and Lehman, "The biblatex Package" (Version 3.22a, 2026), PDF p. 264-265
- Keep the .bib UTF-8 (`inputenc` covers only part of UTF-8): Kime, Wemheuer and Lehman, "The biblatex Package" (Version 3.22a, 2026), PDF p. 46
- With biblatex use `biber` (BibTeX's Unicode limits): Philip Kime and Francois Charette, "biber: A backend bibliography processor for biblatex" (biber 2.22, 13th August 2026), Sec. 2.5 "History" and PDF p. 39
- Unused or undefined entries with `checkcites`: Enrico Gregorio, "The checkcites script" (v2.8), Sec. 1 "Introduction" and Sec. 3 "Usage"
