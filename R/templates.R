# Template discovery and resolution.

#' Available mariner templates
#'
#' Lists the template names shipped by a package.
#'
#' @param package Package to inspect. Defaults to `"mariner"`.
#' @return A character vector of template names.
#' @export
#' @examples
#' mariner_templates()
mariner_templates <- function(package = "mariner") {
  dir <- system.file("templates", package = package)
  if (!nzchar(dir) || !dir.exists(dir)) return(character())
  dirs <- list.dirs(dir, recursive = FALSE, full.names = FALSE)
  valid <- dirs[file.exists(file.path(dir, dirs, "skeleton.qmd"))]
  sort(valid)
}

#' Path to a mariner template skeleton
#'
#' Resolves the path to a template's `skeleton.qmd` file.
#'
#' @param template Name of the template directory under `inst/templates/`.
#'   Defaults to `"report"`.
#' @param package Package shipping the template. Defaults to `"mariner"`.
#' @param call Caller environment for error reporting.
#' @return An absolute file path to the template's `skeleton.qmd`.
#' @export
#' @examples
#' mariner_template_path("report")
mariner_template_path <- function(template = "report",
                                  package = "mariner",
                                  call = rlang::caller_env()) {
  if (!is.character(template) || length(template) != 1L || is.na(template) || !nzchar(template)) {
    cli::cli_abort("{.arg template} must be a single non-empty string.", call = call)
  }

  path <- system.file("templates", template, "skeleton.qmd", package = package)
  if (identical(path, "") || !file.exists(path)) {
    available <- mariner_templates(package = package)
    cli::cli_abort(
      c(
        "No template named {.val {template}} in package {.pkg {package}}.",
        i = if (length(available)) {
          "Available: {.val {available}}."
        } else {
          "That package ships no mariner templates."
        }
      ),
      call = call
    )
  }
  path
}
