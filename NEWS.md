# mariner 0.2.0 (development)

## Breaking Changes

* **Zip archives now default into `zip_files/`**, not beside the source file.
  `process_file()` and `process_files()` resolve the project root from the
  *input file's* directory, so a batch spanning two projects lands each bundle
  in its own folder. Pass `output_zip` / `output_dir` for the old behaviour.
* **`generate_reports()` writes into `reports/` by default** rather than the
  working directory.
* **Output file names are now a `file_name` glue template**, defaulting to
  `"Report-{chapter}_{problem_numbers}"`. A `params_df` without those columns
  used to produce `Report-_.qmd` -- the same name for every row, so `n` rows
  left one file. It is now an error naming the available columns.
* **R Markdown support is removed.** `generate_reports()`, `process_file()` and
  `process_files()` accept `.qmd` only; a `.Rmd` input is refused with a message
  rather than rendered. `rmarkdown` is no longer a dependency, and the
  `simple_report` template no longer carries a `skeleton.Rmd`.

## Major Changes

* **New project scaffolding.** `mariner_setup_project()` creates the three
  folders a mariner workflow uses — `assets/`, `reports/` and `zip_files/` —
  assembles the Quarto theme into `assets/`, copies it beside the documents in
  `reports/`, drops in a starter report, and gitignores the build outputs.
  Running it twice changes nothing.
* **The folders are also created on attach.** `library(mariner)` creates the
  three directories when the working directory looks like a project root
  (see `mariner_looks_like_project()`) and the session is interactive. It does
  not assemble the theme — that stays in `mariner_setup_project()`. Turn the
  whole behaviour off with `options(mariner.auto_setup = FALSE)`.
* **`generate_reports()` now parses the YAML instead of rewriting it with a
  regex.** The old approach broke on a param whose default was empty or `null`,
  on list- and multi-line values, and on any `---` inside the document being
  mistaken for the closing fence -- and it dropped a `params_df` column with no
  counterpart in the template in silence. Unmatched columns now warn, once,
  naming both what was passed and what the template declares.
* **`process_file()` stages the Quarto theme beside the document it renders**,
  so a report using `format: mariner-baylor-pdf` finds its fonts. It is
  symlinked from `assets/` where the platform allows and copied where it does
  not. New `assets_dir` argument points at the extension
  `mariner_setup_project()` already built, so a batch of fifty reports stages
  from one place rather than assembling the theme fifty times.
* **New `include` argument** on `process_file()` and `process_files()` selects
  which of `"source"`, `"script"`, `"output"` and `"intermediates"` reach the
  archive. All four by default.
* **`process_files()` reports the error messages of files that failed**, named,
  instead of only counting them. Fonts are now registered inside each parallel
  worker: a `multisession` worker is a fresh process, so its figures previously
  fell back to the device default -- silently, and only in parallel.
* **New `mariner_check_setup()`** answers "will a branded report render on this
  machine?" in one call: Quarto and its version, a LaTeX engine, whether the
  fonts are installed rather than merely bundled, whether zip can write, the
  project folders, whether the theme is complete beside the documents, and the
  packages the template loads. Each line comes with a copy-pasteable fix.
  Nothing is installed or changed.
* **A document whose `_files/` directory travels correctly even when its name
  has a space in it.** Quarto names its output after a *sanitised* form of the
  input stem -- `report with spaces.qmd` renders to `report-with-spaces.pdf` --
  so matching `<input stem>_files` classed the directory as an intermediate.
  Invisible under the default `include`, but `include = c("source", "output")`
  bundled an HTML document without its dependencies.
* New `mariner_dirs()` returns those three paths and is the single source every
  default path in the package resolves through; `mariner_project_root()`
  resolves the root, overridable with `options(mariner.project_root = …)`.
* Bundling moved from `utils::zip()` to `zip::zip()`. The old backend shelled
  out to an external `zip` binary that a stock Windows install does not have,
  and it added to an existing archive rather than replacing it, so re-running a
  batch could leave stale files inside a bundle.

## Bug Fixes

* **Windows font installation could not have worked.** `mariner_install_fonts()`
  quoted its `reg add` arguments with `shQuote()`'s POSIX default -- single
  quotes -- and `system2()` on Windows goes through `cmd.exe`, which does not
  strip them, so every registry write was refused. A font file in the user font
  directory that is not named in the registry is ignored, so the fonts appeared
  to install and did nothing.
* The Windows registry value now carries the font's own full name
  (`Lora Regular (TrueType)`) rather than one derived from the filename
  (`Lora-Regular (TrueType)`), which is what Windows writes and what stops a
  later install through Explorer leaving a duplicate entry.
* On Linux without `fc-cache`, `mariner_install_fonts()` now says so. The fonts
  are installed either way, but they are not picked up immediately, and the
  previous silence left no route from "restart R" to the actual cause.

## Minor Changes

* User-facing output from `generate_reports()`, `process_file()` and
  `process_files()` now goes through `cli`. `process_files()` additionally
  *names* the files that failed rather than only counting them.
* Renders now happen in a `fs::path_real()`-resolved scratch directory, so the
  path handed to the Quarto CLI is the one the filesystem agrees on -- symlinks
  resolved, and Windows 8.3 short names expanded.
* `systemfonts (>= 1.1.0)` is now required; `match_font()` is soft-deprecated
  there and would print a deprecation warning in the middle of a setup report.
* `progressr` and `tinytex` added to `Suggests`; `tidyverse` and `conflicted`
  restored to it, because the packaged template loads them and a declared
  dependency is now enforced by a test. `LazyData: true` removed -- there is no
  `data/`.

# mariner 0.1.3

This version introduces support for Quarto (`.qmd`) files, which is now the default.

## Major Changes

* **Quarto Support**: The package workflow now fully supports Quarto files.
    * `generate_reports()` will now look for `skeleton.qmd` in the template directory and use it by default. It falls back to `skeleton.Rmd` if a Quarto skeleton is not found.
    * `process_file()` now checks the file extension and uses `quarto::quarto_render()` for `.qmd` files and `rmarkdown::render()` for `.Rmd` files.
    * The `simple_report` template now includes both `skeleton.qmd` and `skeleton.Rmd`.

## Minor Changes

* Unit tests have been updated to test for `.qmd` and `.Rmd` file handling in both `generate_reports()` and `process_file()`.
* Added CI setup with GitHub Actions to test against R 4.5, install Quarto, and run `covr`.

# mariner 0.1.2

* Improve default template in skeleton directory for report generation.
* Update documentation to reflect new template structure.
* Expanded unit tests for `generate_reports()` to cover template variations.

# mariner 0.1.1

* Expand testing suite for all functions.
* Add parallel processing support in `process_files()` using `future` and `furrr`.

# mariner 0.1.0

* Initial release.
* Added `generate_reports()` to create parameterized R Markdown files from a template.
* Added `process_file()` to render and bundle a single `.Rmd` file into a `.zip` archive.