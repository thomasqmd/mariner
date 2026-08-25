# Check that this machine can render a mariner report

Runs through everything a branded PDF needs – Quarto, a LaTeX engine,
the fonts, the project folders, the theme, the packages the template
loads – and prints one line per check with a copy-pasteable fix for
anything that is wrong.

## Usage

``` r
mariner_check_setup(
  root = NULL,
  theme = mariner_themes,
  template = "report",
  quiet = FALSE
)
```

## Arguments

- root:

  Project root to check. `NULL` (the default) resolves it with
  [`mariner_project_root()`](https://thomasqmd.github.io/mariner/reference/mariner_project_root.md).

- theme:

  One of
  [mariner_themes](https://thomasqmd.github.io/mariner/reference/mariner_themes.md).

- template:

  Starter template whose package dependencies to check.

- quiet:

  Return the data frame without printing it.

## Value

Invisibly, a data frame with one row per check and the columns `check`,
`status` (`"ok"`, `"warn"` or `"fail"`), `detail` and `remedy`.

## Details

Nothing is installed or changed. Every remedy is printed for you to run.

## What the statuses mean

- ok:

  Nothing to do.

- warn:

  The report will render, but not as intended – most often figures drawn
  in the device's default typeface while the page text is in the
  theme's, which is the failure nobody notices.

- fail:

  The render will not complete.

## See also

[`mariner_setup_project()`](https://thomasqmd.github.io/mariner/reference/mariner_setup_project.md),
[`mariner_install_fonts()`](https://thomasqmd.github.io/mariner/reference/mariner_install_fonts.md)

## Examples

``` r
if (FALSE) { # \dontrun{
mariner_check_setup()

# Just the problems:
report <- mariner_check_setup(quiet = TRUE)
subset(report, status != "ok")
} # }
```
