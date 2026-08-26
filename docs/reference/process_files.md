# Bundle many Quarto files, in sequence or in parallel

[`process_file()`](https://thomasqmd.github.io/mariner/reference/process_file.md)
over a vector of Quarto (`.qmd`) files. The batch runs sequentially by
default, and in parallel under a **future** plan such as
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

  A character vector of `.qmd` paths.

- output_dir:

  Where the archives go. Defaults to the project's `zip_files/` folder.
  See
  [`mariner_dirs()`](https://thomasqmd.github.io/mariner/reference/mariner_dirs.md).

- theme:

  One of
  [mariner_themes](https://thomasqmd.github.io/mariner/reference/mariner_themes.md).

- assets_dir:

  Directory that holds a built extension. Resolved once here and handed
  to every worker, so a batch of fifty reports stages the theme from one
  place.

- include:

  Which categories to bundle. See
  [`process_file()`](https://thomasqmd.github.io/mariner/reference/process_file.md).

## Value

Invisibly, a character vector of the archives created, with `NA` in the
position of any file that failed.

## Details

A file that fails to render does not stop the batch. It comes back as
`NA`, and its error message is named in the summary. Each render owns a
scratch directory, so parallel workers cannot collide.

## Examples

``` r
if (FALSE) { # \dontrun{
temp_dir <- tempfile("example-")

doc_files <- generate_reports(
  params_df = data.frame(chapter = 1, problem_numbers = 1:2),
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
