# Figure dimensions for a branded report

The drawing area a figure gets on the page. The geometry in
`_extension.yml` (US Letter, 1in left and right, 0.75in top and bottom)
leaves 6.5in of text width. The 4.5in height sits under 3:2, which
leaves room for a caption and the prose around it.

## Usage

``` r
mariner_fig_dims(format = mariner_formats)
```

## Arguments

- format:

  One of
  [mariner_formats](https://thomasqmd.github.io/mariner/reference/mariner_formats.md).

## Value

A named list with numeric `width` and `height` in inches.

## Examples

``` r
mariner_fig_dims("pdf")
#> $width
#> [1] 6.5
#> 
#> $height
#> [1] 4.5
#> 
```
