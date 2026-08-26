# Set up a mariner project

Creates the folders a mariner workflow uses, installs the Quarto theme
into them, drops in a starter report, and records the project's author.
Run it twice and nothing changes: a file that exists is left alone
unless `overwrite = TRUE`.

## Usage

``` r
mariner_setup_project(
  root = NULL,
  theme = mariner_themes,
  template = "report",
  author = NULL,
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

- author:

  Name for the project's author, written to `_mariner.yml`. See the
  section below. `NULL` (the default) writes no file and leaves any
  existing setting alone. A name here is written whether or not
  `overwrite` is set: `overwrite` guards the files setup scaffolds and a
  student then edits, and `author` is itself the instruction to change
  this one.

- overwrite:

  Replace files that already exist. The folders themselves are never
  removed.

## Value

The named list from
[`mariner_dirs()`](https://thomasqmd.github.io/mariner/reference/mariner_dirs.md),
invisibly.

## Details

Beneath `root`:

    _mariner.yml                    project settings, when author is given
    assets/
      _extensions/mariner/          the theme, assembled once
    reports/
      _extensions/mariner/          a copy, beside the documents that use it
      report.qmd                    a starter document
    zip_files/                      the bundles you hand out

`zip_files/`, `assets/_extensions/` and `reports/_extensions/` go into
the project `.gitignore`. All three are build outputs, and a committed
copy goes stale against what it was built from. `_mariner.yml` is not
ignored — it is a setting, and it belongs with the project.

## The author

`author` is a project setting, not a column of
[`generate_reports()`](https://thomasqmd.github.io/mariner/reference/generate_reports.md)'s
`params_df`. One person runs a batch, and it is their name on every
report in it. As a column it had to be retyped on every call, and a call
that omitted it produced a batch of PDFs that carried the template's
placeholder on every title page. The render succeeded, so nothing said
so.

The name goes to `_mariner.yml`, and
[`generate_reports()`](https://thomasqmd.github.io/mariner/reference/generate_reports.md)
fills any template parameter that matches it. A `params_df` column still
wins, for the batch whose author does vary.

## See also

[`mariner_dirs()`](https://thomasqmd.github.io/mariner/reference/mariner_dirs.md),
[`mariner_install_fonts()`](https://thomasqmd.github.io/mariner/reference/mariner_install_fonts.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# In an RStudio project or Quarto project directory:
mariner_setup_project(author = "Alice Smith")

# Or somewhere explicit:
mariner_setup_project(root = "~/classes/stat3010", author = "Alice Smith")

# Change the author later. This touches nothing else:
mariner_setup_project(author = "A. Smith", template = NULL)
} # }
```
