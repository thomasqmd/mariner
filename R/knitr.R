# knitr chunk setup and figure dimension helpers.

#' Figure dimensions by document format
#'
#' Provides aspect ratio and dimension calculations tailored to each presentation
#' and reporting target.
#'
#' The slide figure is not a fourth pair of numbers: it is the slide box less
#' the heading bar, computed by `mariner_slide_geometry()` from the constants in
#' `R/slides.R`, so the size knitr draws at, the cap in the stylesheet and the
#' `width:`/`height:` pair in the extension YAML all move together. The other
#' three are page sizes less their margins, which do not vary with anything.
#'
#' @param format Format target: `"revealjs"`, `"html"`, `"pdf"`, or `"typst"`.
#' @return A named list with numeric `width` and `height` in inches.
#' @export
#' @examples
#' mariner_fig_dims("revealjs")
#' mariner_fig_dims("pdf")
mariner_fig_dims <- function(format = c("revealjs", "html", "pdf", "typst")) {
  format <- rlang::arg_match(format)

  if (identical(format, "revealjs")) {
    geom <- mariner_slide_geometry()
    return(list(width = geom$fig_width_in, height = geom$fig_height_in))
  }

  switch(
    format,
    html  = list(width = 8.0, height = 5.0),
    pdf   = list(width = 6.5, height = 4.5),
    typst = list(width = 6.5, height = 4.5)
  )
}

#' Global knitr setup for branded Quarto documents
#'
#' Configures knitr chunk options with figure dimensions, resolution, and theme settings.
#'
#' @param format Format target: `"revealjs"`, `"html"`, `"pdf"`, or `"typst"`.
#' @param theme One of [mariner_themes]. Defaults to `"baylor"`.
#' @param dpi Numeric figure resolution in dots per inch. Defaults to `300`.
#' @param fig_format Image file format: `"svg"`, `"pdf"`, or `"png"`. Defaults to `"svg"` for web/slides and `"pdf"` for LaTeX.
#' @param ... Additional chunk options passed to `knitr::opts_chunk$set()`.
#' @return Invisibly returns the previous knitr chunk options.
#' @export
#' @examples
#' \dontrun{
#' mariner_knitr_setup("revealjs", theme = "baylor")
#' }
mariner_knitr_setup <- function(format = c("revealjs", "html", "pdf", "typst"),
                            theme = "baylor",
                            dpi = 300,
                            fig_format = NULL,
                            ...) {
  if (!requireNamespace("knitr", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg knitr} is required for {.fn mariner_knitr_setup}.")
  }

  format <- rlang::arg_match(format)
  theme <- check_theme(theme)
  dims <- mariner_fig_dims(format)

  if (is.null(fig_format)) {
    fig_format <- if (format == "pdf") {
      if (capabilities("cairo")) "cairo_pdf" else "pdf"
    } else if (requireNamespace("svglite", quietly = TRUE)) {
      # svglite, not the default "svg".
      #
      # Both write SVG, but they find fonts differently: svglite reads the
      # systemfonts registry that mariner_register_fonts() populates, while the
      # cairo-backed grDevices::svg() consults fontconfig and so cannot see a
      # font that is bundled rather than installed. Registering the faces
      # without also switching the device changes nothing at all -- the figures
      # keep falling back and keep reporting zero text metrics.
      #
      # cairo_pdf() has the same blind spot, which is why the LaTeX figures
      # above are left to the device default; theme_mariner() detects that and
      # falls back deliberately rather than measuring text it cannot draw.
      "svglite"
    } else {
      "svg"
    }
  }

  opts <- knitr::opts_chunk$set(
    fig.width = dims$width,
    fig.height = dims$height,
    dpi = dpi,
    dev = fig_format,
    fig.align = "center",
    comment = "#>",
    collapse = TRUE,
    echo = FALSE,
    warning = FALSE,
    message = FALSE,
    ...
  )

  if (requireNamespace("ggplot2", quietly = TRUE)) {
    mariner_set_theme(theme = theme, format = format)
  }

  invisible(opts)
}
