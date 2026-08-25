# Create Quarto Source Files from a Template

Creates multiple Quarto (`.qmd`) source files from a parameterized
template, one per row of `params_df`. Each file gets that row's values
spliced into its YAML `params:` block.

The template can be one shipped by a package or a `.qmd` file path.

## Usage

``` r
generate_reports(
  params_df,
  template_name = "report",
  template_package = "mariner",
  output_dir = mariner_dirs()$reports,
  template_path = NULL,
  file_name = "Report-{chapter}_{problem_numbers}"
)
```

## Arguments

- params_df:

  A data frame where each row describes one report. Column names are
  matched against the parameter names in the template's YAML `params:`
  block.

- template_name:

  Name of a template directory shipped by `template_package`. Ignored
  when `template_path` is given.

- template_package:

  Installed package to look for `template_name` in.

- output_dir:

  Directory the `.qmd` files are written to. Defaults to the project's
  `reports/` folder – see
  [`mariner_dirs()`](https://thomasqmd.github.io/mariner/reference/mariner_dirs.md).
  Created if needed.

- template_path:

  Path to a `.qmd` file to use instead of a packaged template.

- file_name:

  A [`glue::glue()`](https://glue.tidyverse.org/reference/glue.html)
  template for the output file names, evaluated against each row of
  `params_df`. The `.qmd` extension is added automatically and must not
  be included here.

## Value

Invisibly, a character vector of the paths actually written.

## Details

Values are substituted by parsing the template's front matter as YAML,
merging the row into its `params` entry, and re-emitting it. Only the
`params` block changes – `title`, `format` and everything else are
carried across untouched, including inline R such as
`` title: "`r paste('Report', params$chapter)`" ``.

A column in `params_df` with no counterpart in the template's `params`
block is *not* substituted, and raises a warning naming it. This is
almost always a typo or a template mismatch, and the previous behaviour
– dropping it in silence – produced reports that were wrong in a way
nothing announced.

## Examples

``` r
temp_dir <- tempfile("mariner-example-")

report_params <- data.frame(
  chapter = 1,
  problem_numbers = 1:2,
  author = "Firstname Lastname"
)

qmd_files <- generate_reports(
  params_df = report_params,
  template_name = "report",
  output_dir = temp_dir
)
#> ℹ Generating 2 qmd files...
#> ✔ Wrote 2 files to /var/folders/k3/k8hfzfxd11j6vy0_t2rx27yw0000gn/T//RtmpzQHXJH/mariner-example-11e9c41b757e0

basename(qmd_files)
#> [1] "Report-1_1.qmd" "Report-1_2.qmd"

# A different naming scheme:
generate_reports(
  params_df = report_params,
  output_dir = temp_dir,
  file_name = "ch{chapter}-prob{problem_numbers}"
) |> basename()
#> ℹ Generating 2 qmd files...
#> ✔ Wrote 2 files to /var/folders/k3/k8hfzfxd11j6vy0_t2rx27yw0000gn/T//RtmpzQHXJH/mariner-example-11e9c41b757e0
#> [1] "ch1-prob1.qmd" "ch1-prob2.qmd"

unlink(temp_dir, recursive = TRUE)
```
