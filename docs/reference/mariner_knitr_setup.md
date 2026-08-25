# Global knitr setup for branded Quarto documents

Configures knitr chunk options with figure dimensions, resolution, and
theme settings. Call it in the setup chunk of a report.

## Usage

``` r
mariner_knitr_setup(
  format = mariner_formats,
  theme = mariner_themes,
  dpi = 300,
  fig_format = NULL,
  ...
)
```

## Arguments

- format:

  One of
  [mariner_formats](https://thomasqmd.github.io/mariner/reference/mariner_formats.md).

- theme:

  Theme name. Defaults to the built-in mariner theme.

- dpi:

  Numeric figure resolution in dots per inch. Defaults to `300`.

- fig_format:

  Image device. Defaults to `"cairo_pdf"` where the build has cairo, and
  base `"pdf"` where it does not.

- ...:

  Additional chunk options passed to `knitr::opts_chunk$set()`.

## Value

Invisibly returns the previous knitr chunk options.

## Examples

``` r
if (FALSE) { # \dontrun{
mariner_knitr_setup("pdf")
} # }
```
