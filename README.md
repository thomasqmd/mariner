# mariner

[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/thomasqmd/mariner/actions/workflows/r.yml/badge.svg)](https://github.com/thomasqmd/mariner/actions/workflows/r.yml)
[![codecov](https://codecov.io/github/thomasqmd/mariner/graph/badge.svg?token=A4PDZWC3IL)](https://codecov.io/github/thomasqmd/mariner)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

The **mariner** package simplifies and automates the process of creating and zipping reports for Dr. Seaman's Class. It provides a cohesive workflow to first generate multiple Quarto or R Markdown source files from a single parameterized template, and then zips the source files and all rendered outputs into easily shareable zip archives. See the reference website [here](https://thomasqmd.github.io/mariner/).

## Installation

You can install the current version of mariner from [GitHub](https://github.com/thomasqmd/mariner) with:

```r
# install.packages("pak")
pak::pak("thomasqmd/mariner")

```

## Workflow

The typical workflow involves two main steps: using `generate_reports()` to create parameterized `.qmd` or `.Rmd` files, and then using `process_files()` to render and bundle them.

### Generate Reports

Use `generate_reports` to create multiple report files base on a template.

```r
library(mariner)
library(tidyr)

# --- 1. Setup: Create a temporary directory for the output ---
temp_dir <- tempfile("mariner-example-")
dir.create(temp_dir)

# --- 2. Define the parameters for each report ---
# Each row in the data frame corresponds to one report.
report_params <- expand_grid(
  chapter = 1, 
  problem_numbers = 1:2, 
  author = "Firstname Lastname"
)

# --- 3. Generate the .qmd source files ---
qmd_files <- generate_reports(
  params_df = report_params,
  template_name = "simple_report",
  output_dir = temp_dir
)
#> Generating 2 qmd files...
#> Rmd file generation complete.
```

### Proccess Reports

Then you will have two `.qmd` files in your temporary directory, named `Report-1_1.qmd` and `Report-1_2.qmd`, each containing the parameters specified. After editing the reports as needed, you can proceed to render and zip them with `process_file` or `process_files` as shown below.

```r
# --- 4. Render the reports and bundle them into zip archives ---
# This can be run in parallel by setting a future plan.
process_files(qmd_files)
#> Starting bundling process...
#> Progress: ────────────────────────────────── 100%
#> Successfully created bundle: Report-1_1.zip
#> Successfully created bundle: Report-1_2.zip
#> Bundling complete. Success: 2, Failures: 0.

# --- 5. View the final output ---
# The directory now contains the source Rmd files and their zip archives.
list.files(temp_dir)
#> [1] "Report-1_1.Rmd" "Report-1_1.zip" "Report-1_2.Rmd" "Report-1_2.zip"

# --- Cleanup ---
unlink(temp_dir, recursive = TRUE)
```
