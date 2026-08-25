# mariner

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/thomasqmd/mariner/actions/workflows/r.yml/badge.svg)](https://github.com/thomasqmd/mariner/actions/workflows/r.yml)
[![codecov](https://codecov.io/github/thomasqmd/mariner/graph/badge.svg?token=A4PDZWC3IL)](https://codecov.io/github/thomasqmd/mariner)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

The **mariner** package automates the generation, rendering, and
bundling of parameterized Quarto reports. It includes a built-in Baylor
Quarto PDF theme with typography, colors, and `ggplot2` scales.

Visit the documentation site at <https://thomasqmd.github.io/mariner/>.

## Installation

Install the development version from GitHub:

`# install.packages("pak")`` ``pak``::`[`pak`](https://pak.r-lib.org/reference/pak.html)`(``"thomasqmd/mariner"``)`

## Folder Structure

`mariner` organizes files into three project directories:

    your-project/
    ├── assets/          # Theme cache and font assets
    ├── reports/         # Quarto source files (.qmd) and staged _extensions/
    └── zip_files/       # Output zip archives containing PDF, source, and R script

## Quickstart

[`library`](https://rdrr.io/r/base/library.html)`(`[`mariner`](https://thomasqmd.github.io/mariner/)`)`` `[`library`](https://rdrr.io/r/base/library.html)`(`[`tidyr`](https://tidyr.tidyverse.org)`)`` `` ``# 1. Initialize project folders and Quarto theme`` `[`mariner_setup_project`](https://thomasqmd.github.io/mariner/reference/mariner_setup_project.md)`(``)`` `` ``# 2. Define report parameters`` ``report_params`` ``<-`` `[`expand_grid`](https://tidyr.tidyverse.org/reference/expand_grid.html)`(`` `` chapter ``=`` ``1``,`` `` problem_numbers ``=`` ``1``:``2``,`` `` author ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"Alice Smith"``, ``"Bob Jones"``)`` ``)`` `` ``# 3. Generate .qmd files in reports/`` ``qmd_files`` ``<-`` `[`generate_reports`](https://thomasqmd.github.io/mariner/reference/generate_reports.md)`(``report_params``)`` `` ``# 4. Render and bundle into zip_files/`` ``zip_files`` ``<-`` `[`process_files`](https://thomasqmd.github.io/mariner/reference/process_files.md)`(``qmd_files``)`

## Theming and Visualization

`mariner` exports
[`theme_mariner()`](https://thomasqmd.github.io/mariner/reference/theme_mariner.md)
and custom scale functions:

[`library`](https://rdrr.io/r/base/library.html)`(`[`ggplot2`](https://ggplot2.tidyverse.org)`)`` `` `[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mpg``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``class``, ``hwy``, color ``=`` ``class``)``)`` ``+`` `` `[`geom_jitter`](https://ggplot2.tidyverse.org/reference/geom_jitter.html)`(``width ``=`` ``0.2``, height ``=`` ``0``, size ``=`` ``2``)`` ``+`` `` `[`scale_colour_mariner_d`](https://thomasqmd.github.io/mariner/reference/scale_mariner_d.md)`(``)`` ``+`` `` `[`labs`](https://ggplot2.tidyverse.org/reference/labs.html)`(`` `` title ``=`` ``"Fuel Economy by Vehicle Class"``,`` `` x ``=`` ``"Vehicle Class"``,`` `` y ``=`` ``"Highway MPG"`` `` ``)`` ``+`` `` `[`theme_mariner`](https://thomasqmd.github.io/mariner/reference/theme_mariner.md)`(``)`` ``+`` `` `[`theme`](https://ggplot2.tidyverse.org/reference/theme.html)`(``legend.position ``=`` ``"none"``)`

## System Verification and Troubleshooting

To verify your system environment (Quarto CLI, LaTeX, and theme fonts):

[`mariner_check_setup`](https://thomasqmd.github.io/mariner/reference/mariner_check_setup.md)`(``)`

If fonts are missing on your operating system:

[`mariner_install_fonts`](https://thomasqmd.github.io/mariner/reference/mariner_install_fonts.md)`(``)`
