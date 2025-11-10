#' mariner: Streamline R Markdown Report Generation and Bundling
#'
#' @description
#' The `mariner` package simplifies and automates the process of creating and
#' packaging R Markdown documents. It provides a cohesive workflow for first
#' generating multiple Rmd source files from a single parameterized template,
#' and then bundling those source files along with all their rendered outputs
#' (e.g., PDFs, scripts, and dependency files) into easily shareable zip
#' archives.
#'
#' @section Core Workflow:
#' The typical workflow involves two main steps:
#' \enumerate{
#'   \item Use \code{\link{generate_reports}} to create multiple,
#'     parameterized `.Rmd` source files from a template.
#'   \item Use \code{\link{process_files}} to render each `.Rmd` file
#'     and bundle the source, R script, and all outputs into a zip archive.
#' }
#'
#' @seealso
#' Useful functions:
#' \itemize{
#'   \item \code{\link{generate_reports}}
#'   \item \code{\link{process_files}}
#'   \item \code{\link{process_file}}
#' }
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL
