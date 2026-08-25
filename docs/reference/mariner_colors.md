# Named colour vector for a theme

Extracts all named colours and semantic roles defined in the theme's
`_brand.yml`.

## Usage

``` r
mariner_colors(theme = mariner_themes)
```

## Arguments

- theme:

  Theme name. Defaults to the built-in mariner theme.

## Value

A named character vector of hex codes.

## Examples

``` r
mariner_colors()
#>      background      foreground    baylor-green university-gold        gold-ink 
#>       "#fefefe"       "#222222"       "#154734"       "#FFB81C"       "#9b6e06" 
#>       gold-rule  series-1-green   series-2-gold series-3-purple  series-4-olive 
#>       "#c28a01"       "#017553"       "#c08802"       "#aa4499"       "#979731" 
#>    series-5-sky series-6-orange series-7-indigo   series-8-rose           seq-1 
#>       "#0178bc"       "#e8712a"       "#493fa6"       "#cc6677"       "#eaf7f1" 
#>           seq-2           seq-3           seq-4           seq-5           seq-6 
#>       "#c5d7ce"       "#a0b9ad"       "#7d9b8c"       "#5b7e6d"       "#396250" 
#>           seq-7           ord-1           ord-2           ord-3           ord-4 
#>       "#154734"       "#a8b4ae"       "#83988e"       "#5f7c6e"       "#3b6150" 
#>           ord-5           div-1           div-2           div-3           div-4 
#>       "#154734"       "#017553"       "#649c83"       "#a8c3b6"       "#e9ecea" 
#>           div-5           div-6           div-7             ink   ink-secondary 
#>       "#decaac"       "#cfaa6b"       "#c08802"       "#222222"       "#4a4f4b" 
#>       ink-muted       rule-grid       rule-axis         primary       secondary 
#>       "#6f7671"       "#dfe3e0"       "#c2c8c4"       "#154734"       "#c28a01" 
#>            link      accent-ink     accent-rule      on-primary    on-secondary 
#>       "#154734"       "#9a6e13"       "#c28a01"       "#fefefe"       "#222222" 
#>        series-1        series-2        series-3        series-4        series-5 
#>       "#017553"       "#c08802"       "#aa4499"       "#979731"       "#0178bc" 
#>        series-6        series-7        series-8 
#>       "#e8712a"       "#493fa6"       "#cc6677" 
mariner_colors()[c("primary", "secondary")]
#>   primary secondary 
#> "#154734" "#c28a01" 
```
