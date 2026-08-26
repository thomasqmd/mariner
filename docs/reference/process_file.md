# Bundle a Quarto file and its outputs

Renders a Quarto (`.qmd`) file and bundles the source, the purled R
script, the rendered document and the render's intermediates into one
zip archive.

## Usage

``` r
process_file(
  input_file,
  output_zip = NULL,
  theme = mariner_themes,
  assets_dir = mariner_dirs()$assets,
  include = INCLUDE_KINDS
)
```

## Arguments

- input_file:

  Path to the input `.qmd`.

- output_zip:

  Path for the output `.zip`. Defaults to the source's name in the
  project's `zip_files/` folder. See
  [`mariner_dirs()`](https://thomasqmd.github.io/mariner/reference/mariner_dirs.md).

- theme:

  One of
  [mariner_themes](https://thomasqmd.github.io/mariner/reference/mariner_themes.md).

- assets_dir:

  Directory that holds a built extension, as
  [`mariner_setup_project()`](https://thomasqmd.github.io/mariner/reference/mariner_setup_project.md)
  leaves in `assets/`. `NULL` assembles one from the installed package
  for this render.

- include:

  Which categories to bundle. Any of `"source"`, `"script"`, `"output"`,
  `"intermediates"`.

## Value

Invisibly, the path to the zip file.

## Details

The render runs in a temporary directory, with the theme staged next to
the document. Nothing lands beside the source, and parallel callers
cannot collide on a shared cache.

`include` selects what reaches the archive:

- `source`:

  the `.qmd` itself

- `script`:

  the purled `.R`

- `output`:

  the rendered document and its `_files/` directory

- `intermediates`:

  whatever else the render left behind, such as the `.tex` under
  `keep-tex`

The Quarto extension is never bundled. A report renders inside a project
that has one, and a copy per archive costs ~1.3 MB.

## Examples

``` r
if (FALSE) { # \dontrun{
temp_dir <- tempfile("example-")

doc <- generate_reports(
  params_df = data.frame(chapter = 1, problem_numbers = 1),
  output_dir = temp_dir
)

# Everything, into zip_files/:
process_file(doc)

# Just the source and the PDF, somewhere explicit:
process_file(
  doc,
  output_zip = file.path(temp_dir, "handout.zip"),
  include = c("source", "output")
)

unlink(temp_dir, recursive = TRUE)
} # }
```
