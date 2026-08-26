# Assembling the Quarto extension.
#
# The extension is a BUILD OUTPUT and is not committed. Nothing under inst/ is a
# second copy of anything else:
#
#   inst/tex/                             hand-written, shared by every theme
#   inst/assets/fonts/  inst/assets/logos/  the binaries
#   inst/generated/<theme>/                 written by build_tokens() from
#                                           _brand.yml
#
# and this function is what turns those into the `_extensions/mariner-<theme>/`
# directory Quarto actually reads. It runs against the INSTALLED package, so the
# same call serves both callers: scaffolding a student's project, and preparing
# a scratch directory for one render.
#
# The alternative -- committing the assembled extension under inst/ -- shipped
# every font, logo and partial twice, and made "which copy is real?" a question
# a hash test had to answer. Assembling on demand deletes the question: a
# generated file cannot go stale against a source it is built from at the moment
# of use.
#
# Copied, not symlinked, because this output is handed to a student and has to
# survive being moved, zipped and emailed. (A per-render scratch directory has
# no such constraint and may link instead -- see the note in process_file().)

# Which of the package's own directories contribute to the extension, and where
# each lands inside it. One list, so the builder and the test that checks the
# result cannot disagree about what "complete" means.
EXTENSION_SOURCES <- list(
  list(from = "tex",                pattern = "\\.tex$",         into = "."),
  # Alongside the manifest rather than in a subdirectory, because _extension.yml
  # names the filter by bare filename and Quarto resolves that against the
  # extension root.
  list(from = "lua",                pattern = "\\.lua$",         into = "."),
  list(from = c("assets", "fonts"), pattern = "\\.(ttf|txt)$",   into = "fonts"),
  # Every mark, not just the ones wired up today. They are ~35 KB together, and
  # a template that reaches for the stacked lockup should not need a rebuild.
  list(from = c("assets", "logos"), pattern = "\\.(png|svg)$",   into = "logos")
)

# The relative paths a freshly built extension contains.
#
# Derived by walking EXTENSION_SOURCES, the same list mariner_build_extension()
# walks, so "complete" cannot come to mean two different things -- which is the
# whole reason that list exists. A checker with its own hardcoded inventory
# would go stale the first time a font cut or a logo slot is added.
extension_manifest <- function(theme = mariner_themes) {
  theme <- check_theme(theme)

  rel <- character()
  for (src in EXTENSION_SOURCES) {
    from <- mariner_path(paste(src$from, collapse = .Platform$file.sep))
    files <- basename(list.files(from, pattern = src$pattern))
    rel <- c(rel, if (identical(src$into, ".")) files else file.path(src$into, files))
  }

  # The generated half, named from what is on disk rather than from a list of
  # expected filenames -- build_tokens() decides what it writes.
  c(rel, basename(list.files(mariner_path("generated", theme))))
}

# Which of those an assembled extension is missing. character(0) means complete.
#
# A partially-assembled extension is the failure mode worth naming: xelatex does
# not fall back to a system face when fonts/ is short a cut, it aborts with "the
# font Lora-Regular cannot be found", which says nothing about the directory
# being incomplete.
extension_missing <- function(ext_dir, theme = mariner_themes) {
  want <- extension_manifest(theme)
  if (!dir.exists(ext_dir)) return(want)
  want[!file.exists(file.path(ext_dir, want))]
}

#' Assemble the Quarto extension for a theme into a directory
#'
#' Builds `<dest>/_extensions/mariner-<theme>/` from the package's installed
#' sources: the shared TeX includes, the bundled fonts and logos, and the
#' generated preamble and manifest for the theme.
#'
#' The result is self-contained, and it has to be. `brand-preamble.tex` reaches
#' the fonts through `Path=_extensions/mariner-<theme>/fonts/`, which xelatex
#' resolves against the directory holding the `.tex` -- that is, the document's
#' own directory. An extension one level up gives a document that finds its
#' *format* and then dies with "the font Lora-Regular cannot be found".
#'
#' @param dest Directory that will contain `_extensions/`. Created if needed.
#' @param theme One of [mariner_themes].
#' @param overwrite Replace files already present in the destination.
#' @param quiet Suppress the summary message.
#' @return The extension directory, invisibly.
#' @noRd
mariner_build_extension <- function(dest, theme = mariner_themes,
                                    overwrite = TRUE, quiet = FALSE) {
  theme <- check_theme(theme)

  ext_dir <- mariner_ext_dir(dest, theme)
  dir.create(ext_dir, recursive = TRUE, showWarnings = FALSE)

  copied <- character()
  copy_into <- function(files, dir) {
    if (!length(files)) return(invisible(NULL))
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    dests <- file.path(dir, basename(files))
    ok <- file.copy(files, dests, overwrite = overwrite)
    # A copy that returns FALSE with overwrite = FALSE is a file already there,
    # which is fine. With overwrite = TRUE it is a real failure -- a read-only
    # destination, a full disk -- and staying quiet about it means the student
    # finds out at render time, from a missing-font error that names nothing.
    if (overwrite && !all(ok)) {
      cli::cli_abort(c(
        "Could not write the theme assets into {.file {dir}}.",
        x = "Failed: {.file {basename(files[!ok])}}"
      ))
    }
    copied <<- c(copied, dests[ok])
    invisible(NULL)
  }

  for (src in EXTENSION_SOURCES) {
    from <- mariner_path(paste(src$from, collapse = .Platform$file.sep))
    files <- list.files(from, pattern = src$pattern, full.names = TRUE)
    copy_into(files, if (identical(src$into, ".")) ext_dir else file.path(ext_dir, src$into))
  }

  # The generated half: brand-preamble.tex and _extension.yml.
  generated <- list.files(mariner_path("generated", theme), full.names = TRUE)
  if (!length(generated)) {
    cli::cli_abort(c(
      "No generated token files found for theme {.val {theme}}.",
      i = "The install may be incomplete; try reinstalling mariner."
    ))
  }
  copy_into(generated, ext_dir)

  if (!quiet) {
    cli::cli_alert_success(
      "built {.file {mariner_ext_name(theme)}} ({length(copied)} files) in {.file {dest}}"
    )
  }
  invisible(ext_dir)
}
