# Bundle a Quarto File and its Outputs

Renders a Quarto (`.qmd`) file in a scratch directory and bundles the
source, the purled R script, the rendered document and the render's
intermediates into a single zip archive.

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

  Path to the input `.qmd` file.

- output_zip:

  Path for the output `.zip`. Defaults to the project's `zip_files/`
  folder – see
  [`mariner_dirs()`](https://thomasqmd.github.io/mariner/reference/mariner_dirs.md)
  – under the source's name.

- theme:

  One of
  [mariner_themes](https://thomasqmd.github.io/mariner/reference/mariner_themes.md).

- assets_dir:

  Directory holding an already-built extension, as
  [`mariner_setup_project()`](https://thomasqmd.github.io/mariner/reference/mariner_setup_project.md)
  leaves in `assets/`. Pass `NULL` to assemble one from the installed
  package for this render instead.

- include:

  Which categories of file to bundle. Any of `"source"`, `"script"`,
  `"output"`, `"intermediates"`.

## Value

Invisibly, the path to the created zip file.

## Details

The render happens in a temporary directory with the theme staged beside
the document, not in place, so nothing is written next to the source and
parallel callers cannot collide on a shared cache.

`include` selects what reaches the archive:

- `source`:

  the `.qmd` itself

- `script`:

  the purled `.R`

- `output`:

  the rendered document, and its `_files/` directory – which an HTML
  document is broken without

- `intermediates`:

  everything else the render left behind, such as the `.tex` when
  `keep-tex` is set

The Quarto extension is never bundled. Reports are rendered inside a
project that already has it, and a copy per archive would add ~1.3 MB to
each.

## Examples

``` r
if (FALSE) { # \dontrun{
temp_dir <- tempfile("example-")

doc <- generate_reports(
  params_df = data.frame(chapter = 1, problem_numbers = 1, author = "A. Name"),
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
