# Create Quarto sources from a template

Writes one Quarto (`.qmd`) source file per row of `params_df`. Each file
gets that row's values in its YAML `params:` block.

The template is either one a package ships or a `.qmd` path.

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

  A data frame, one row per report. Column names match the parameter
  names in the template's `params:` block.

- template_name:

  A template directory that `template_package` ships. Ignored when
  `template_path` is given.

- template_package:

  Installed package to look for `template_name` in.

- output_dir:

  Where the `.qmd` files go. Defaults to the project's `reports/`
  folder. See
  [`mariner_dirs()`](https://thomasqmd.github.io/mariner/reference/mariner_dirs.md).
  Created if it is missing.

- template_path:

  A `.qmd` path to use instead of a packaged template.

- file_name:

  A [`glue::glue()`](https://glue.tidyverse.org/reference/glue.html)
  template for the output names, evaluated against each row of
  `params_df`. Leave off the `.qmd` extension; mariner adds it. Every
  column that varies has to appear here, or two rows resolve to one name
  and the second overwrites the first.

## Value

Invisibly, a character vector of the paths written.

## Details

mariner parses the template front matter as YAML, merges the row into
its `params` entry, and re-emits it. Only `params` changes. `title`,
`format` and the rest come across untouched, inline R included:
`` title: "`r paste('Report', params$chapter)`" ``.

A column of `params_df` with no counterpart in the template's `params`
block is not substituted, and warns. That case is a typo or a template
mismatch, and the old behaviour dropped it in silence.

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
#> ✔ Wrote 2 files to /var/folders/k3/k8hfzfxd11j6vy0_t2rx27yw0000gn/T//RtmpDjwOKV/mariner-example-1648113beecf1

basename(qmd_files)
#> [1] "Report-1_1.qmd" "Report-1_2.qmd"

# A different naming scheme:
generate_reports(
  params_df = report_params,
  output_dir = temp_dir,
  file_name = "ch{chapter}-prob{problem_numbers}"
) |> basename()
#> ℹ Generating 2 qmd files...
#> ✔ Wrote 2 files to /var/folders/k3/k8hfzfxd11j6vy0_t2rx27yw0000gn/T//RtmpDjwOKV/mariner-example-1648113beecf1
#> [1] "ch1-prob1.qmd" "ch1-prob2.qmd"

unlink(temp_dir, recursive = TRUE)
```
