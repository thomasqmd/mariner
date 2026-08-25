# mariner: Streamline Quarto Report Generation and Bundling

The `mariner` package simplifies and automates the process of creating
and packaging Quarto (.qmd) documents. It provides a cohesive workflow
for first generating multiple document source files from a single
parameterized template, and then bundling those source files along with
all their rendered outputs (e.g., PDFs, scripts, and dependency files)
into easily shareable zip archives.

It also carries a complete Baylor-branded Quarto theme, so a generated
report is styled, typeset in bundled fonts, and has its figures drawn
from the same palette as the page, without anything to install
separately.

## Core Workflow

1.  Run
    [`mariner_check_setup`](https://thomasqmd.github.io/mariner/reference/mariner_check_setup.md)
    to confirm this machine has everything a branded report needs –
    Quarto, a LaTeX engine, the fonts. It reports and prints the fix; it
    changes nothing.

2.  Use
    [`mariner_setup_project`](https://thomasqmd.github.io/mariner/reference/mariner_setup_project.md)
    once to create the project folders and install the theme assets into
    them.

3.  Use
    [`generate_reports`](https://thomasqmd.github.io/mariner/reference/generate_reports.md)
    to create multiple, parameterized `.qmd` source files from a
    template, into `reports/`.

4.  Use
    [`process_files`](https://thomasqmd.github.io/mariner/reference/process_files.md)
    to render each source file and bundle the source, R script, and all
    outputs into a zip archive, into `zip_files/`.

## Project Folders

mariner works in three directories beneath the project root, returned by
[`mariner_dirs`](https://thomasqmd.github.io/mariner/reference/mariner_dirs.md):

- `assets/`:

  The built Quarto extension, assembled once.

- `reports/`:

  Generated `.qmd` sources, their rendered PDFs, and a copy of the
  extension beside them.

- `zip_files/`:

  The bundles handed to students.

Attaching the package with
[`library(mariner)`](https://thomasqmd.github.io/mariner/) creates the
three folders if the working directory looks like a project root – see
[`mariner_looks_like_project`](https://thomasqmd.github.io/mariner/reference/mariner_looks_like_project.md).
Set `options(mariner.auto_setup = FALSE)` to turn that off.

## See also

Useful links:

- <https://thomasqmd.github.io/mariner/>

- <https://github.com/thomasqmd/mariner>

- Report bugs at <https://github.com/thomasqmd/mariner/issues>

## Author

**Maintainer**: Thomas Reinke <thomas_reinke1@baylor.edu>
