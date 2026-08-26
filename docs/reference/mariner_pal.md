# Brand palette generator

Builds a discrete, sequential, ordinal, or diverging palette for a
theme.

## Usage

``` r
mariner_pal(
  theme = mariner_themes,
  family = c("discrete", "sequential", "ordinal", "diverging"),
  n = NULL,
  reverse = FALSE
)
```

## Arguments

- theme:

  Theme name. Defaults to the built-in mariner theme.

- family:

  Palette family: `"discrete"`, `"sequential"`, `"ordinal"`, or
  `"diverging"`.

- n:

  Number of colours. `NULL` (the default) returns a palette function
  `function(n)` instead.

- reverse:

  Logical; if `TRUE`, reverse the colour vector.

## Value

A character vector of hex colours, or a palette function when `n` is
`NULL`.

## Examples

``` r
mariner_pal(family = "discrete", n = 4)
#> [1] "#017553" "#c08802" "#aa4499" "#979731"
mariner_pal(family = "diverging", n = 7)
#> [1] "#017553" "#649C83" "#A8C3B6" "#E9ECEA" "#DECAAC" "#CFAA6B" "#C08802"
pal_fn <- mariner_pal(family = "sequential")
pal_fn(5)
#> [1] "#EAF7F1" "#B2C8BD" "#7D9B8C" "#49705E" "#154734"
```
