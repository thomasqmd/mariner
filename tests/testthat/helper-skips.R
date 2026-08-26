# Skip helpers for environment-dependent test suites.

skip_if_no_quarto <- function() {
  path <- tryCatch(quarto::quarto_path(), error = function(e) NULL)
  if (is.null(path) || !nzchar(path) || !file.exists(path)) {
    testthat::skip("Quarto CLI is not available")
  }
  ver <- tryCatch(quarto::quarto_version(), error = function(e) NULL)
  if (is.null(ver) || ver < "1.4") {
    testthat::skip("Quarto >= 1.4 is required")
  }
}

skip_if_no_latex <- function() {
  has_tinytex <- isTRUE(tryCatch(tinytex::is_tinytex(), error = function(e) FALSE))
  has_xelatex <- nzchar(Sys.which("xelatex"))
  if (!has_tinytex && !has_xelatex) {
    testthat::skip("xelatex / LaTeX engine is not available")
  }
}

skip_if_no_fonts <- function(format = "pdf") {
  if (!isTRUE(mariner_fonts_available(format))) {
    testthat::skip(paste0("theme fonts not installed system-wide for format: ", format))
  }
}
