# Small shared helpers.

# Format a number for a generated artefact.
#
# Trailing zeros are noise in a LaTeX preamble, and the drift test compares
# BYTES -- so "1.4053" has to come out the same way every time it is generated,
# on every platform.
num_str <- function(x) {
  format(round(x, 4), trim = TRUE, scientific = FALSE, drop0trailing = TRUE)
}

# Copy a file, never clobbering unless asked.
#
# Returns TRUE if it wrote, FALSE if it declined because the destination
# existed -- which is what lets the scaffolder report "created" and "already
# there" as different outcomes instead of claiming credit for a file a student
# wrote themselves.
#
# The inner overwrite = TRUE is deliberate and is NOT the argument: by the time
# we reach it we have already decided the destination is ours to write.
copy_file_safe <- function(src, dst, overwrite = FALSE) {
  if (file.exists(dst) && !overwrite) return(invisible(FALSE))
  dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
  ok <- file.copy(src, dst, overwrite = TRUE)
  if (!ok) {
    cli::cli_abort(c(
      "Could not write {.file {dst}}.",
      i = "Check that the directory is writable."
    ))
  }
  invisible(TRUE)
}

# Copy a directory tree, file by file, respecting `overwrite` per file.
#
# The obvious implementation of the relative paths -- sub()-ing a normalised
# source prefix off each normalised absolute path -- builds a regex out of a
# filesystem path, and breaks on any directory whose name contains a regex
# metacharacter. list.files() with full.names = FALSE already returns exactly
# the relative paths we need.
#
# Per-file rather than a single recursive file.copy() because overwrite has to
# apply to each destination independently: re-running the scaffolder in a
# project where a student has edited one file inside the extension must leave
# that edit alone and still restore the twelve font files they deleted.
copy_dir_safe <- function(src, dst, overwrite = FALSE) {
  rel <- list.files(src, recursive = TRUE, all.files = TRUE, no.. = TRUE)
  for (r in rel) {
    copy_file_safe(file.path(src, r), file.path(dst, r), overwrite = overwrite)
  }
  invisible(dst)
}
