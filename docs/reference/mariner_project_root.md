# Locate the project root

Resolves the directory that `reports/`, `zip_files/` and `assets/` are
created beneath, in this order:

## Usage

``` r
mariner_project_root(path = ".")
```

## Arguments

- path:

  Directory to start the upward search from. Defaults to the working
  directory.

## Value

A normalised absolute path.

## Details

1.  `getOption("mariner.project_root")`, if set. The escape hatch, for a
    session whose working directory is not where the reports belong.

2.  The nearest ancestor of `path` – starting with `path` itself – that
    contains an `.Rproj` file, a `_quarto.yml`, or a `DESCRIPTION`.

3.  `path` itself, normalised.

Note that `.git` is *not* a marker here, though it is one for
[`mariner_looks_like_project()`](https://thomasqmd.github.io/mariner/reference/mariner_looks_like_project.md).
See the comment in `R/setup.R` for why.

An explicit `root =` argument to
[`mariner_dirs()`](https://thomasqmd.github.io/mariner/reference/mariner_dirs.md)
or
[`mariner_setup_project()`](https://thomasqmd.github.io/mariner/reference/mariner_setup_project.md)
beats all three – those functions only consult this one when `root` is
`NULL`.

## See also

[`mariner_dirs()`](https://thomasqmd.github.io/mariner/reference/mariner_dirs.md),
[`mariner_looks_like_project()`](https://thomasqmd.github.io/mariner/reference/mariner_looks_like_project.md)

## Examples

``` r
mariner_project_root()
#> [1] "/Users/thomasreinke/Library/CloudStorage/OneDrive-Personal/Personal R Projects/mariner"

# The option wins over the search:
withr::with_options(
  list(mariner.project_root = tempdir()),
  mariner_project_root()
)
#> [1] "/private/var/folders/k3/k8hfzfxd11j6vy0_t2rx27yw0000gn/T/RtmpzQHXJH"
```
