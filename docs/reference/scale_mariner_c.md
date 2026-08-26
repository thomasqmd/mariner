# Continuous colour and fill scales for mariner

Magnitude on one hue, as a smooth gradient.

## Usage

``` r
scale_colour_mariner_c(reverse = FALSE, ...)

scale_color_mariner_c(reverse = FALSE, ...)

scale_fill_mariner_c(reverse = FALSE, ...)
```

## Arguments

- reverse:

  Logical; if `TRUE`, reverse the gradient.

- ...:

  Further arguments for
  [`ggplot2::scale_colour_gradientn()`](https://ggplot2.tidyverse.org/reference/scale_gradient.html)
  or
  [`ggplot2::scale_fill_gradientn()`](https://ggplot2.tidyverse.org/reference/scale_gradient.html).

## Value

A ggplot2 continuous scale object.

## Examples

``` r
library(ggplot2)
ggplot(mpg, aes(displ, hwy, colour = cty)) +
  geom_point() +
  scale_colour_mariner_c()
```
