# ggplot2 theme matching document brand and typography.

#' Branded ggplot2 theme for mariner
#'
#' Provides a consistent ggplot2 theme aligned with the brand typography,
#' background, rule grids, and primary colors of the document theme.
#'
#' @param theme Theme name. Defaults to the built-in mariner theme.
#' @param format One of [mariner_formats].
#' @param base_size Base font size in points. Defaults to `11`, matching the
#'   report body text set in `_extension.yml`.
#' @param base_family Font family name. Defaults to `"Atkinson Hyperlegible Next"`.
#' @param ... Additional arguments passed to [ggplot2::theme()].
#' @return A ggplot2 theme object.
#' @export
#' @examples
#' library(ggplot2)
#' ggplot(mpg, aes(displ, hwy, colour = class)) +
#'   geom_point() +
#'   scale_colour_mariner_d() +
#'   theme_mariner()
theme_mariner <- function(theme = mariner_themes,
                      format = mariner_formats,
                      base_size = 11,
                      base_family = NULL,
                      ...) {
  theme <- check_theme(theme)
  check_format(format)

  if (is.null(base_family)) {
    # The bundled face, once mariner_register_fonts() has made it reachable.
    # This used to be "" for pdf, which meant a report's FIGURES silently opted
    # out of the theme's own typeface -- they were drawn in the device default
    # while the body text around them was Atkinson, and nothing said so.
    #
    # The guard is not belt-and-braces. If the face cannot be resolved the
    # device does not merely substitute: it reports zero text metrics and lays
    # the panel out around labels it believes have no size, and base pdf() --
    # which is what knitr falls back to on a build without cairo -- refuses
    # outright with "invalid font type" and takes the render down.
    #
    # `format` is passed because the answer DEPENDS ON THE DEVICE: the
    # systemfonts registry that mariner_register_fonts() populates is read by
    # svglite and ragg, and not by the cairo_pdf()/pdf() pair the LaTeX pdf path
    # draws through. See mariner_fonts_available().
    base_family <- if (mariner_fonts_available(format)) "Atkinson Hyperlegible Next" else ""
  }

  cols <- mariner_colors(theme)
  bg <- cols[["background"]]
  ink <- cols[["ink"]]
  ink_sec <- cols[["ink-secondary"]]
  ink_muted <- cols[["ink-muted"]]
  grid <- cols[["rule-grid"]]
  axis_col <- cols[["rule-axis"]]
  prim <- cols[["primary"]]

  ggplot2::theme_minimal(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = bg, colour = NA),
      panel.background = ggplot2::element_rect(fill = bg, colour = NA),
      panel.grid.major = ggplot2::element_line(colour = grid, linewidth = 0.4),
      panel.grid.minor = ggplot2::element_blank(),
      axis.line = ggplot2::element_line(colour = axis_col, linewidth = 0.5),
      axis.ticks = ggplot2::element_line(colour = axis_col, linewidth = 0.5),
      axis.text = ggplot2::element_text(colour = ink_muted, size = ggplot2::rel(0.85)),
      axis.title = ggplot2::element_text(colour = ink, size = ggplot2::rel(0.95), face = "bold"),
      plot.title = ggplot2::element_text(
        colour = prim, size = ggplot2::rel(1.2), face = "bold",
        margin = ggplot2::margin(b = 6)
      ),
      plot.subtitle = ggplot2::element_text(
        colour = ink_sec, size = ggplot2::rel(0.95),
        margin = ggplot2::margin(b = 10)
      ),
      plot.caption = ggplot2::element_text(
        colour = ink_muted, size = ggplot2::rel(0.75), hjust = 1,
        margin = ggplot2::margin(t = 8)
      ),
      legend.background = ggplot2::element_rect(fill = bg, colour = NA),
      legend.key = ggplot2::element_rect(fill = bg, colour = NA),
      legend.text = ggplot2::element_text(colour = ink, size = ggplot2::rel(0.85)),
      legend.title = ggplot2::element_text(colour = ink, size = ggplot2::rel(0.9), face = "bold"),
      strip.background = ggplot2::element_rect(fill = grid, colour = NA),
      strip.text = ggplot2::element_text(
        colour = ink, size = ggplot2::rel(0.9), face = "bold",
        margin = ggplot2::margin(4, 4, 4, 4)
      ),
      ...
    )
}

#' Set global ggplot2 theme and scale defaults
#'
#' Sets [theme_mariner()] as the global default theme and configures default discrete and
#' continuous scales so subsequent plots use the brand palette automatically.
#'
#' @param theme Theme name. Defaults to the built-in mariner theme.
#' @param format One of [mariner_formats].
#' @param ... Arguments passed to [theme_mariner()].
#' @return Invisibly returns the previous theme.
#' @export
#' @examples
#' mariner_set_theme()
mariner_set_theme <- function(theme = mariner_themes,
                          format = mariner_formats,
                          ...) {
  theme <- check_theme(theme)
  check_format(format)

  th <- theme_mariner(theme = theme, format = format, ...)
  old_theme <- ggplot2::theme_set(th)

  options(
    ggplot2.discrete.colour = function(...) scale_colour_mariner_d(...),
    ggplot2.discrete.fill = function(...) scale_fill_mariner_d(...),
    ggplot2.continuous.colour = function(...) scale_colour_mariner_c(...),
    ggplot2.continuous.fill = function(...) scale_fill_mariner_c(...)
  )

  invisible(old_theme)
}

# mariner_plotly_theme() was removed with the html and revealjs formats.
#
# A plotly figure is an htmlwidget: it needs a browser to draw, and a pdf report
# has no browser. Keeping a themed plotly wrapper in a pdf-only package would
# export a function that cannot be used in the only format the package targets.
# It is in the git history if an interactive format ever comes back.
