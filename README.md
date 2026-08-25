# mariner

[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/thomasqmd/mariner/actions/workflows/r.yml/badge.svg)](https://github.com/thomasqmd/mariner/actions/workflows/r.yml)
[![codecov](https://codecov.io/github/thomasqmd/mariner/graph/badge.svg?token=A4PDZWC3IL)](https://codecov.io/github/thomasqmd/mariner)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

The **mariner** package automates the generation, rendering, and bundling of parameterized Quarto reports. It includes a built-in Baylor Quarto PDF theme with typography, colors, and `ggplot2` scales.

Visit the documentation site at [https://thomasqmd.github.io/mariner/](https://thomasqmd.github.io/mariner/).

## Installation

Install the development version from GitHub:

```r
# install.packages("pak")
pak::pak("thomasqmd/mariner")
```

## Folder Structure

`mariner` organizes files into three project directories:

```
your-project/
├── assets/          # Theme cache and font assets
├── reports/         # Quarto source files (.qmd) and staged _extensions/
└── zip_files/       # Output zip archives containing PDF, source, and R script
```

## Quickstart

```r
library(mariner)
library(tidyr)

# 1. Initialize project folders and Quarto theme
mariner_setup_project()

# 2. Define report parameters
report_params <- expand_grid(
  chapter = 1,
  problem_numbers = 1:2,
  author = c("Alice Smith", "Bob Jones")
)

# 3. Generate .qmd files in reports/
qmd_files <- generate_reports(report_params)

# 4. Render and bundle into zip_files/
zip_files <- process_files(qmd_files)
```

## Theming and Visualization

`mariner` exports `theme_mariner()` and custom scale functions:

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

## System Verification and Troubleshooting

To verify your system environment (Quarto CLI, LaTeX, and theme fonts):

```r
mariner_check_setup()
```

If fonts are missing on your operating system:

```r
mariner_install_fonts()
```
