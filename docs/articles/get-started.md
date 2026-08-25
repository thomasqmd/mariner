# Get Started with mariner

`mariner` simplifies parameterized Quarto report generation and
bundling.

## 1. System Preflight Check

Check that your machine has the required tools (Quarto, LaTeX, and theme
fonts):

[`library`](https://rdrr.io/r/base/library.html)`(`[`mariner`](https://thomasqmd.github.io/mariner/)`)`` `[`mariner_check_setup`](https://thomasqmd.github.io/mariner/reference/mariner_check_setup.md)`(``)`

Output:

    ── mariner setup ─────────────────────────────────────────────────────────────
    ✔ Quarto: version 1.4.550
    ✔ LaTeX: xelatex available
    ✔ Figure fonts: bundled and available
    ✔ Zip archives: created and read back
    ✔ Project folders: present
    ✔ Theme in reports/: present and complete
    ✔ Figure theme: theme_mariner() builds
    ✔ Template packages: all 1 installed
    ✔ Setup check complete: ready to render reports.

If fonts are missing for PDF device figures, install them with:

[`mariner_install_fonts`](https://thomasqmd.github.io/mariner/reference/mariner_install_fonts.md)`(``)`

## 2. Project Scaffolding

Initialize the folder structure and install the Baylor Quarto theme:

[`mariner_setup_project`](https://thomasqmd.github.io/mariner/reference/mariner_setup_project.md)`(``)`

This creates:

- `assets/`: Theme files source cache.
- `reports/`: Document directory containing `_extensions/` and starter
  `report.qmd`.
- `zip_files/`: Output folder for student bundles.

## 3. Define Parameters

Create a data frame where each row specifies parameters for one report:

[`library`](https://rdrr.io/r/base/library.html)`(`[`tidyr`](https://tidyr.tidyverse.org)`)`` `` ``report_params`` ``<-`` `[`expand_grid`](https://tidyr.tidyverse.org/reference/expand_grid.html)`(`` `` chapter ``=`` ``1``,`` `` problem_numbers ``=`` ``1``:``2``,`` `` author ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"Alice Smith"``, ``"Bob Jones"``)`` ``)`` ``report_params`

## 4. Generate Report Sources

Generate `.qmd` files from the built-in template:

`qmd_files`` ``<-`` `[`generate_reports`](https://thomasqmd.github.io/mariner/reference/generate_reports.md)`(`` `` params_df ``=`` ``report_params``,`` `` template_name ``=`` ``"report"`` ``)`` ``qmd_files`

Output:

    [1] "reports/Report-1_1.qmd" "reports/Report-1_2.qmd"
    [3] "reports/Report-1_1.qmd" "reports/Report-1_2.qmd"

## 5. Render and Bundle Reports

Render each document to PDF and bundle source files, purled R scripts,
and PDFs into zip archives:

`# Sequential execution:`` ``zip_paths`` ``<-`` `[`process_files`](https://thomasqmd.github.io/mariner/reference/process_files.md)`(``qmd_files``)`` `` ``# Parallel execution across background workers:`` `[`library`](https://rdrr.io/r/base/library.html)`(`[`future`](https://future.futureverse.org)`)`` `[`plan`](https://future.futureverse.org/reference/plan.html)`(``multisession``, workers ``=`` ``2``)`` ``zip_paths`` ``<-`` `[`process_files`](https://thomasqmd.github.io/mariner/reference/process_files.md)`(``qmd_files``)`

Each archive in `zip_files/` contains: \* The `.qmd` source document. \*
The extracted `.R` code script. \* The rendered `.pdf` output.
