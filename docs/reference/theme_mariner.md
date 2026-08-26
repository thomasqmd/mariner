# Branded ggplot2 theme for mariner

A ggplot2 theme that matches the page: the brand typeface, background,
ink and grid rules.

## Usage

``` r
theme_mariner(
  theme = mariner_themes,
  format = mariner_formats,
  base_size = 11,
  base_family = NULL,
  ...
)
```

## Arguments

- theme:

  Theme name. Defaults to the built-in mariner theme.

- format:

  One of
  [mariner_formats](https://thomasqmd.github.io/mariner/reference/mariner_formats.md).

- base_size:

  Base font size in points. Defaults to `11`, the report body size set
  in `_extension.yml`.

- base_family:

  Font family. Defaults to `"Atkinson Hyperlegible Next"`.

- ...:

  Further arguments for
  [`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html).

## Value

A ggplot2 theme object.

## Examples

``` r
library(ggplot2)
# base_family = "" keeps the device's own font. The bundled families reach a
# plot through systemfonts, which the base pdf() device does not read. A
# report renders through cairo_pdf and gets the real face.
ggplot(mpg, aes(displ, hwy, colour = class)) +
  geom_point() +
  scale_colour_mariner_d() +
  theme_mariner(base_family = "")
```
