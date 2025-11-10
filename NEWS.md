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