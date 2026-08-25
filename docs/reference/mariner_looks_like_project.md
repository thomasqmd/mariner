# Does this directory look like a project root?

The guard `.onAttach()` uses before it creates anything. A directory
counts as a project root if it contains an `.Rproj` file, a
`_quarto.yml`, a `DESCRIPTION`, or a `.git` directory.

## Usage

``` r
mariner_looks_like_project(path = ".")
```

## Arguments

- path:

  Directory to test. Defaults to the working directory.

## Value

`TRUE` or `FALSE`.

## Details

This is exported so the attach behaviour is inspectable rather than
mysterious: if
[`library(mariner)`](https://thomasqmd.github.io/mariner/) did not
create the folders you expected, `mariner_looks_like_project(getwd())`
says why in one call.

## See also

[`mariner_project_root()`](https://thomasqmd.github.io/mariner/reference/mariner_project_root.md),
[`mariner_dirs()`](https://thomasqmd.github.io/mariner/reference/mariner_dirs.md)

## Examples

``` r
# The directory R is currently running in:
mariner_looks_like_project(getwd())
#> [1] FALSE

# An empty temporary directory is not a project:
mariner_looks_like_project(tempdir())
#> [1] FALSE
```
