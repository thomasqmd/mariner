# Check that this machine can render a mariner report

Checks what a report needs: Quarto, a LaTeX engine, the fonts, the
project folders, the theme, and the packages the template loads. One
line per check, with the fix to paste for anything that is wrong.

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

Nothing is installed or changed. You run the remedies.

## What the statuses mean

- ok:

  Nothing to do.

- warn:

  The report renders, but not as intended. Usually the figures come out
  in the device's default typeface while the page text does not.

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
