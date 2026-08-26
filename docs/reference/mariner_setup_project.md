# Set up a mariner project

Creates the folders a mariner workflow uses, installs the Quarto theme
into them, and drops in a starter report. Run it twice and nothing
changes: a file that exists is left alone unless `overwrite = TRUE`.

## Usage

``` r
mariner_setup_project(
  root = NULL,
  theme = mariner_themes,
  template = "report",
  overwrite = FALSE
)
```

## Arguments

- root:

  Project root. `NULL` (the default) resolves it with
  [`mariner_project_root()`](https://thomasqmd.github.io/mariner/reference/mariner_project_root.md),
  which is the working directory unless that is one of the mariner
  folders. Pass a path to override.

- theme:

  One of
  [mariner_themes](https://thomasqmd.github.io/mariner/reference/mariner_themes.md).

- template:

  Starter template to copy into `reports/`. `NULL` for no starter
  document.

- overwrite:

  Replace files that already exist. The folders themselves are never
  removed.

## Value

The named list from
[`mariner_dirs()`](https://thomasqmd.github.io/mariner/reference/mariner_dirs.md),
invisibly.

## Details

Beneath `root`:

    assets/
      _extensions/mariner/          the theme, assembled once
    reports/
      _extensions/mariner/          a copy, beside the documents that use it
      report.qmd                    a starter document
    zip_files/                      the bundles you hand out

`zip_files/`, `assets/_extensions/` and `reports/_extensions/` go into
the project `.gitignore`. All three are build outputs, and a committed
copy goes stale against what it was built from.

## See also

[`mariner_dirs()`](https://thomasqmd.github.io/mariner/reference/mariner_dirs.md),
[`mariner_install_fonts()`](https://thomasqmd.github.io/mariner/reference/mariner_install_fonts.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# In an RStudio project or Quarto project directory:
mariner_setup_project()

# Or somewhere explicit:
mariner_setup_project(root = "~/classes/stat3010")
} # }
```
