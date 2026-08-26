# mariner: Streamline Quarto Report Generation and Bundling

mariner turns one parameterized Quarto template into a set of `.qmd`
reports, renders them, and bundles each source, R script and PDF into a
zip archive.

The package carries its own Quarto PDF theme. A report is typeset in the
bundled fonts, and its figures use the palette the page does.

## Core Workflow

1.  [`mariner_check_setup`](https://thomasqmd.github.io/mariner/reference/mariner_check_setup.md)
    confirms this machine has what a report needs: Quarto, a LaTeX
    engine, the fonts. It changes nothing and prints the fix for
    whatever is missing.

2.  [`mariner_setup_project`](https://thomasqmd.github.io/mariner/reference/mariner_setup_project.md)
    creates the project folders and installs the theme into them. Run it
    once.

3.  [`generate_reports`](https://thomasqmd.github.io/mariner/reference/generate_reports.md)
    writes one `.qmd` per row of a parameter data frame into `reports/`.

4.  [`process_files`](https://thomasqmd.github.io/mariner/reference/process_files.md)
    renders each one and bundles the source, the R script and the
    outputs into `zip_files/`.

## Project Folders

mariner works in three directories beneath the project root. See
[`mariner_dirs`](https://thomasqmd.github.io/mariner/reference/mariner_dirs.md).

- `assets/`:

  The Quarto extension, assembled once.

- `reports/`:

  The `.qmd` sources, their PDFs, and a copy of the extension beside
  them.

- `zip_files/`:

  The bundles you hand out.

[`library(mariner)`](https://thomasqmd.github.io/mariner/) creates the
three folders when the working directory looks like a project root. See
[`mariner_looks_like_project`](https://thomasqmd.github.io/mariner/reference/mariner_looks_like_project.md).
Set `options(mariner.auto_setup = FALSE)` to turn that off.

## See also

Useful links:

- <https://thomasqmd.github.io/mariner/>

- <https://github.com/thomasqmd/mariner>

- Report bugs at <https://github.com/thomasqmd/mariner/issues>

## Author

**Maintainer**: Thomas Reinke <thomas_reinke1@baylor.edu>
