# Global knitr setup for branded Quarto documents

Sets the chunk options a report needs – figure size, resolution, device
– and applies the brand ggplot2 theme. Call it in the setup chunk.

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

  Figure resolution in dots per inch. Defaults to `300`.

- fig_format:

  Graphics device. Defaults to `"cairo_pdf"` where the build has cairo,
  base `"pdf"` where it does not.

- ...:

  Further chunk options for `knitr::opts_chunk$set()`.

## Value

Invisibly, the previous chunk options.

## Examples

``` r
if (FALSE) { # \dontrun{
mariner_knitr_setup("pdf")
} # }
```
