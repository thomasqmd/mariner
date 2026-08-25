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

  `assets/` – holds the built Quarto extension, assembled once by
  [`mariner_setup_project()`](https://thomasqmd.github.io/mariner/reference/mariner_setup_project.md).
  This is the copy renders are served from, so a batch of fifty reports
  unpacks the theme once rather than fifty times.

- `reports`:

  `reports/` – the generated `.qmd` sources, their rendered PDFs, and a
  copy of `_extensions/`. The extension has to sit *beside* the
  documents: `brand-preamble.tex` reaches the bundled fonts through a
  relative path that xelatex resolves against the directory holding the
  `.tex`, so an extension one level up gives a document that finds its
  format and then dies with "the font Lora-Regular cannot be found".

- `zips`:

  `zip_files/` – the bundles handed to students.

The paths are returned whether or not the directories exist. Creating
them is
[`mariner_setup_project()`](https://thomasqmd.github.io/mariner/reference/mariner_setup_project.md)'s
job, and `.onAttach()`'s.

## See also

[`mariner_setup_project()`](https://thomasqmd.github.io/mariner/reference/mariner_setup_project.md),
[`mariner_project_root()`](https://thomasqmd.github.io/mariner/reference/mariner_project_root.md)

## Examples

``` r
mariner_dirs(root = tempdir())
#> $assets
#> [1] "/private/var/folders/k3/k8hfzfxd11j6vy0_t2rx27yw0000gn/T/RtmpzQHXJH/assets"
#> 
#> $reports
#> [1] "/private/var/folders/k3/k8hfzfxd11j6vy0_t2rx27yw0000gn/T/RtmpzQHXJH/reports"
#> 
#> $zips
#> [1] "/private/var/folders/k3/k8hfzfxd11j6vy0_t2rx27yw0000gn/T/RtmpzQHXJH/zip_files"
#> 

# Every default path in the package is composed from this:
mariner_dirs(root = tempdir())$reports
#> [1] "/private/var/folders/k3/k8hfzfxd11j6vy0_t2rx27yw0000gn/T/RtmpzQHXJH/reports"
```
