# Diverging colour and fill scales for mariner

A signed quantity, where the neutral step means no difference. Set
`limits` symmetrically, or the neutral step lands wherever the data
straddles.

## Usage

``` r
scale_colour_mariner_div(reverse = FALSE, ...)

scale_color_mariner_div(reverse = FALSE, ...)

scale_fill_mariner_div(reverse = FALSE, ...)
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

A ggplot2 diverging scale object.

## Examples

``` r
library(ggplot2)
mpg$delta <- mpg$hwy - mean(mpg$hwy)
lim <- max(abs(mpg$delta))
ggplot(mpg, aes(displ, hwy, colour = delta)) +
  geom_point() +
  scale_colour_mariner_div(limits = c(-lim, lim))
```
