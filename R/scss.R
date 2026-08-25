# The stylesheet layer stack.
#
# Quarto reassembles a multi-file `theme:` list by LAYER, not by file, and the
# two layers it cares about here move in opposite directions:
#
#   defaults  concatenated in REVERSE list order
#   rules     concatenated in list order
#
# That was established by compiling probes rather than by reading about it, and
# it has one consequence that shapes every partial in inst/scss/: a file's
# defaults cannot see a variable defined in the defaults of a file listed BEFORE
# it. Hence the ordering rule the whole set is written against:
#
#   * _qmd-tokens.scss is listed LAST, so after reversal its variables come first.
#   * A partial may reference $qmd-* in its defaults, and nothing else from
#     another partial.
#   * Rules land in list order, so the list runs base -> chrome -> opt-in ->
#     accessibility, and the later entries win ties on specificity.
#
# The order lives here, in one place, so the extension YAML written in P6 and
# the test that compiles the stack cannot drift apart.
#
# Quarto also rejects a theme file containing no layer boundary at all -- it is
# an error, not a default -- which is why the generated token files carry an
# explicit marker.

# THE `qmd-` PREFIX IS RETAINED, and it no longer stands for anything.
#
# These partials came from QMDThemes, where the prefix named the package. mariner
# does not depend on that package and does not sync with it, so the name is now
# purely an internal namespace -- it appears in the SCSS variables, the `.qmd-*`
# utility classes, the `\qmd*` LaTeX colour commands and the `qmd-*` Typst
# bindings.
#
# It is kept rather than renamed because the prefix's actual job, below, is
# served by any prefix at all, while renaming means touching every one of those
# four file formats at once -- and a miss in the SCSS is a compile error, but a
# miss in a `.qmd-*` class name is silently unstyled output. The name is
# cosmetic; the churn would not be.
#
# Every file is prefixed `qmd-`, and that is not a style choice.
#
# Quarto puts the directory of each theme file on the Sass load path, so a
# partial here can SHADOW one of Bootstrap's. Naming this set the obvious
# things -- _utilities.scss, _functions.scss, _tables.scss -- meant Bootstrap's
# own `@import "utilities"` resolved to ours instead, and html builds died
# inside Bootstrap with `Undefined variable: $utilities` pointing at a file we
# had never touched. revealjs was unaffected, because it does not load
# Bootstrap, so half the formats worked.
#
# Prefixing all of them, not just the three that collide with Bootstrap today,
# because the failure is silent until it is baffling and the cost is a prefix.

# Hand-written partials, in `theme:` order. The format's own file slots in at
# the marker.
MARINER_SCSS_STACK <- c(
  "_qmd-typography.scss",   # base type, links
  "_qmd-tables.scss",       # table base and density scale
  "<format>",               # report or slide chrome
  "_qmd-utilities.scss",    # the opt-in class vocabulary
  "_qmd-a11y.scss",         # focus, motion, print -- wins ties by being late
  "_qmd-tokens-css.scss",   # generated: :root custom properties
  "_qmd-functions.scss",    # qmd-tint(), the mixins, the sass: modules
  "_qmd-tokens.scss"        # generated: $qmd-* -- LAST, see above
)

#' Stylesheet files for a theme and format, in `theme:` order
#'
#' The list a Quarto `theme:` key needs. Order matters and is not alphabetical
#' or dependency order -- see the note at the top of `R/scss.R`.
#'
#' @param theme One of [mariner_themes].
#' @param format `"html"` or `"revealjs"`. The other two formats in
#'   [mariner_formats] are not styled with SCSS.
#' @param absolute Return full paths into the installed package, rather than
#'   names relative to the extension directory.
#' @return A character vector of file paths.
#' @noRd
#' @examples
#' mariner_scss_files("baylor", "revealjs", absolute = FALSE)
mariner_scss_files <- function(theme = mariner_themes, format = c("html", "revealjs"),
                           absolute = TRUE) {
  theme <- check_theme(theme)
  format <- rlang::arg_match(format)
  files <- sub("^<format>$", paste0("qmd-", format, ".scss"), MARINER_SCSS_STACK)
  if (!absolute) return(files)

  ext <- file.path("quarto", "_extensions", mariner_ext_name(theme))
  vapply(files, function(f) {
    # The generated ones live with their theme; the hand-written ones are shared
    # by both themes and live once.
    if (f %in% c("_qmd-tokens.scss", "_qmd-tokens-css.scss")) mariner_path(ext, f)
    else mariner_path("scss", f)
  }, character(1), USE.NAMES = FALSE)
}

# Quarto's layer markers, in the order the assembled stylesheet uses them.
SCSS_LAYERS <- c("uses", "functions", "defaults", "mixins", "rules")

# Split one theme file into its layers.
#
# Quarto's own splitter; reproduced here so the test suite can assemble a
# stylesheet exactly as a render would, and catch a broken partial without
# needing Quarto, a document and a full render to do it.
split_scss_layers <- function(path) {
  txt <- readLines(path, warn = FALSE)
  marker <- "^\\s*/\\*--\\s*scss:([a-z]+)\\s*--\\*/\\s*$"
  hits <- grep(marker, txt)
  if (!length(hits)) {
    cli::cli_abort("{.file {path}} contains no scss layer boundary.")
  }
  names <- sub(marker, "\\1", txt[hits])
  ends <- c(hits[-1] - 1L, length(txt))
  out <- stats::setNames(vector("list", length(SCSS_LAYERS)), SCSS_LAYERS)
  for (i in seq_along(hits)) {
    layer <- names[[i]]
    if (!layer %in% SCSS_LAYERS) {
      cli::cli_abort("{.file {path}}: unknown scss layer {.val {layer}}.")
    }
    out[[layer]] <- c(out[[layer]], txt[seq.int(hits[[i]] + 1L, ends[[i]])])
  }
  out
}

#' Assemble a stylesheet the way Quarto would
#'
#' Concatenates the layers of several theme files into one compilable
#' stylesheet: defaults in reverse file order, everything else in file order.
#'
#' @param paths Theme files, in `theme:` order.
#' @return A single string of SCSS.
#' @noRd
assemble_scss <- function(paths) {
  layers <- lapply(paths, split_scss_layers)
  chunk <- function(layer, files) {
    parts <- lapply(files, function(l) l[[layer]])
    unlist(parts[lengths(parts) > 0])
  }
  paste(
    c(
      chunk("uses", layers),
      chunk("functions", layers),
      # The reversal. Without it a partial's defaults would be assembled before
      # the tokens it references, which is a compile error rather than a
      # silently wrong colour -- see the note at the top of this file.
      chunk("defaults", rev(layers)),
      chunk("mixins", layers),
      chunk("rules", layers)
    ),
    collapse = "\n"
  )
}
