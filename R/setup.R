# Project scaffolding: where the folders are, and who creates them.
#
# Every default path in the package resolves through mariner_dirs(). No other
# function composes "reports" or "zip_files" into a string itself -- a folder
# rename is this file plus a rebuild, not a search across four functions that
# can each be missed.

# The three folders, and the names mariner_dirs() returns them under.
#
# The list ELEMENT names and the DIRECTORY names deliberately differ in one
# place: `zips` on disk is `zip_files/`. The element name is what appears in
# every default argument (`mariner_dirs()$zips`), and the directory name is what
# a student sees in the RStudio files pane, where `zip_files` reads as a folder
# of zip files and `zips` reads as a typo.
MARINER_DIR_NAMES <- c(
  assets  = "assets",
  reports = "reports",
  zips    = "zip_files"
)

# What makes a directory a project root.
#
# Two lists, and the asymmetry is deliberate.
#
# ROOT_MARKERS drives the ancestor walk. `.git` is left out of it because it is
# the marker most likely to sit far above where the work actually is: someone
# whose home directory is under version control -- dotfiles repos are not rare
# -- would get mariner_project_root() returning `~`, and every default path in
# the package would point at their home directory.
#
# The walk itself is narrow, and deliberately so: see accepts_root(). It climbs
# only out of the three mariner folders, so a marker in a parent directory does
# not capture an unrelated directory beneath it.
#
# PROJECT_MARKERS drives the attach GUARD, which only ever asks about ONE
# directory: the working directory, right now. It never walks. A `.git` in the
# directory a person deliberately started R in is proof enough that they are
# working in a project, so the guard accepts it where the walk does not.
ROOT_MARKERS    <- c(".Rproj", "_quarto.yml", "DESCRIPTION")
PROJECT_MARKERS <- c(ROOT_MARKERS, ".git")

# Does `path` itself carry any of `markers`?
#
# `.Rproj` is matched as an EXTENSION -- the file is named after the project, so
# there is no fixed filename to test for. The others are exact names.
has_markers <- function(path, markers) {
  for (m in markers) {
    if (identical(m, ".Rproj")) {
      if (length(list.files(path, pattern = "\\.Rproj$"))) return(TRUE)
    } else if (file.exists(file.path(path, m))) {
      return(TRUE)
    }
  }
  FALSE
}

# A directory holding all three mariner folders IS a mariner project.
#
# Without this, mariner_setup_project() scaffolds a project that
# mariner_project_root() cannot afterwards find. The two resolve the root
# differently -- the scaffolder from the working directory, process_file() by
# walking up from the INPUT FILE -- so in a directory carrying none of the
# ROOT_MARKERS they disagreed: setup made `<project>/zip_files/`, and a render of
# `reports/ch1.qmd` walked up from `reports/`, found no marker, fell back to
# `reports/` itself, and wrote `reports/zip_files/`. Two bundle directories, and
# the one the student was told about was the empty one.
#
# Requiring all THREE is what keeps this from firing by accident. A lone
# `reports/` or `assets/` is an ordinary directory name; the full set is what
# this package creates and nothing else does.
has_mariner_layout <- function(path) {
  all(dir.exists(file.path(path, MARINER_DIR_NAMES)))
}

# Is `current` the root, having arrived from `from`? `from` is NULL when
# `current` is where the search started.
#
# A marker is necessary and NOT sufficient. The walk climbs only out of the
# three mariner folders, so a marker one level up claims a directory beneath it
# only when that directory is `assets/`, `reports/` or `zip_files/`.
#
# WHY THE WALK IS THIS NARROW. It exists for one caller: process_file()
# resolves the root from the INPUT FILE's directory, so bundling
# `reports/ch1.qmd` has to reach the project holding `reports/`. That case is
# unambiguous -- a file in a project's reports/ belongs to that project by
# construction. Nothing else is.
#
# An unrestricted walk got this wrong twice in one afternoon, once for each
# kind of marker. The mariner layout is created FOR you -- library(mariner)
# makes it on attach -- so `folder/` left over from an abandoned run swallowed
# the `folder/new folder/` started in its place. And an `.Rproj` two levels up
# meant a working directory that is plainly not the project was scaffolded as
# though it were. In both cases the answer a person expects is the directory
# they are standing in.
accepts_root <- function(current, from) {
  if (!has_markers(current, ROOT_MARKERS) && !has_mariner_layout(current)) {
    return(FALSE)
  }
  is.null(from) || basename(from) %in% MARINER_DIR_NAMES
}

#' Does this directory look like a project root?
#'
#' The guard `.onAttach()` uses before it creates anything. A directory counts
#' as a project root if it holds an `.Rproj` file, a `_quarto.yml`, a
#' `DESCRIPTION`, a `.git` directory, or all three mariner folders.
#'
#' The last of those is what makes a directory [mariner_setup_project()]
#' scaffolded count as a project afterwards, without it also having to be an
#' RStudio or Quarto one.
#'
#' It is exported so the attach behaviour can be checked: if `library(mariner)`
#' did not create the folders you expected, this says why.
#'
#' @param path Directory to test. Defaults to the working directory.
#' @return `TRUE` or `FALSE`.
#' @seealso [mariner_project_root()], [mariner_dirs()]
#' @export
#' @examples
#' # The directory R is currently running in:
#' mariner_looks_like_project(getwd())
#'
#' # An empty temporary directory is not a project:
#' mariner_looks_like_project(tempdir())
mariner_looks_like_project <- function(path = ".") {
  # The layout counts here for the same reason it counts in
  # mariner_project_root(): a directory this package scaffolded is a mariner
  # project, whatever else it is or is not. Without it, setup left behind a
  # directory that was a root and did not look like a project -- and the guard
  # would decline to restore a folder a student had deleted out of it.
  #
  # Unlike the walk, there is no ancestor to get wrong: this only ever asks
  # about ONE directory.
  dir.exists(path) &&
    (has_markers(path, PROJECT_MARKERS) || has_mariner_layout(path))
}

#' Locate the project root
#'
#' Resolves the directory that `assets/`, `reports/` and `zip_files/` sit
#' beneath, in this order:
#'
#' 1. `getOption("mariner.project_root")`, if set. The escape hatch for a
#'    session whose working directory is not where the reports belong.
#' 2. `path` itself, if it holds an `.Rproj` file, a `_quarto.yml`, a
#'    `DESCRIPTION`, or all three mariner folders. A project
#'    [mariner_setup_project()] scaffolded is therefore found again without
#'    also being an RStudio or Quarto project.
#' 3. An ancestor carrying one of those, reached by climbing out of `assets/`,
#'    `reports/` or `zip_files/` -- so bundling `reports/ch1.qmd` resolves to
#'    the project that holds `reports/`.
#' 4. `path` itself, normalised.
#'
#' The walk in step 3 goes through mariner folders and nothing else. A marker
#' in a parent directory does not claim an unrelated subdirectory: run this
#' from `project/scratch` and you get `project/scratch`, whatever `project`
#' carries.
#'
#' `.git` is not a marker here, though it is one for
#' [mariner_looks_like_project()]. See the comment in `R/setup.R` for why.
#'
#' A `root` argument to [mariner_dirs()] or [mariner_setup_project()] beats all
#' of them. Those functions call this one only when `root` is `NULL`.
#'
#' @param path Directory to search upward from. Defaults to the working
#'   directory.
#' @return A normalised absolute path.
#' @seealso [mariner_dirs()], [mariner_looks_like_project()]
#' @export
#' @examples
#' mariner_project_root()
#'
#' # The option wins over the search:
#' withr::with_options(
#'   list(mariner.project_root = tempdir()),
#'   mariner_project_root()
#' )
mariner_project_root <- function(path = ".") {
  opt <- getOption("mariner.project_root")
  if (!is.null(opt) && nzchar(opt)) {
    return(normalizePath(opt, winslash = "/", mustWork = FALSE))
  }

  current <- normalizePath(path, winslash = "/", mustWork = FALSE)
  # The directory we climbed out of to reach `current`. NULL on the first pass,
  # which is how accepts_root() tells "where the search started" from "some
  # ancestor".
  from <- NULL

  # Walk up until a marker turns up or the path stops changing. dirname("/") is
  # "/" and dirname("C:/") is "C:/", so the fixed point is the loop's only
  # terminator -- there is no depth limit to get wrong.
  repeat {
    if (accepts_root(current, from)) return(current)
    from <- current
    parent <- dirname(current)
    if (identical(parent, current)) break
    current <- parent
  }

  normalizePath(path, winslash = "/", mustWork = FALSE)
}

#' The mariner project folders
#'
#' The single source for every default path in the package. Returns the three
#' directories mariner works in, as a named list:
#'
#' \describe{
#'   \item{`assets`}{`assets/` -- the Quarto extension, assembled once by
#'     [mariner_setup_project()]. Every render stages the theme from here, so a
#'     batch of fifty reports unpacks it once.}
#'   \item{`reports`}{`reports/` -- the `.qmd` sources, their PDFs, and a copy of
#'     `_extensions/`. The extension has to sit *beside* the documents:
#'     xelatex resolves the font paths in `brand-preamble.tex` against the
#'     directory that holds the `.tex`. An extension one level up gives a
#'     document that finds its format and then dies with "the font
#'     Lora-Regular cannot be found".}
#'   \item{`zips`}{`zip_files/` -- the bundles you hand out.}
#' }
#'
#' The paths come back whether or not the directories exist.
#' [mariner_setup_project()] and `.onAttach()` create them.
#'
#' @param root Project root. `NULL` (the default) resolves it with
#'   [mariner_project_root()].
#' @return A named list of three absolute paths: `assets`, `reports`, `zips`.
#' @seealso [mariner_setup_project()], [mariner_project_root()]
#' @export
#' @examples
#' mariner_dirs(root = tempdir())
#'
#' # Every default path in the package is composed from this:
#' mariner_dirs(root = tempdir())$reports
mariner_dirs <- function(root = NULL) {
  if (is.null(root)) root <- mariner_project_root()
  root <- normalizePath(root, winslash = "/", mustWork = FALSE)
  out <- as.list(file.path(root, MARINER_DIR_NAMES))
  names(out) <- names(MARINER_DIR_NAMES)
  out
}

#' Set up a mariner project
#'
#' Creates the folders a mariner workflow uses, installs the Quarto theme into
#' them, drops in a starter report, and records the project's author. Run it
#' twice and nothing changes: a file that exists is left alone unless
#' `overwrite = TRUE`.
#'
#' Beneath `root`:
#'
#' ```
#' _mariner.yml                    project settings, when author is given
#' assets/
#'   _extensions/mariner/          the theme, assembled once
#' reports/
#'   _extensions/mariner/          a copy, beside the documents that use it
#'   report.qmd                    a starter document
#' zip_files/                      the bundles you hand out
#' ```
#'
#' `zip_files/`, `assets/_extensions/` and `reports/_extensions/` go into the
#' project `.gitignore`. All three are build outputs, and a committed copy goes
#' stale against what it was built from. `_mariner.yml` is not ignored — it is
#' a setting, and it belongs with the project.
#'
#' @section The author:
#' `author` is a project setting, not a column of [generate_reports()]'s
#' `params_df`. One person runs a batch, and it is their name on every report
#' in it. As a column it had to be retyped on every call, and a call that
#' omitted it produced a batch of PDFs that carried the template's placeholder
#' on every title page. The render succeeded, so nothing said so.
#'
#' The name goes to `_mariner.yml`, and [generate_reports()] fills any template
#' parameter that matches it. A `params_df` column still wins, for the batch
#' whose author does vary.
#'
#' @param root Project root. `NULL` (the default) resolves it with
#'   [mariner_project_root()], which is the working directory unless that is
#'   one of the mariner folders. Pass a path to override.
#' @param theme One of [mariner_themes].
#' @param template Starter template to copy into `reports/`. `NULL` for no
#'   starter document.
#' @param author Name for the project's author, written to `_mariner.yml`. See
#'   the section below. `NULL` (the default) writes no file and leaves any
#'   existing setting alone. A name here is written whether or not `overwrite`
#'   is set: `overwrite` guards the files setup scaffolds and a student then
#'   edits, and `author` is itself the instruction to change this one.
#' @param overwrite Replace files that already exist. The folders themselves are
#'   never removed.
#' @return The named list from [mariner_dirs()], invisibly.
#' @seealso [mariner_dirs()], [mariner_install_fonts()]
#' @export
#' @examples
#' \dontrun{
#' # In an RStudio project or Quarto project directory:
#' mariner_setup_project(author = "Alice Smith")
#'
#' # Or somewhere explicit:
#' mariner_setup_project(root = "~/classes/stat3010", author = "Alice Smith")
#'
#' # Change the author later. This touches nothing else:
#' mariner_setup_project(author = "A. Smith", template = NULL)
#' }
mariner_setup_project <- function(root = NULL,
                                  theme = mariner_themes,
                                  template = "report",
                                  author = NULL,
                                  overwrite = FALSE) {
  theme <- check_theme(theme)
  dirs <- mariner_dirs(root)
  # Resolved once, from mariner_dirs() rather than beside it -- if the two ever
  # disagreed about where the root is, the .gitignore would land in one project
  # and the folders in another.
  root_dir <- dirname(dirs$reports)

  # Resolved before anything is written. A mistyped template name that aborted
  # at step 3 would leave three folders and a 1.3 MB extension behind, and the
  # student would have to know that re-running is safe in order to recover.
  starter_src <- if (is.null(template)) NULL else setup_template_path(template)

  # Validated here for the same reason the template is: before anything is
  # written, so a bad value cannot leave three folders and a 1.3 MB extension
  # behind. A length-2 vector is the likely slip -- c("A. Smith", "B. Jones")
  # from someone expecting a co-author list, which the front matter would take
  # as a YAML sequence and the template's `params$author` would print as one.
  if (!is.null(author)) {
    if (!is.character(author) || length(author) != 1L || is.na(author) ||
        !nzchar(trimws(author))) {
      cli::cli_abort("{.arg author} must be a single non-empty string.")
    }
    author <- trimws(author)
  }

  # Every step records what it did, so the closing summary reports what actually
  # happened rather than what was attempted. On a second run this is what makes
  # the difference between "created" and "already there" visible.
  made <- character()
  kept <- character()
  note <- function(created, what) {
    if (isTRUE(created)) made <<- c(made, what) else kept <<- c(kept, what)
  }

  cli::cli_h1("Setting up mariner project")
  cli::cli_alert_info("Root: {.file {root_dir}}")

  # --- 1. The three folders ---------------------------------------------------
  for (nm in names(dirs)) {
    existed <- dir.exists(dirs[[nm]])
    if (!existed) dir.create(dirs[[nm]], recursive = TRUE, showWarnings = FALSE)
    note(!existed, paste0(MARINER_DIR_NAMES[[nm]], "/"))
  }

  # --- 2. The theme -----------------------------------------------------------
  #
  # Assembled into assets/ and COPIED to reports/, rather than assembled twice.
  # assets/ is the source of truth: process_file() serves each render's scratch
  # directory from it, so the package's installed sources are walked once per
  # project instead of once per document.
  assets_ext  <- mariner_ext_dir(dirs$assets, theme)
  reports_ext <- mariner_ext_dir(dirs$reports, theme)

  if (dir.exists(assets_ext) && !overwrite) {
    note(FALSE, paste0("assets/", mariner_ext_rel(theme)))
  } else {
    mariner_build_extension(dirs$assets, theme = theme, quiet = TRUE)
    note(TRUE, paste0("assets/", mariner_ext_rel(theme)))
  }

  had_reports_ext <- dir.exists(reports_ext)
  copy_dir_safe(assets_ext, reports_ext, overwrite = overwrite)
  note(!had_reports_ext, paste0("reports/", mariner_ext_rel(theme)))

  # --- 3. A starter document --------------------------------------------------
  if (!is.null(starter_src)) {
    starter_dst <- file.path(dirs$reports, "report.qmd")
    note(
      copy_file_safe(starter_src, starter_dst, overwrite = overwrite),
      "reports/report.qmd"
    )
  }

  # --- 3b. Project settings ---------------------------------------------------
  #
  # Only written when a name was actually given. Running setup again for the
  # folders must not clear an author set on a previous run, and writing a file
  # holding nothing but a comment header would make `_mariner.yml` exist
  # without meaning anything -- which is worse than absent, because the next
  # reader has to open it to find that out.
  if (!is.null(author)) {
    write_project_config(root_dir, list(author = author))
    note(TRUE, MARINER_CONFIG_FILE)
  }

  # --- 4. .gitignore ----------------------------------------------------------
  ignored <- append_gitignore(root_dir, c(
    paste0(MARINER_DIR_NAMES[["zips"]], "/"),
    "assets/_extensions/",
    "reports/_extensions/"
  ))
  note(length(ignored) > 0, ".gitignore entries")

  # --- 5. Report --------------------------------------------------------------
  if (length(made)) cli::cli_alert_success("Created: {.file {made}}")
  if (length(kept)) {
    cli::cli_alert_info(
      "Already present, left alone: {.file {kept}}"
    )
  }

  # --- 5b. Say so when there is no author ---------------------------------------
  #
  # Not gated on interactive(), unlike the font notice below. A missing font
  # degrades a deliverable; a missing author makes it wrong -- every PDF in the
  # batch carries the template's placeholder on its title page, and the render
  # succeeds, so nothing else in the pipeline will ever mention it.
  if (is.null(read_project_config(root_dir)$author)) {
    cli::cli_alert_warning(
      "No author is set for this project. Reports will carry the template's \\
       placeholder name."
    )
    cli::cli_alert_info(
      'Set it with {.run mariner_setup_project(author = "Your Name")}.'
    )
  }

  # --- 6. Offer the fonts, never install them unasked --------------------------
  #
  # This is the one operation in the package that writes outside the project, so
  # it is the one operation that has to be asked for. Without it the body text
  # is Atkinson/Lora via fontspec -- which reads the bundled files by path --
  # while every FIGURE falls back to the device default, because cairo_pdf() and
  # base pdf() read fontconfig and ignore the systemfonts registry that bundling
  # populates. One document, two typefaces, and nothing saying so.
  if (interactive() && !mariner_fonts_available("pdf")) {
    cli::cli_alert_warning(c(
      "The bundled fonts are not installed system-wide. ",
      "Figures will render in the device's default typeface while the page ",
      "text renders in Lora."
    ))
    cli::cli_alert_info("Run {.run mariner_install_fonts()} to fix this.")
  }

  invisible(dirs)
}

# Path to a packaged template skeleton.
setup_template_path <- function(template, call = rlang::caller_env()) {
  mariner_template_path(template, package = "mariner", call = call)
}

# Append lines to a project .gitignore, skipping any already there.
#
# Created if absent, even when the project is not yet a git repository --
# `git init` in a directory that already has a .gitignore does the right thing,
# whereas a repository initialised later and missing these lines commits a
# 1.3 MB extension and every zip archive before anyone notices.
#
# Returns the lines it actually added.
append_gitignore <- function(root, lines) {
  path <- file.path(root, ".gitignore")

  existing <- if (file.exists(path)) readLines(path, warn = FALSE) else character()
  # Compare trimmed, so an entry a student wrote as `zip_files/ ` is recognised.
  wanted <- setdiff(lines, trimws(existing))
  if (!length(wanted)) return(character())

  # A trailing blank line is normal in a hand-written .gitignore; a missing
  # final newline is not, and appending to a file without one would glue the
  # first new entry onto the last existing entry.
  block <- c(
    if (length(existing) && nzchar(existing[[length(existing)]])) "",
    "# mariner build outputs",
    wanted
  )
  writeLines(c(existing, block), path)
  wanted
}

# --- Attach ------------------------------------------------------------------

# Create the folders if the working directory looks like a place they belong.
#
# Split out of .onAttach() so it is testable: .onAttach() adds the interactivity
# check, and testthat runs non-interactively, so a test calling .onAttach()
# directly would exercise nothing but the early return.
auto_setup_dirs <- function(wd = getwd()) {
  if (!isTRUE(getOption("mariner.auto_setup", TRUE))) return(character())
  if (!mariner_looks_like_project(wd)) return(character())

  dirs <- mariner_dirs(wd)
  absent <- dirs[!dir.exists(unlist(dirs, use.names = FALSE))]
  for (d in absent) dir.create(d, recursive = TRUE, showWarnings = FALSE)

  # unname(): the only consumer is the startup message, which prints the
  # DIRECTORY names. Carrying the list-element keys alongside them means the
  # empty case is a *named* character(0), which is not identical to character()
  # -- a distinction that shows up nowhere except in a test comparison.
  unname(MARINER_DIR_NAMES[names(absent)])
}

.onAttach <- function(libname, pkgname) {
  # Three guards, in order:
  #
  # 1. One option turns the whole behaviour off.
  # 2. The working directory must look like a project root -- a bare getwd() is
  #    not enough, or someone starting R in ~ or / gets folders there.
  # 3. Non-interactive sessions are skipped. Rscript in CI, a future
  #    multisession worker, and R CMD check all attach this package, and none of
  #    them is a person opening a project.
  #
  # (1) and (2) live in auto_setup_dirs(); (3) is here, because a test needs to
  # exercise the other two and testthat is not interactive.
  #
  # This is .onAttach, NOT .onLoad. .onLoad fires on namespace load, which
  # includes installation and R CMD check -- creating directories during a build
  # is surprising, and on a read-only library path it is a failure.
  #
  # What this does is cheap: three mkdir calls. It does NOT assemble the
  # extension. That stays in mariner_setup_project(), where it was asked for.
  if (!interactive()) return(invisible(NULL))

  created <- auto_setup_dirs()

  # Silent when everything is already there, so the message appears once per
  # project rather than every session.
  if (!length(created)) return(invisible(NULL))

  packageStartupMessage(
    "mariner: created ", paste0(created, "/", collapse = ", "),
    " in this project.\n",
    "Run mariner_setup_project() to install the theme into them."
  )
  invisible(NULL)
}
