# Rendering one document and bundling what comes out of it.

# What a bundle can contain. Order is the order they are documented in; the
# vocabulary is fixed so `include` can be checked rather than trusted.
INCLUDE_KINDS <- c("source", "script", "output", "intermediates")

# Rendered-document extensions. Anything here is the deliverable itself.
OUTPUT_EXTS <- c("pdf", "html", "docx", "pptx", "odt", "epub", "rtf")

# Sort one render's leftovers into the four `include` categories.
#
# `<stem>_files/` is classed as OUTPUT, not intermediates, and the asymmetry is
# deliberate. For html it is not optional -- the document is broken without it.
# For pdf it is merely redundant, since the figures are already embedded. Being
# wrong in the first direction ships a broken deliverable; being wrong in the
# second ships a slightly larger zip, so the classification takes the safe side.
#
# The `_files` directory is matched by SUFFIX rather than against `<stem>_files`,
# because the stem of the output is not always the stem of the input: Quarto
# slugifies the name it writes, so `report with spaces.qmd` renders to
# `report-with-spaces.pdf` and `report-with-spaces_files/`. Matching the input
# stem sent that directory to `intermediates`, which is invisible under the
# default `include` and ships a BROKEN html bundle under
# `include = c("source", "output")` -- for documents whose only distinguishing
# feature is a space in the filename.
#
# Matching every `*_files` is safe by construction rather than by luck: the
# scratch directory is created empty and receives exactly one file, so anything
# else in it was produced by the render.
#
# Everything unrecognised falls to `intermediates` rather than being dropped:
# the default includes all four, so an unfamiliar artefact travels with the
# bundle instead of going missing without anyone noticing.
classify_artefacts <- function(entries, stem) {
  ext <- tolower(tools::file_ext(entries))

  kind <- rep("intermediates", length(entries))
  kind[ext %in% OUTPUT_EXTS] <- "output"
  kind[grepl("_files$", entries)] <- "output"
  kind[entries == paste0(stem, ".R")] <- "script"
  kind[entries == paste0(stem, ".qmd")] <- "source"

  split(entries, factor(kind, levels = INCLUDE_KINDS))
}

# "Did you mean reports/<name>?"
#
# The working directory is the project root and the sources live in reports/, so
# a student who reads a filename out of the RStudio Files pane and types it gets
# a miss. This function already resolves the OUTPUT from the project layout --
# the zip goes to zip_files/ -- and this is the input half of that same
# knowledge.
#
# A HINT, not a fallback. Resolving the bare name silently would work and would
# teach nobody where their files are, and it would turn a typo into a search of
# two directories reported as one failure.
#
# Only bare filenames, because that is the mistake being answered. A path that
# is already a path is a different error, and pointing it at reports/ would be
# a guess rather than a hint.
#
# The relative form is returned rather than the absolute one: it is what the
# caller has to type, and MARINER_DIR_NAMES keeps it right through a rename.
reports_hint <- function(input_file, root = NULL) {
  if (!identical(basename(input_file), input_file)) return(NULL)

  dirs <- tryCatch(mariner_dirs(root), error = function(e) NULL)
  if (is.null(dirs) || !file.exists(file.path(dirs$reports, input_file))) return(NULL)

  file.path(MARINER_DIR_NAMES[["reports"]], input_file)
}

# Put the theme where the document can reach it, and return an undo function.
#
# §0.4 of the plan, measured rather than assumed: `brand-preamble.tex` reaches
# the bundled fonts through `Path=_extensions/mariner-<theme>/fonts/`, and
# xelatex resolves that against the directory holding the `.tex` -- the
# document's own. An extension one level up gives a render that finds its
# *format* and then dies with "The font Lora-Regular cannot be found".
#
# Symlinked when the platform allows it, because a copy is ~1.3 MB per document
# and a class set is fifty of them. Windows refuses symlinks without developer
# mode or elevation, and file.symlink() reports that as FALSE plus a warning, so
# the copy is the fallback rather than the default.
stage_extension <- function(scratch, theme, assets_dir) {
  ext_name <- mariner_ext_name(theme)
  dest <- file.path(scratch, "_extensions", ext_name)
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)

  source_ext <- if (is.null(assets_dir)) NULL else mariner_ext_dir(assets_dir, theme)

  if (!is.null(source_ext) && dir.exists(source_ext)) {
    linked <- suppressWarnings(file.symlink(normalizePath(source_ext), dest))
    if (!isTRUE(linked)) copy_dir_safe(source_ext, dest, overwrite = TRUE)
  } else {
    # No prebuilt extension to serve from -- mariner_setup_project() has not
    # been run, or the caller passed assets_dir = NULL. Assemble one straight
    # into the scratch directory from the installed package.
    mariner_build_extension(scratch, theme = theme, quiet = TRUE)
  }

  # Removing the LINK before the scratch tree goes is not superstition: a
  # recursive delete that followed it would take the project's assets/ with it.
  #
  # fs::link_delete(), not unlink(recursive = FALSE). The latter removes a POSIX
  # symlink and REFUSES a Windows directory reparse point --
  #
  #   cannot delete reparse point '...', reason 'There is a mismatch between the
  #   tag specified in the request and the tag present in the reparse point'
  #
  # -- which left the link standing for the fs::dir_delete() on the next line,
  # so the guarantee above rested on fs happening not to follow it rather than
  # on this function having done its job.
  #
  # A link that cannot be removed is WARNED about, never deleted recursively.
  # Leaving one in a temp directory costs nothing; following it costs the
  # student their assets/.
  function() {
    if (fs::is_link(dest)) {
      tryCatch(fs::link_delete(dest), error = function(e) {
        cli::cli_warn(c(
          "Could not remove the staged theme link at {.file {dest}}.",
          i = "It is inside a temporary directory and can be deleted by hand."
        ))
      })
    } else {
      # The copy fallback: a real directory, and one this function created.
      unlink(dest, recursive = TRUE, force = TRUE)
    }
  }
}

#' Bundle a Quarto file and its outputs
#'
#' @description
#' Renders a Quarto (`.qmd`) file and bundles the source, the purled R script,
#' the rendered document and the render's intermediates into one zip archive.
#'
#' @details
#' The render runs in a temporary directory, with the theme staged next to the
#' document. Nothing lands beside the source, and parallel callers cannot
#' collide on a shared cache.
#'
#' `include` selects what reaches the archive:
#'
#' \describe{
#'   \item{`source`}{the `.qmd` itself}
#'   \item{`script`}{the purled `.R`}
#'   \item{`output`}{the rendered document and its `_files/` directory}
#'   \item{`intermediates`}{whatever else the render left behind, such as the
#'     `.tex` under `keep-tex`}
#' }
#'
#' The Quarto extension is never bundled. A report renders inside a project that
#' has one, and a copy per archive costs ~1.3 MB.
#'
#' @param input_file Path to the input `.qmd`.
#' @param output_zip Path for the output `.zip`. Defaults to the source's name
#'   in the project's `zip_files/` folder. See [mariner_dirs()].
#' @param theme One of [mariner_themes].
#' @param assets_dir Directory that holds a built extension, as
#'   [mariner_setup_project()] leaves in `assets/`. `NULL` assembles one from the
#'   installed package for this render.
#' @param include Which categories to bundle. Any of `"source"`, `"script"`,
#'   `"output"`, `"intermediates"`.
#'
#' @return Invisibly, the path to the zip file.
#' @export
#' @importFrom knitr purl
#' @importFrom quarto quarto_render
#' @importFrom fs path_abs path_ext_set file_copy dir_create dir_delete path_file
#' @importFrom withr with_dir
#' @importFrom tools file_ext file_path_sans_ext
#'
#' @examples
#' \dontrun{
#' temp_dir <- tempfile("example-")
#'
#' doc <- generate_reports(
#'   params_df = data.frame(chapter = 1, problem_numbers = 1, author = "A. Name"),
#'   output_dir = temp_dir
#' )
#'
#' # Everything, into zip_files/:
#' process_file(doc)
#'
#' # Just the source and the PDF, somewhere explicit:
#' process_file(
#'   doc,
#'   output_zip = file.path(temp_dir, "handout.zip"),
#'   include = c("source", "output")
#' )
#'
#' unlink(temp_dir, recursive = TRUE)
#' }
process_file <- function(input_file,
                         output_zip = NULL,
                         theme = mariner_themes,
                         assets_dir = mariner_dirs()$assets,
                         include = INCLUDE_KINDS) {
  if (!file.exists(input_file)) {
    hint <- reports_hint(input_file)
    cli::cli_abort(c(
      "Input file does not exist: {.file {input_file}}.",
      # NULL when there is nothing to suggest, which drops the bullet.
      i = if (!is.null(hint)) "Did you mean {.file {hint}}?"
    ))
  }

  input_path <- fs::path_abs(input_file)
  input_ext <- tolower(tools::file_ext(input_path))
  if (!identical(input_ext, "qmd")) {
    cli::cli_abort(c(
      "Input file must be a .qmd file.",
      x = "Got {.file {fs::path_file(input_path)}}.",
      i = "mariner is Quarto-only as of 0.2.0."
    ))
  }

  theme <- check_theme(theme)
  include <- rlang::arg_match(include, INCLUDE_KINDS, multiple = TRUE)

  # Defaults into zip_files/, not beside the source. The bundles are a
  # deliverable and belong together; scattering them through reports/ meant
  # hunting for them, and meant `reports/` held both inputs and outputs.
  #
  # The root is resolved from the INPUT FILE's directory, not from getwd().
  # `reports/ch1.qmd` belongs to the project containing `reports/`, whatever
  # directory R happens to be sitting in -- and a parallel worker's working
  # directory is not the caller's at all.
  output_path <- if (is.null(output_zip)) {
    file.path(
      mariner_dirs(mariner_project_root(dirname(input_path)))$zips,
      paste0(tools::file_path_sans_ext(fs::path_file(input_path)), ".zip")
    )
  } else {
    fs::path_abs(output_zip)
  }
  fs::dir_create(dirname(output_path))

  # path_real() AFTER creating it, because path_real() requires the path to
  # exist. What it buys is the one form of the path that every tool agrees on:
  # it resolves symlinks -- on macOS tempdir() is /var/..., a link to
  # /private/var/... -- and on Windows expands an 8.3 short name back to the
  # long one. The Quarto CLI is a separate process that resolves paths itself,
  # so handing it a directory whose name we only half know is how "it rendered
  # but the outputs are not where I looked" happens.
  #
  # Spaces need no special handling here and must not get any: `Personal R
  # Projects` is in this package's own checkout path, quarto_render() quotes its
  # arguments, and the document is passed as a bare filename relative to this
  # directory. Quoting it again would create the bug it was meant to prevent.
  scratch <- fs::path_real(fs::dir_create(tempfile(pattern = "doc-bundle-")))
  unstage <- stage_extension(scratch, theme, assets_dir)
  on.exit({
    unstage()
    fs::dir_delete(scratch)
  }, add = TRUE)

  fs::file_copy(input_path, scratch)
  doc_file_name <- fs::path_file(input_path)
  stem <- tools::file_path_sans_ext(doc_file_name)

  withr::with_dir(scratch, {
    tryCatch(
      {
        knitr::purl(doc_file_name)
        quarto::quarto_render(doc_file_name, quiet = TRUE)
      },
      error = function(e) {
        cli::cli_abort(
          c("Failed while processing {.file {doc_file_name}}.", x = e$message),
          parent = e
        )
      }
    )

    # Explicit, not fs::dir_ls(): that is non-recursive, so it listed
    # `<stem>_files` as a bare name and zip::zip() stored an empty directory
    # entry for it. `recurse = TRUE` below is what reaches inside; this decides
    # WHAT to reach into.
    #
    # _extensions is excluded by construction rather than by filter -- it is
    # staged, not produced, and on a symlinking platform zipping it would
    # dereference into the project's assets/.
    entries <- setdiff(
      list.files(".", all.files = FALSE, no.. = TRUE),
      c("_extensions", ".quarto")
    )
    by_kind <- classify_artefacts(entries, stem)
    files_to_zip <- unlist(by_kind[include], use.names = FALSE)

    if (!length(files_to_zip)) {
      cli::cli_abort(c(
        "Nothing to bundle for {.file {doc_file_name}}.",
        i = "{.arg include} was {.val {include}}, and the render produced \\
             nothing in {?that category/those categories}."
      ))
    }

    zip::zip(
      zipfile = output_path,
      files = files_to_zip,
      root = ".",
      recurse = TRUE
    )
  })

  if (!file.exists(output_path)) {
    cli::cli_abort("Bundling failed: no archive at {.file {output_path}}.")
  }

  cli::cli_alert_success("Bundled {.file {fs::path_file(output_path)}}")
  invisible(output_path)
}
