#' mariner: Streamline Quarto Report Generation and Bundling
#'
#' @description
#' The `mariner` package simplifies and automates the process of creating and
#' packaging Quarto (.qmd) documents. It provides a cohesive workflow for first
#' generating multiple document source files from a single parameterized
#' template, and then bundling those source files along with all their rendered
#' outputs (e.g., PDFs, scripts, and dependency files) into easily shareable zip
#' archives.
#'
#' It also carries a complete Baylor-branded Quarto theme, so a generated report
#' is styled, typeset in bundled fonts, and has its figures drawn from the same
#' palette as the page, without anything to install separately.
#'
#' @section Core Workflow:
#' \enumerate{
#'   \item Run \code{\link{mariner_check_setup}} to confirm this machine has
#'     everything a branded report needs -- Quarto, a LaTeX engine, the fonts.
#'     It reports and prints the fix; it changes nothing.
#'   \item Use \code{\link{mariner_setup_project}} once to create the project
#'     folders and install the theme assets into them.
#'   \item Use \code{\link{generate_reports}} to create multiple, parameterized
#'     `.qmd` source files from a template, into `reports/`.
#'   \item Use \code{\link{process_files}} to render each source file and bundle
#'     the source, R script, and all outputs into a zip archive, into
#'     `zip_files/`.
#' }
#'
#' @section Project Folders:
#' mariner works in three directories beneath the project root, returned by
#' \code{\link{mariner_dirs}}:
#'
#' \describe{
#'   \item{`assets/`}{The built Quarto extension, assembled once.}
#'   \item{`reports/`}{Generated `.qmd` sources, their rendered PDFs, and a copy
#'     of the extension beside them.}
#'   \item{`zip_files/`}{The bundles handed to students.}
#' }
#'
#' Attaching the package with `library(mariner)` creates the three folders if
#' the working directory looks like a project root -- see
#' \code{\link{mariner_looks_like_project}}. Set
#' `options(mariner.auto_setup = FALSE)` to turn that off.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL

# Locate a file inside the installed package.
#
# Every path the package hands out goes through here rather than through
# system.file() at the call site, so a moved directory is one edit. Errors
# rather than returning "" -- system.file()'s empty-string-on-miss is the
# classic way a broken install turns into a confusing downstream error, and this
# package ships 19 font files that a partial install can silently drop.
mariner_path <- function(...) {
  path <- system.file(..., package = "mariner")
  if (identical(path, "")) {
    cli::cli_abort(c(
      "Could not find {.file {file.path(...)}} in the installed package.",
      i = "The install may be incomplete; try reinstalling mariner."
    ))
  }
  path
}

#' Themes shipped by mariner
#'
#' The brand identities available to `mariner_setup_project()` and the
#' templates. Every function that takes a `theme` argument validates against
#' this vector.
#'
#' There is one theme today. It stays a vector, and `theme` stays a named
#' argument everywhere rather than being dropped, so adding a second identity
#' later is a new entry here rather than a signature change across the package.
#'
#' @format A character vector.
#' @export
mariner_themes <- c("baylor")

#' Formats shipped by mariner
#'
#' The Quarto formats the vendored extension contributes.
#'
#' There is one: `pdf`, rendered through xelatex. mariner exists to turn a
#' parameterized `.qmd` into a bundled report, and a report is a PDF.
#'
#' It stays a vector, and `format` stays a named argument on the functions that
#' take one, for the same reason [mariner_themes] does: a second target later is
#' an entry here rather than a signature change across the package.
#'
#' @format A character vector.
#' @export
mariner_formats <- c("pdf")

# The Quarto extension directory name for a theme.
#
# Derived, never typed. It appears inside asset paths that Quarto and xelatex
# resolve at render time -- the logo and the font directory -- and both of those
# are GENERATED from this function. A rename is therefore this line plus a
# rebuild, rather than a search through a LaTeX preamble where a miss fails
# silently (Quarto simply does not find the logo; xelatex simply substitutes a
# font).
mariner_ext_name <- function(theme = mariner_themes) {
  paste0("mariner-", check_theme(theme))
}

# The extension directory as the RENDERED DOCUMENT sees it: relative to the
# directory Quarto writes the .tex into, which is the document's own. That is
# why the extension has to be assembled beside the document rather than shared
# from a parent -- see R/extension.R.
mariner_ext_rel <- function(theme = mariner_themes) {
  paste0("_extensions/", mariner_ext_name(theme))
}

# The extension directory beneath a given directory, as the FILESYSTEM sees it.
#
# mariner_ext_rel() is what goes into generated LaTeX, where the separator must
# be "/" whatever the platform. This is what goes into file.copy() and
# dir.exists(), where it must be the platform's own. Two callers compose this
# path -- the builder and the project scaffolder -- and they must not each
# assemble it from parts.
mariner_ext_dir <- function(dir, theme = mariner_themes) {
  file.path(dir, "_extensions", mariner_ext_name(theme))
}

# Validate a theme name, with a spell-checked error.
check_theme <- function(theme, call = rlang::caller_env()) {
  rlang::arg_match(theme, mariner_themes, error_call = call)
}

check_format <- function(format, call = rlang::caller_env()) {
  rlang::arg_match(format, mariner_formats, error_call = call)
}
