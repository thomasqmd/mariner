# Set global ggplot2 theme and scale defaults

Sets
[`theme_mariner()`](https://thomasqmd.github.io/mariner/reference/theme_mariner.md)
as the global default theme and configures default discrete and
continuous scales so subsequent plots use the brand palette
automatically.

## Usage

``` r
mariner_set_theme(theme = mariner_themes, format = mariner_formats, ...)
```

## Arguments

- theme:

  Theme name. Defaults to the built-in mariner theme.

- format:

  One of
  [mariner_formats](https://thomasqmd.github.io/mariner/reference/mariner_formats.md).

- ...:

  Arguments passed to
  [`theme_mariner()`](https://thomasqmd.github.io/mariner/reference/theme_mariner.md).

## Value

Invisibly returns the previous theme.

## Examples

``` r
mariner_set_theme()
```
