# Locate the project root

Resolves the directory that `assets/`, `reports/` and `zip_files/` sit
beneath, in this order:

## Usage

``` r
mariner_project_root(path = ".")
```

## Arguments

- path:

  Directory to search upward from. Defaults to the working directory.

## Value

A normalised absolute path.

## Details

1.  `getOption("mariner.project_root")`, if set. The escape hatch for a
    session whose working directory is not where the reports belong.

2.  The nearest ancestor of `path`, `path` included, that holds an
    `.Rproj` file, a `_quarto.yml`, or a `DESCRIPTION`.

3.  A directory holding all three mariner folders, so a project
    [`mariner_setup_project()`](https://thomasqmd.github.io/mariner/reference/mariner_setup_project.md)
    scaffolded is found again without also being an RStudio or Quarto
    project. This one counts at `path` itself, and further up only when
    the search climbed out of `assets/`, `reports/` or `zip_files/`.
    Those folders are created for you, so an abandoned set in a parent
    directory does not capture a new project started beneath it.

4.  `path` itself, normalised.

`.git` is not a marker here, though it is one for
[`mariner_looks_like_project()`](https://thomasqmd.github.io/mariner/reference/mariner_looks_like_project.md).
See the comment in `R/setup.R` for why.

A `root` argument to
[`mariner_dirs()`](https://thomasqmd.github.io/mariner/reference/mariner_dirs.md)
or
[`mariner_setup_project()`](https://thomasqmd.github.io/mariner/reference/mariner_setup_project.md)
beats all three. Those functions call this one only when `root` is
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
#> [1] "/private/var/folders/k3/k8hfzfxd11j6vy0_t2rx27yw0000gn/T/RtmpTXSPL8"
```
