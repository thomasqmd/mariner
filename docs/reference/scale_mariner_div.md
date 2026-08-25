# Diverging colour and fill scales for mariner

Diverging colour and fill scales for mariner

## Usage

``` r
scale_colour_mariner_div(reverse = FALSE, ...)

scale_color_mariner_div(reverse = FALSE, ...)

scale_fill_mariner_div(reverse = FALSE, ...)
```

## Arguments

- reverse:

  Logical; if `TRUE`, reverses the color gradient.

- ...:

  Arguments passed to
  [`ggplot2::scale_colour_gradientn()`](https://ggplot2.tidyverse.org/reference/scale_gradient.html)
  or
  [`ggplot2::scale_fill_gradientn()`](https://ggplot2.tidyverse.org/reference/scale_gradient.html).

## Value

A ggplot2 diverging scale object.
