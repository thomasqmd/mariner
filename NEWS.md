# mariner 0.2.0 (development)

## Breaking Changes

* **Zip archives default into `zip_files/`**, not beside the source file.
  `process_file()` and `process_files()` resolve the project root from the
  *input file's* directory, so a batch that spans two projects lands each bundle
  in its own folder. Pass `output_zip` / `output_dir` for the old behaviour.
* **`generate_reports()` writes into `reports/`** rather than the working
  directory.
* **Output names come from a `file_name` glue template**, `"Report-{chapter}_{problem_numbers}"`
  by default. A `params_df` without those columns used to give every row the
  name `Report-_.qmd`, so `n` rows left one file. It is now an error that names
  the available columns.
* **R Markdown support is removed.** `generate_reports()`, `process_file()` and
  `process_files()` take `.qmd` only, and refuse a `.Rmd` with a message.
  **rmarkdown** is no longer a dependency, and the `simple_report` template no
  longer carries a `skeleton.Rmd`.

## New Features

* **A vendored Quarto PDF theme.** mariner ships the theme, the fonts and the
  brand tokens. A report renders in Atkinson Hyperlegible Next, Lora and
  JetBrains Mono with the LaTeX geometry to match, and there is nothing to
  install separately.
* **Document markup.** The spans `[x]{.defn}`, `[x]{.term}`, `[x]{.termref}` and
  `[x]{.emph}`, and the blocks `::: {.def}` and `::: {.thm}`, mark defined terms
  and set off definitions and theorems in the brand colours. A `.defn` with an
  identifier — `[support]{.defn #support}` — also plants a cross-reference
  target. Quarto's callouts work alongside them.
* **ggplot2 theming and scales.** `theme_mariner()`, `mariner_set_theme()`,
  `mariner_colors()` and `mariner_pal()`, plus `colour` and `fill` scales in
  five families: `scale_*_mariner_d()`, `_c()`, `_o()`, `_div()` and `_b()`.
* **Project scaffolding.** `mariner_setup_project()` creates `assets/`,
  `reports/` and `zip_files/`, assembles the theme into `assets/`, copies it
  beside the documents in `reports/`, drops in a starter report, and gitignores
  the build outputs. Run it twice and nothing changes.
* **The folders are also created on attach.** `library(mariner)` creates the
  three directories in an interactive session whose working directory looks like
  a project root — see `mariner_looks_like_project()`. It does not assemble the
  theme. Turn it off with `options(mariner.auto_setup = FALSE)`.
* **New `mariner_check_setup()`** answers "will a report render on this
  machine?" in one call: Quarto and its version, a LaTeX engine, whether the
  fonts are installed rather than merely bundled, whether zip can write, the
  project folders, whether the theme beside the documents is complete, and the
  packages the template loads. Each line carries a fix to paste. Nothing is
  installed or changed.
* **New `report` template**, replacing `simple_report`, with
  `mariner_templates()` and `mariner_template_path()` to find it.
* **New `include` argument** on `process_file()` and `process_files()` selects
  which of `"source"`, `"script"`, `"output"` and `"intermediates"` reach the
  archive. All four by default.
* **New `assets_dir` argument** points at the extension `mariner_setup_project()`
  built, so a batch of fifty reports stages the theme from one place.
* New `mariner_dirs()` returns the three project paths and is the single source
  every default path resolves through. `mariner_project_root()` resolves the
  root, and `options(mariner.project_root = ...)` overrides it.

## Bug Fixes

* **A project scaffolded by `mariner_setup_project()` is now found again.**
  `mariner_project_root()` recognised only an `.Rproj`, a `_quarto.yml` or a
  `DESCRIPTION`, so in a plain directory the scaffolder and the renderer
  disagreed about where the project was: setup created `zip_files/` beside the
  three folders, while `process_file()` walked up from `reports/ch1.qmd`, found
  no marker, fell back to `reports/` itself, and wrote `reports/zip_files/`. A
  directory holding all three mariner folders is now a root in its own right --
  at the directory you are in, and further up only when the search climbed out
  of `assets/`, `reports/` or `zip_files/`. Those folders are created for you,
  so an abandoned set in a parent directory does not capture a new project
  started beneath it.
* **The staged theme link is removed on Windows.** Teardown used
  `unlink(recursive = FALSE)`, which Windows refuses on a directory reparse
  point — `mismatch between the tag specified in the request and the tag present
  in the reparse point` — so every render warned and left the link standing for
  the recursive delete on the next line. It now goes through `fs::link_delete()`,
  and a link that cannot be removed is reported rather than deleted recursively.
* **A missing input file says where to look.** `process_file("Report-1_1.qmd")`
  from the project root reported only that the file did not exist. It now adds
  `Did you mean 'reports/Report-1_1.qmd'?` when the name resolves there.

* **`generate_reports()` parses the YAML instead of rewriting it with a regex.**
  The old approach broke on a param whose default was empty or `null`, on list-
  and multi-line values, and on a `---` inside the document. It also dropped a
  `params_df` column with no counterpart in the template. Unmatched columns now
  warn once, naming both what was passed and what the template declares.
* **`process_file()` stages the theme beside the document it renders**, so a
  report using `format: mariner-pdf` finds its fonts. It symlinks from `assets/`
  where the platform allows and copies where it does not.
* **Fonts are registered inside each parallel worker.** A `multisession` worker
  is a fresh process, so its figures used to fall back to the device default —
  in parallel runs only, with nothing to show for it.
* **A `_files/` directory now travels with a document whose name has a space in
  it.** Quarto names its output after a sanitised form of the input stem, so
  `report with spaces.qmd` renders to `report-with-spaces.pdf` and the match
  against `<input stem>_files` classed the directory as an intermediate. The
  default `include` bundled it either way, but `include = c("source", "output")`
  shipped an HTML document without its dependencies.
* **Windows font installation could not have worked.** `mariner_install_fonts()`
  quoted its `reg add` arguments with `shQuote()`'s POSIX default, and
  `system2()` on Windows goes through `cmd.exe`, which does not strip single
  quotes. Every registry write was refused. Windows ignores a font file the
  registry does not name, so the fonts appeared to install and did nothing.
* The Windows registry value now carries the font's own full name
  (`Lora Regular (TrueType)`) rather than one derived from the filename
  (`Lora-Regular (TrueType)`). That is what Windows writes, and it stops a later
  install through Explorer from leaving a duplicate entry.
* On Linux without `fc-cache`, `mariner_install_fonts()` says so. The fonts
  install either way, but they are not picked up at once, and the previous
  silence left no route from "restart R" to the cause.
* Bundling moved from `utils::zip()` to `zip::zip()`. The old backend shelled
  out to an external `zip` binary that a stock Windows install does not have, and
  it added to an existing archive rather than replacing it, so re-running a batch
  could leave stale files in a bundle.

## Minor Changes

* User-facing output from `generate_reports()`, `process_file()` and
  `process_files()` goes through **cli**. `process_files()` names the files that
  failed rather than counting them.
* A render happens in an `fs::path_real()`-resolved scratch directory, so the
  path the Quarto CLI receives is the one the filesystem agrees on: symlinks
  resolved, Windows 8.3 short names expanded.
* **systemfonts** (>= 1.1.0) is now required. `match_font()` is soft-deprecated
  there and would print a deprecation warning in the middle of a setup report.
* **progressr** and **tinytex** added to `Suggests`; **tidyverse** and
  **conflicted** restored to it. A test now checks that every package the
  starter template loads is declared, so the list cannot fall behind the
  template.
* `LazyData: true` removed — there is no `data/`.

# mariner 0.1.3

This version introduces support for Quarto (`.qmd`) files, which is now the default.

## Major Changes

* **Quarto Support**: The package workflow now fully supports Quarto files.
    * `generate_reports()` will now look for `skeleton.qmd` in the template directory and use it by default. It falls back to `skeleton.Rmd` if a Quarto skeleton is not found.
    * `process_file()` now checks the file extension and uses `quarto::quarto_render()` for `.qmd` files and `rmarkdown::render()` for `.Rmd` files.
    * The `simple_report` template now includes both `skeleton.qmd` and `skeleton.Rmd`.

## Minor Changes

* Unit tests have been updated to test for `.qmd` and `.Rmd` file handling in both `generate_reports()` and `process_file()`.
* Added CI setup with GitHub Actions to test against R 4.5, install Quarto, and run **covr**.

# mariner 0.1.2

* Improve default template in skeleton directory for report generation.
* Update documentation to reflect new template structure.
* Expanded unit tests for `generate_reports()` to cover template variations.

# mariner 0.1.1

* Expand testing suite for all functions.
* Add parallel processing support in `process_files()` using **future** and **furrr**.

# mariner 0.1.0

* Initial release.
* Added `generate_reports()` to create parameterized R Markdown files from a template.
* Added `process_file()` to render and bundle a single `.Rmd` file into a `.zip` archive.