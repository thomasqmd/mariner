# Bundle Multiple Quarto Files Sequentially or in Parallel

A wrapper around
[`process_file()`](https://thomasqmd.github.io/mariner/reference/process_file.md)
for a vector of Quarto (`.qmd`) files. Execution is sequential by
default and parallel under a `future` plan, e.g.
`future::plan(future::multisession)`.

## Usage

``` r
process_files(
  input_files,
  output_dir = NULL,
  theme = mariner_themes,
  assets_dir = mariner_dirs()$assets,
  include = INCLUDE_KINDS
)
```

## Arguments

- input_files:

  A character vector of paths to `.qmd` files.

- output_dir:

  Directory for the zip archives. Defaults to the project's `zip_files/`
  folder – see
  [`mariner_dirs()`](https://thomasqmd.github.io/mariner/reference/mariner_dirs.md).

- theme:

  One of
  [mariner_themes](https://thomasqmd.github.io/mariner/reference/mariner_themes.md).

- assets_dir:

  Directory holding an already-built extension. Resolved once here and
  passed to every worker, so a batch of fifty reports stages the theme
  from one place rather than assembling it fifty times.

- include:

  Which categories of file to bundle – see
  [`process_file()`](https://thomasqmd.github.io/mariner/reference/process_file.md).

## Value

Invisibly, a character vector of paths to the archives created, with
`NA` in the position of any file that failed.

## Details

A file that fails to render does not stop the batch: it comes back as
`NA` and its error message is reported at the end, named. Each render
owns a scratch directory, so parallel workers cannot collide.

## Examples

``` r
if (FALSE) { # \dontrun{
temp_dir <- tempfile("example-")

doc_files <- generate_reports(
  params_df = data.frame(
    chapter = 1, problem_numbers = 1:2, author = "A. Name"
  ),
  output_dir = temp_dir
)

process_files(doc_files, output_dir = file.path(temp_dir, "zips"))

# In parallel:
future::plan(future::multisession, workers = 2)
process_files(doc_files, output_dir = file.path(temp_dir, "zips"))
future::plan(future::sequential)

unlink(temp_dir, recursive = TRUE)
} # }
```
