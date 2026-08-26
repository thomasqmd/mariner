# Render the example gallery and put the PDF where pkgdown will publish it.
#
#   Rscript data-raw/render-examples.R
#
# The gallery is an EXAMPLE, not the report template. The template is the
# starting point a student edits and is deliberately near-empty; this is the
# other thing -- every colour family, both faces, the markup vocabulary and all
# five callouts on one set of pages, so that someone deciding whether to install
# mariner can see what they would get.
#
# Only inst/examples/<theme>/gallery.qmd is committed. The _extensions/
# directory it renders against is assembled here, fresh, and deleted again:
# committing one would fork the copy Quarto reads away from inst/, which is the
# single-copy rule in plan.md 0.3.
#
# The rendered PDF IS committed, to pkgdown/assets/, because pkgdown copies that
# directory into docs/ verbatim and the gallery has to be reachable from the
# site without a build step.

if (!requireNamespace("pkgload", quietly = TRUE)) {
  stop("pkgload is required to run this script: install.packages('pkgload')")
}

pkgload::load_all(".", quiet = TRUE, export_all = TRUE)

for (theme in mariner_themes) {
  src <- file.path("inst", "examples", theme, "gallery.qmd")
  if (!file.exists(src)) {
    cli::cli_alert_warning("no gallery for {.val {theme}}, skipping")
    next
  }

  ext_root <- dirname(src)
  cli::cli_h1("Rendering the {theme} gallery")

  # Beside the document, not above it: brand-preamble.tex reaches the fonts
  # through Path=_extensions/<theme>/fonts/, and xelatex resolves that against
  # the directory holding the .tex. See plan.md 0.4.
  mariner_build_extension(ext_root, theme, quiet = TRUE)

  # unlink() below rather than on.exit() above: on.exit only registers against a
  # function's frame, and at the top level of a script it registers against
  # nothing at all -- which left a stale _extensions/ sitting in the source tree
  # the first time this ran.
  rendered <- tryCatch(
    {
      quarto::quarto_render(src, quiet = FALSE)
      TRUE
    },
    error = function(e) {
      unlink(file.path(ext_root, "_extensions"), recursive = TRUE)
      cli::cli_abort("Rendering {.file {src}} failed.", parent = e)
    }
  )
  unlink(file.path(ext_root, "_extensions"), recursive = TRUE)

  dest_dir <- file.path("pkgdown", "assets")
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  dest <- file.path(dest_dir, paste0(theme, "-gallery.pdf"))

  ok <- file.copy(file.path(ext_root, "gallery.pdf"), dest, overwrite = TRUE)
  if (!ok) {
    cli::cli_abort("Could not copy the rendered gallery to {.file {dest}}.")
  }

  # The rendered PDF stays only at the destination; leaving a second copy beside
  # the source is how the two drift apart.
  unlink(file.path(ext_root, "gallery.pdf"))
  unlink(file.path(ext_root, "gallery_files"), recursive = TRUE)
  unlink(file.path(ext_root, ".quarto"), recursive = TRUE)

  cli::cli_alert_success("wrote {.file {dest}}")
}
