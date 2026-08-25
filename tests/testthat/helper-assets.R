# Helpers for the vendored-theme tests.

# Quarto ships dart-sass inside its own installation, under an
# architecture-named directory. Finding it there rather than requiring a
# system-wide `sass` means the stylesheet tests run on any machine that can
# render at all, which is the same bar the package already sets.
find_dart_sass <- function() {
  quarto_bin <- Sys.which("quarto")
  if (!nzchar(quarto_bin)) return(NULL)
  # .../quarto/bin/quarto -> .../quarto/bin/tools/<arch>/dart-sass/sass
  tools_dir <- file.path(dirname(quarto_bin), "tools")
  hits <- list.files(
    tools_dir,
    pattern = "^sass(\\.bat|\\.cmd)?$",
    recursive = TRUE, full.names = TRUE
  )
  if (!length(hits)) return(NULL)
  hits[[1]]
}

skip_if_no_sass <- function() {
  sass <- find_dart_sass()
  testthat::skip_if(is.null(sass), "dart-sass not found (needs a Quarto install)")
  sass
}

# The package source root, as seen from tests/testthat/.
#
# The generators take a `root` and write beneath it, so the drift test needs the
# source tree rather than the installed package. Under R CMD check the source is
# not present, and these tests skip rather than fail -- they guard the developer
# loop, and there is nothing to regenerate from in a tarball.
pkg_root <- function() {
  candidate <- testthat::test_path("..", "..")
  if (file.exists(file.path(candidate, "DESCRIPTION"))) {
    return(normalizePath(candidate))
  }
  NULL
}

skip_if_no_source <- function() {
  root <- pkg_root()
  testthat::skip_if(is.null(root), "package source tree not available")
  root
}
