# mariner

[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/thomasqmd/mariner/actions/workflows/r.yml/badge.svg)](https://github.com/thomasqmd/mariner/actions/workflows/r.yml)
[![codecov](https://codecov.io/github/thomasqmd/mariner/graph/badge.svg?token=A4PDZWC3IL)](https://codecov.io/github/thomasqmd/mariner)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**mariner** turns one parameterized Quarto template into a set of reports, renders them, and bundles each one into a zip archive. It carries its own Quarto PDF theme: typography, brand colours, and matching **ggplot2** scales.

Documentation: [https://thomasqmd.github.io/mariner/](https://thomasqmd.github.io/mariner/).

## Installation

**mariner** installs from GitHub, so R builds it from source.

**Windows needs [Rtools](https://cran.r-project.org/bin/windows/Rtools/) first.**
Match the version to your R — check `R.version.string`, so R 4.5.x takes Rtools45 —
then restart RStudio. Without it the install stops at
`Could not find tools necessary to compile a package`. macOS and Linux need
nothing extra.

```r
# install.packages("pak")
pak::pak("thomasqmd/mariner", dependencies = TRUE)
```

`dependencies = TRUE` brings the `Suggests` along — **tidyverse**, **patchwork**,
**tinytex** and the rest — which is what a course usually wants. Leave it off to
install only what mariner itself needs.

## Folder Structure

mariner works in three project directories:

```
your-project/
├── assets/          # the Quarto theme, assembled once
├── reports/         # the .qmd sources, their PDFs, and _extensions/
└── zip_files/       # one archive per report: PDF, source, R script
```

## Quickstart

```r
library(mariner)

# 1. Create the folders and install the Quarto theme
mariner_setup_project()

# 2. One row per report
report_params <- expand.grid(
  chapter = 1,
  problem_numbers = 1:2,
  author = "Alice Smith",
  stringsAsFactors = FALSE
)

# 3. Write the .qmd files into reports/
qmd_files <- generate_reports(report_params)

# 4. Render and bundle into zip_files/
zip_files <- process_files(qmd_files)
```

Every column that varies has to appear in the file name template, which defaults to `"Report-{chapter}_{problem_numbers}"`. Otherwise two rows resolve to one name and the second overwrites the first.

## Theming

`theme_mariner()` and the `scale_*_mariner_*()` families draw a figure in the same colours as the page:

```r
library(ggplot2)

ggplot(mpg, aes(class, hwy, color = class)) +
  geom_jitter(width = 0.2, height = 0, size = 2) +
  scale_colour_mariner_d() +
  labs(
    title = "Fuel Economy by Vehicle Class",
    x = "Vehicle Class",
    y = "Highway MPG"
  ) +
  theme_mariner() +
  theme(legend.position = "none")
```

## If It Does Not Work

`mariner_check_setup()` reports on Quarto, LaTeX, the fonts, the folders and the theme, and prints the fix for anything missing:

```r
mariner_check_setup()
```

If the fonts are missing:

```r
mariner_install_fonts()
```
