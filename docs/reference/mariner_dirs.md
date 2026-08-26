# The mariner project folders

The single source for every default path in the package. Returns the
three directories mariner works in, as a named list:

## Usage

``` r
mariner_dirs(root = NULL)
```

## Arguments

- root:

  Project root. `NULL` (the default) resolves it with
  [`mariner_project_root()`](https://thomasqmd.github.io/mariner/reference/mariner_project_root.md).

## Value

A named list of three absolute paths: `assets`, `reports`, `zips`.

## Details

- `assets`:

  `assets/` – the Quarto extension, assembled once by
  [`mariner_setup_project()`](https://thomasqmd.github.io/mariner/reference/mariner_setup_project.md).
  Every render stages the theme from here, so a batch of fifty reports
  unpacks it once.

- `reports`:

  `reports/` – the `.qmd` sources, their PDFs, and a copy of
  `_extensions/`. The extension has to sit *beside* the documents:
  xelatex resolves the font paths in `brand-preamble.tex` against the
  directory that holds the `.tex`. An extension one level up gives a
  document that finds its format and then dies with "the font
  Lora-Regular cannot be found".

- `zips`:

  `zip_files/` – the bundles you hand out.

The paths come back whether or not the directories exist.
[`mariner_setup_project()`](https://thomasqmd.github.io/mariner/reference/mariner_setup_project.md)
and `.onAttach()` create them.

## See also

[`mariner_setup_project()`](https://thomasqmd.github.io/mariner/reference/mariner_setup_project.md),
[`mariner_project_root()`](https://thomasqmd.github.io/mariner/reference/mariner_project_root.md)

## Examples

``` r
mariner_dirs(root = tempdir())
#> $assets
#> [1] "/private/var/folders/k3/k8hfzfxd11j6vy0_t2rx27yw0000gn/T/RtmpWsU1oN/assets"
#> 
#> $reports
#> [1] "/private/var/folders/k3/k8hfzfxd11j6vy0_t2rx27yw0000gn/T/RtmpWsU1oN/reports"
#> 
#> $zips
#> [1] "/private/var/folders/k3/k8hfzfxd11j6vy0_t2rx27yw0000gn/T/RtmpWsU1oN/zip_files"
#> 

# Every default path in the package is composed from this:
mariner_dirs(root = tempdir())$reports
#> [1] "/private/var/folders/k3/k8hfzfxd11j6vy0_t2rx27yw0000gn/T/RtmpWsU1oN/reports"
```
