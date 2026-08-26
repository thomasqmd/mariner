# Get Started with mariner

**mariner** writes one Quarto report per row of a parameter table,
renders each one, and bundles it into a zip archive.

## 0. Installation

**mariner** installs from GitHub, so R builds it from source.

**Windows needs [Rtools](https://cran.r-project.org/bin/windows/Rtools/)
first.** Match the version to your R — check `R.version.string`, so R
4.5.x takes Rtools45 — then restart RStudio. Without it the install
stops at `Could not find tools necessary to compile a package`. macOS
and Linux need nothing extra.

`# install.packages("pak")`` ``pak``::`[`pak`](https://pak.r-lib.org/reference/pak.html)`(``"thomasqmd/mariner"``, dependencies ``=`` ``TRUE``)`

`dependencies = TRUE` brings the `Suggests` along.

## 1. System Preflight Check

Check the machine first: Quarto, LaTeX, the fonts.

[`library`](https://rdrr.io/r/base/library.html)`(`[`mariner`](https://thomasqmd.github.io/mariner/)`)`` `[`mariner_check_setup`](https://thomasqmd.github.io/mariner/reference/mariner_check_setup.md)`(``)`

Output:

    ── mariner setup ───────────────────────────────────────────────────────────────
    ℹ Project: /Users/you/classes/stat3010
    ✔ Quarto: version 1.10.18
    ✔ LaTeX: TinyTeX
    ✔ Figure fonts: all three families installed
    ✔ Zip archives: created and read back
    ✔ Project folders: assets/, reports/, zip_files/
    ✔ Theme in reports/: _extensions/mariner
    ✔ Figure theme: theme_mariner() builds
    ✔ Template packages: all 1 installed
    ✔ Everything checks out.

A `warn` on the fonts means the figures in a PDF will come out in the
device’s default typeface while the page text does not. Fix it with:

[`mariner_install_fonts`](https://thomasqmd.github.io/mariner/reference/mariner_install_fonts.md)`(``)`

## 2. Project Scaffolding

Create the folders, install the Quarto theme, and set your name:

[`mariner_setup_project`](https://thomasqmd.github.io/mariner/reference/mariner_setup_project.md)`(``author ``=`` ``"Alice Smith"``)`

You get three directories:

- `assets/`: the theme, assembled once.
- `reports/`: the documents, a copy of `_extensions/`, and a starter
  `report.qmd`.
- `zip_files/`: the bundles you hand out.

and a `_mariner.yml`, which holds the settings that apply to the whole
project:

``` yaml
# mariner project settings. Edit by hand or with mariner_setup_project().
#
# Values here fill any parameter of the same name that a template
# declares. A column in generate_reports()'s params_df beats them.
author: Alice Smith
```

Run setup without an `author` and it says so. The alternative is a batch
of PDFs that carry the template’s placeholder name, from a render that
succeeded. To change the name later, make the same call again — this
touches nothing else:

[`mariner_setup_project`](https://thomasqmd.github.io/mariner/reference/mariner_setup_project.md)`(``author ``=`` ``"A. Smith"``, template ``=`` ``NULL``)`

## 3. Define Parameters

One row per report. Only what differs between them belongs here:

[`library`](https://rdrr.io/r/base/library.html)`(`[`tidyr`](https://tidyr.tidyverse.org)`)`` `` ``report_params`` ``<-`` `[`expand_grid`](https://tidyr.tidyverse.org/reference/expand_grid.html)`(`` `` chapter ``=`` ``1``,`` `` problem_numbers ``=`` ``1``:``2`` ``)`` ``report_params`

There is no `author` column. One person runs the batch, and it is their
name on every report, so it belongs in `_mariner.yml` and not in a data
frame column that repeats one value. `_mariner.yml` fills any template
parameter of the same name; a `params_df` column beats it, for the case
where the author does vary.

## 4. Generate Report Sources

Write the `.qmd` files from the built-in template:

`qmd_files`` ``<-`` `[`generate_reports`](https://thomasqmd.github.io/mariner/reference/generate_reports.md)`(`` `` params_df ``=`` ``report_params``,`` `` template_name ``=`` ``"report"`` ``)`` ``qmd_files`

Output:

    [1] "/Users/you/classes/stat3010/reports/Report-1_1.qmd"
    [2] "/Users/you/classes/stat3010/reports/Report-1_2.qmd"

The names come from `file_name`, a [glue](https://glue.tidyverse.org)
template over the columns of `params_df`. It defaults to
`"Report-{chapter}_{problem_numbers}"`. **Every column that varies has
to appear in it.** Otherwise two rows resolve to one name and the second
overwrites the first.

## 5. Render and Bundle Reports

Render each document and bundle it:

`# Sequential:`` ``zip_paths`` ``<-`` `[`process_files`](https://thomasqmd.github.io/mariner/reference/process_files.md)`(``qmd_files``)`` `` ``# Parallel, across background workers:`` `[`library`](https://rdrr.io/r/base/library.html)`(`[`future`](https://future.futureverse.org)`)`` `[`plan`](https://future.futureverse.org/reference/plan.html)`(``multisession``, workers ``=`` ``2``)`` ``zip_paths`` ``<-`` `[`process_files`](https://thomasqmd.github.io/mariner/reference/process_files.md)`(``qmd_files``)`

Each archive in `zip_files/` holds:

- the `.qmd` source,
- the purled `.R` script,
- the rendered `.pdf`,
- whatever else the render left behind, such as the `.tex` the starter
  template keeps.

The `include` argument selects among those four. See
[`?process_file`](https://thomasqmd.github.io/mariner/reference/process_file.md).

A file that fails to render does not stop the batch. It comes back as
`NA` and its error message is named in the summary.
