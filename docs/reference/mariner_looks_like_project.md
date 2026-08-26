# Does this directory look like a project root?

The guard `.onAttach()` uses before it creates anything. A directory
counts as a project root if it holds an `.Rproj` file, a `_quarto.yml`,
a `DESCRIPTION`, a `.git` directory, or all three mariner folders.

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

The last of those is what makes a directory
[`mariner_setup_project()`](https://thomasqmd.github.io/mariner/reference/mariner_setup_project.md)
scaffolded count as a project afterwards, without it also having to be
an RStudio or Quarto one.

It is exported so the attach behaviour can be checked: if
[`library(mariner)`](https://thomasqmd.github.io/mariner/) did not
create the folders you expected, this says why.

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
