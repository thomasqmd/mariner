# Discrete colour and fill scales for mariner

Discrete colour and fill scales for mariner

## Usage

``` r
scale_colour_mariner_d(reverse = FALSE, ...)

scale_color_mariner_d(reverse = FALSE, ...)

scale_fill_mariner_d(reverse = FALSE, ...)
```

## Arguments

- reverse:

  Logical; if `TRUE`, reverses the color vector.

- ...:

  Arguments passed to
  [`ggplot2::discrete_scale()`](https://ggplot2.tidyverse.org/reference/discrete_scale.html).

## Value

A ggplot2 discrete scale object.

## Examples

``` r
library(ggplot2)
ggplot(mpg, aes(displ, hwy, colour = class)) +
  geom_point() +
  scale_colour_mariner_d()
```
