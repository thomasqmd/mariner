# Helpers for the vendored-theme tests.

# The package source root, as seen from tests/testthat/.
#
# The generators take a `root` and write beneath it, so the drift test needs the
# source tree rather than the installed package. Under R CMD check the source is
# not present, and these tests skip rather than fail -- they guard the developer
# loop, and there is nothing to regenerate from in a tarball.
pkg_root <- function() {
  candidate <- testthat::test_path("..", "..")
  if (file.exists(file.path(candidate, "DESCRIPTION")) &&
      dir.exists(file.path(candidate, "inst"))) {
    return(normalizePath(candidate))
  }
  NULL
}

skip_if_no_source <- function() {
  root <- pkg_root()
  testthat::skip_if(is.null(root), "package source tree not available")
  root
}
