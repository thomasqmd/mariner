#' mariner: Streamline Quarto Report Generation and Bundling
#'
#' @description
#' mariner turns one parameterized Quarto template into a set of `.qmd` reports,
#' renders them, and bundles each source, R script and PDF into a zip archive.
#'
#' The package carries its own Quarto PDF theme. A report is typeset in the
#' bundled fonts, and its figures use the palette the page does.
#'
#' @section Core Workflow:
#' \enumerate{
#'   \item \code{\link{mariner_check_setup}} confirms this machine has what a
#'     report needs: Quarto, a LaTeX engine, the fonts. It changes nothing and
#'     prints the fix for whatever is missing.
#'   \item \code{\link{mariner_setup_project}} creates the project folders and
#'     installs the theme into them. Run it once.
#'   \item \code{\link{generate_reports}} writes one `.qmd` per row of a
#'     parameter data frame into `reports/`.
#'   \item \code{\link{process_files}} renders each one and bundles the source,
#'     the R script and the outputs into `zip_files/`.
#' }
#'
#' @section Project Folders:
#' mariner works in three directories beneath the project root. See
#' \code{\link{mariner_dirs}}.
#'
#' \describe{
#'   \item{`assets/`}{The Quarto extension, assembled once.}
#'   \item{`reports/`}{The `.qmd` sources, their PDFs, and a copy of the
#'     extension beside them.}
#'   \item{`zip_files/`}{The bundles you hand out.}
#' }
#'
#' `library(mariner)` creates the three folders when the working directory looks
#' like a project root. See \code{\link{mariner_looks_like_project}}. Set
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
#' templates. Every function with a `theme` argument validates against this
#' vector.
#'
#' There is one theme today. It stays a vector so that a second identity is an
#' entry here rather than a signature change across the package.
#'
#' @format A character vector.
#' @export
mariner_themes <- c("mariner")

#' Formats shipped by mariner
#'
#' The Quarto formats the extension contributes.
#'
#' There is one: `pdf`, through xelatex. mariner turns a parameterized `.qmd`
#' into a report, and a report is a PDF.
#'
#' It stays a vector for the same reason [mariner_themes] does.
#'
#' @format A character vector.
#' @export
mariner_formats <- c("pdf")

# The Quarto extension directory name for a theme.
mariner_ext_name <- function(theme = mariner_themes) {
  check_theme(theme)
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
