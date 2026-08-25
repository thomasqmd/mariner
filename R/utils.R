# Small shared helpers.

# Format a number for a generated artefact.
#
# Trailing zeros are noise in a LaTeX preamble, and the drift test compares
# BYTES -- so "1.4053" has to come out the same way every time it is generated,
# on every platform.
num_str <- function(x) {
  format(round(x, 4), trim = TRUE, scientific = FALSE, drop0trailing = TRUE)
}
