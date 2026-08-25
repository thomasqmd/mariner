# knitr chunk setup and figure dimension helpers.

#' Figure dimensions for a branded report
#'
#' The drawing area a figure gets on the page: the geometry in `_extension.yml`
#' (US Letter, 1in left and right, 0.75in top and bottom) leaves 6.5in of text
#' width, and 4.5in tall is a little under the 3:2 that leaves room for a
#' caption and surrounding prose.
#'
#' @param format One of [mariner_formats].
#' @return A named list with numeric `width` and `height` in inches.
#' @export
#' @examples
#' mariner_fig_dims("pdf")
mariner_fig_dims <- function(format = mariner_formats) {
  check_format(format)
  list(width = 6.5, height = 4.5)
}

#' Global knitr setup for branded Quarto documents
#'
#' Configures knitr chunk options with figure dimensions, resolution, and theme
#' settings. Call it in the setup chunk of a report.
#'
#' @param format One of [mariner_formats].
#' @param theme One of [mariner_themes]. Defaults to `"baylor"`.
#' @param dpi Numeric figure resolution in dots per inch. Defaults to `300`.
#' @param fig_format Image device. Defaults to `"cairo_pdf"` where the build has
#'   cairo, and base `"pdf"` where it does not.
#' @param ... Additional chunk options passed to `knitr::opts_chunk$set()`.
#' @return Invisibly returns the previous knitr chunk options.
#' @export
#' @examples
#' \dontrun{
#' mariner_knitr_setup("pdf", theme = "baylor")
#' }
mariner_knitr_setup <- function(format = mariner_formats,
                            theme = "baylor",
                            dpi = 300,
                            fig_format = NULL,
                            ...) {
  if (!requireNamespace("knitr", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg knitr} is required for {.fn mariner_knitr_setup}.")
  }

  check_format(format)
  theme <- check_theme(theme)
  dims <- mariner_fig_dims(format)

  if (is.null(fig_format)) {
    # cairo_pdf() where it exists: a vector device, so a figure stays sharp at
    # any zoom, and it embeds the face it draws with.
    #
    # Neither it nor base pdf() reads the systemfonts registry that
    # mariner_register_fonts() populates -- both consult fontconfig -- so a
    # bundled-but-not-installed face is invisible to them. That is what
    # mariner_install_fonts() is for, and what theme_mariner()'s base_family
    # guard falls back from. Asking for a face the device cannot measure does
    # not substitute: it returns zero text metrics and collapses the panel
    # layout, and base pdf() refuses outright with "invalid font type".
    fig_format <- if (capabilities("cairo")) "cairo_pdf" else "pdf"
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
