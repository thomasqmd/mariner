# Set up a mariner project

Creates the folder structure a mariner workflow expects, installs the
Quarto theme into it, and drops in a starter report. Safe to run twice:
nothing already present is replaced unless `overwrite = TRUE`.

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
  so running this from a subdirectory scaffolds the project rather than
  the subdirectory. Pass a path to override.

- theme:

  One of
  [mariner_themes](https://thomasqmd.github.io/mariner/reference/mariner_themes.md).

- template:

  Name of the starter template to copy into `reports/`. Pass `NULL` for
  no starter document.

- overwrite:

  Replace files that already exist. The folders themselves are never
  removed.

## Value

The named list from
[`mariner_dirs()`](https://thomasqmd.github.io/mariner/reference/mariner_dirs.md),
invisibly.

## Details

What it creates, beneath `root`:

    assets/
      _extensions/mariner-baylor/   the theme, assembled once
    reports/
      _extensions/mariner-baylor/   a copy, beside the documents that use it
      report.qmd                    a starter document
    zip_files/                      the bundles handed to students

`zip_files/`, `assets/_extensions/` and `reports/_extensions/` are
appended to the project `.gitignore`. All three are build outputs: the
archives are rebuilt from the sources beside them, and the extension is
assembled from the installed package, so committing either means
committing a copy that can go stale against what it was built from.

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
