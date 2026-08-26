# Get Started with mariner

**mariner** writes one Quarto report per row of a parameter table,
renders each one, and bundles it into a zip archive.

## 1. System Preflight Check

Check the machine first: Quarto, LaTeX, the fonts.

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

A `warn` on the fonts means the figures in a PDF will come out in the
device’s default typeface while the page text does not. Fix it with:

[`mariner_install_fonts`](https://thomasqmd.github.io/mariner/reference/mariner_install_fonts.md)`(``)`

## 2. Project Scaffolding

Create the folders and install the Quarto theme:

[`mariner_setup_project`](https://thomasqmd.github.io/mariner/reference/mariner_setup_project.md)`(``)`

You get three directories:

- `assets/`: the theme, assembled once.
- `reports/`: the documents, a copy of `_extensions/`, and a starter
  `report.qmd`.
- `zip_files/`: the bundles you hand out.

## 3. Define Parameters

One row per report:

[`library`](https://rdrr.io/r/base/library.html)`(`[`tidyr`](https://tidyr.tidyverse.org)`)`` `` ``report_params`` ``<-`` `[`expand_grid`](https://tidyr.tidyverse.org/reference/expand_grid.html)`(`` `` chapter ``=`` ``1``,`` `` problem_numbers ``=`` ``1``:``2``,`` `` author ``=`` ``"Alice Smith"`` ``)`` ``report_params`

`author` is constant. One person runs the batch, and it is their name on
every report. It is a parameter rather than a hard-coded string so the
template can print it.

## 4. Generate Report Sources

Write the `.qmd` files from the built-in template:

`qmd_files`` ``<-`` `[`generate_reports`](https://thomasqmd.github.io/mariner/reference/generate_reports.md)`(`` `` params_df ``=`` ``report_params``,`` `` template_name ``=`` ``"report"`` ``)`` ``qmd_files`

Output:

    [1] "reports/Report-1_1.qmd" "reports/Report-1_2.qmd"

The names come from `file_name`, a [glue](https://glue.tidyverse.org)
template over the columns of `params_df`. It defaults to
`"Report-{chapter}_{problem_numbers}"`. **Every column that varies has
to appear in it.** Otherwise two rows resolve to one name and the second
overwrites the first. That is why the grid above holds `author`
constant: it does not tell one report from another.

## 5. Render and Bundle Reports

Render each document and bundle it:

`# Sequential:`` ``zip_paths`` ``<-`` `[`process_files`](https://thomasqmd.github.io/mariner/reference/process_files.md)`(``qmd_files``)`` `` ``# Parallel, across background workers:`` `[`library`](https://rdrr.io/r/base/library.html)`(`[`future`](https://future.futureverse.org)`)`` `[`plan`](https://future.futureverse.org/reference/plan.html)`(``multisession``, workers ``=`` ``2``)`` ``zip_paths`` ``<-`` `[`process_files`](https://thomasqmd.github.io/mariner/reference/process_files.md)`(``qmd_files``)`

Each archive in `zip_files/` holds:

- the `.qmd` source,
- the purled `.R` script,
- the rendered `.pdf`.

A file that fails to render does not stop the batch. It comes back as
`NA` and its error message is named in the summary.
