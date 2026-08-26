# mariner

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/thomasqmd/mariner/actions/workflows/r.yml/badge.svg)](https://github.com/thomasqmd/mariner/actions/workflows/r.yml)
[![codecov](https://codecov.io/github/thomasqmd/mariner/graph/badge.svg?token=A4PDZWC3IL)](https://codecov.io/github/thomasqmd/mariner)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**mariner** turns one parameterized Quarto template into a set of
reports, renders them, and bundles each one into a zip archive. It
carries its own Quarto PDF theme: typography, brand colours, and
matching `ggplot2` scales.

Documentation: <https://thomasqmd.github.io/mariner/>.

## Installation

The development version, from GitHub:

`# install.packages("pak")`` ``pak``::`[`pak`](https://pak.r-lib.org/reference/pak.html)`(``"thomasqmd/mariner"``)`

## Folder Structure

mariner works in three project directories:

    your-project/
    ├── assets/          # the Quarto theme, assembled once
    ├── reports/         # the .qmd sources, their PDFs, and _extensions/
    └── zip_files/       # one archive per report: PDF, source, R script

## Quickstart

[`library`](https://rdrr.io/r/base/library.html)`(`[`mariner`](https://thomasqmd.github.io/mariner/)`)`` `[`library`](https://rdrr.io/r/base/library.html)`(`[`tidyr`](https://tidyr.tidyverse.org)`)`` `` ``# 1. Create the folders and install the Quarto theme`` `[`mariner_setup_project`](https://thomasqmd.github.io/mariner/reference/mariner_setup_project.md)`(``)`` `` ``# 2. One row per report`` ``report_params`` ``<-`` `[`expand_grid`](https://tidyr.tidyverse.org/reference/expand_grid.html)`(`` `` chapter ``=`` ``1``,`` `` problem_numbers ``=`` ``1``:``2``,`` `` author ``=`` ``"Alice Smith"`` ``)`` `` ``# 3. Write the .qmd files into reports/`` ``qmd_files`` ``<-`` `[`generate_reports`](https://thomasqmd.github.io/mariner/reference/generate_reports.md)`(``report_params``)`` `` ``# 4. Render and bundle into zip_files/`` ``zip_files`` ``<-`` `[`process_files`](https://thomasqmd.github.io/mariner/reference/process_files.md)`(``qmd_files``)`

Every column that varies has to appear in the file name template, which
defaults to `"Report-{chapter}_{problem_numbers}"`. Otherwise two rows
resolve to one name and the second overwrites the first.

## Theming

[`theme_mariner()`](https://thomasqmd.github.io/mariner/reference/theme_mariner.md)
and the `scale_*_mariner_*()` families draw a figure in the same colours
as the page:

[`library`](https://rdrr.io/r/base/library.html)`(`[`ggplot2`](https://ggplot2.tidyverse.org)`)`` `` `[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mpg``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``class``, ``hwy``, color ``=`` ``class``)``)`` ``+`` `` `[`geom_jitter`](https://ggplot2.tidyverse.org/reference/geom_jitter.html)`(``width ``=`` ``0.2``, height ``=`` ``0``, size ``=`` ``2``)`` ``+`` `` `[`scale_colour_mariner_d`](https://thomasqmd.github.io/mariner/reference/scale_mariner_d.md)`(``)`` ``+`` `` `[`labs`](https://ggplot2.tidyverse.org/reference/labs.html)`(`` `` title ``=`` ``"Fuel Economy by Vehicle Class"``,`` `` x ``=`` ``"Vehicle Class"``,`` `` y ``=`` ``"Highway MPG"`` `` ``)`` ``+`` `` `[`theme_mariner`](https://thomasqmd.github.io/mariner/reference/theme_mariner.md)`(``)`` ``+`` `` `[`theme`](https://ggplot2.tidyverse.org/reference/theme.html)`(``legend.position ``=`` ``"none"``)`

## If It Does Not Work

[`mariner_check_setup()`](https://thomasqmd.github.io/mariner/reference/mariner_check_setup.md)
reports on Quarto, LaTeX, the fonts, the folders and the theme, and
prints the fix for anything missing:

[`mariner_check_setup`](https://thomasqmd.github.io/mariner/reference/mariner_check_setup.md)`(``)`

If the fonts are missing:

[`mariner_install_fonts`](https://thomasqmd.github.io/mariner/reference/mariner_install_fonts.md)`(``)`
