# Read a generated document's front matter back as a list.
#
# Assertions go through this rather than grepping for `author: "Name"`.
# yaml::as.yaml() quotes only what YAML requires quoting, so a byte-level
# assertion tests the emitter's style choices rather than whether the parameter
# was substituted -- and breaks the moment the implementation stops writing the
# quotes by hand.
#
# Lives here rather than in a test file because three of them need it:
# test-generate_reports.R, test-yaml.R and test-config.R.
front_matter <- function(path) {
  lines <- readLines(path, warn = FALSE)
  fences <- which(grepl("^(---|\\.\\.\\.)\\s*$", lines))
  yaml::yaml.load(paste(lines[(fences[1] + 1):(fences[2] - 1)], collapse = "\n"))
}

# A scratch directory tied to the calling test's lifetime.
local_dir <- function(env = parent.frame()) {
  withr::local_tempdir(.local_envir = env)
}
