# Ordinal colour and fill scales for mariner

A few ranked levels. The palette ramps rather than contrasts, so the
colours carry the order.

## Usage

``` r
scale_colour_mariner_o(reverse = FALSE, ...)

scale_color_mariner_o(reverse = FALSE, ...)

scale_fill_mariner_o(reverse = FALSE, ...)
```

## Arguments

- reverse:

  Logical; if `TRUE`, reverse the ramp.

- ...:

  Further arguments for
  [`ggplot2::discrete_scale()`](https://ggplot2.tidyverse.org/reference/discrete_scale.html).

## Value

A ggplot2 discrete scale object for ordered categories.

## Examples

``` r
library(ggplot2)
mpg$size <- cut(mpg$displ, 3, labels = c("Small", "Medium", "Large"))
ggplot(mpg, aes(hwy, fill = size)) +
  geom_histogram(bins = 20) +
  scale_fill_mariner_o()
```
