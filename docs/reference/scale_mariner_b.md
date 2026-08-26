# Binned colour and fill scales for mariner

The sequential palette cut into steps. Use it when a reader has to name
the band a point falls in.

## Usage

``` r
scale_colour_mariner_b(reverse = FALSE, ...)

scale_color_mariner_b(reverse = FALSE, ...)

scale_fill_mariner_b(reverse = FALSE, ...)
```

## Arguments

- reverse:

  Logical; if `TRUE`, reverse the steps.

- ...:

  Further arguments for
  [`ggplot2::scale_colour_stepsn()`](https://ggplot2.tidyverse.org/reference/scale_steps.html)
  or
  [`ggplot2::scale_fill_stepsn()`](https://ggplot2.tidyverse.org/reference/scale_steps.html).

## Value

A ggplot2 binned scale object.

## Examples

``` r
library(ggplot2)
ggplot(mpg, aes(displ, hwy, colour = cty)) +
  geom_point() +
  scale_colour_mariner_b()
```
