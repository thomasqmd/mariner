# Set global ggplot2 theme and scale defaults

Makes
[`theme_mariner()`](https://thomasqmd.github.io/mariner/reference/theme_mariner.md)
the global ggplot2 theme and the brand palettes the default discrete and
continuous scales. Later plots need no scale call.

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

  Further arguments for
  [`theme_mariner()`](https://thomasqmd.github.io/mariner/reference/theme_mariner.md).

## Value

Invisibly, the previous theme.

## Examples

``` r
# This changes global ggplot2 state. The return value puts it back.
old <- mariner_set_theme()
ggplot2::theme_set(old)
```
