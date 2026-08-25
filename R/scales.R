# ggplot2 scale functions tied to _brand.yml palettes.

#' Discrete colour and fill scales for mariner
#'
#' @param theme One of [mariner_themes]. Defaults to `"baylor"`.
#' @param reverse Logical; if `TRUE`, reverses the color vector.
#' @param ... Arguments passed to [ggplot2::discrete_scale()].
#' @return A ggplot2 discrete scale object.
#' @export
#' @rdname scale_mariner_d
#' @examples
#' \dontrun{
#' library(ggplot2)
#' ggplot(mpg, aes(displ, hwy, colour = class)) +
#'   geom_point() +
#'   scale_colour_mariner_d("baylor")
#' }
scale_colour_mariner_d <- function(theme = "baylor", reverse = FALSE, ...) {
  ggplot2::discrete_scale(
    aesthetics = "colour",
    palette = mariner_pal(theme = theme, family = "discrete", reverse = reverse),
    ...
  )
}

#' @export
#' @rdname scale_mariner_d
scale_color_mariner_d <- scale_colour_mariner_d

#' @export
#' @rdname scale_mariner_d
scale_fill_mariner_d <- function(theme = "baylor", reverse = FALSE, ...) {
  ggplot2::discrete_scale(
    aesthetics = "fill",
    palette = mariner_pal(theme = theme, family = "discrete", reverse = reverse),
    ...
  )
}

#' Continuous colour and fill scales for mariner
#'
#' @param theme One of [mariner_themes]. Defaults to `"baylor"`.
#' @param reverse Logical; if `TRUE`, reverses the color gradient.
#' @param ... Arguments passed to [ggplot2::scale_colour_gradientn()] or [ggplot2::scale_fill_gradientn()].
#' @return A ggplot2 continuous scale object.
#' @export
#' @rdname scale_mariner_c
scale_colour_mariner_c <- function(theme = "baylor", reverse = FALSE, ...) {
  ggplot2::scale_colour_gradientn(
    colours = mariner_pal(theme = theme, family = "sequential", reverse = reverse)(100),
    ...
  )
}

#' @export
#' @rdname scale_mariner_c
scale_color_mariner_c <- scale_colour_mariner_c

#' @export
#' @rdname scale_mariner_c
scale_fill_mariner_c <- function(theme = "baylor", reverse = FALSE, ...) {
  ggplot2::scale_fill_gradientn(
    colours = mariner_pal(theme = theme, family = "sequential", reverse = reverse)(100),
    ...
  )
}

#' Ordinal colour and fill scales for mariner
#'
#' @param theme One of [mariner_themes]. Defaults to `"baylor"`.
#' @param reverse Logical; if `TRUE`, reverses the color ramp.
#' @param ... Arguments passed to [ggplot2::discrete_scale()].
#' @return A ggplot2 discrete scale object tailored for ordered categories.
#' @export
#' @rdname scale_mariner_o
scale_colour_mariner_o <- function(theme = "baylor", reverse = FALSE, ...) {
  ggplot2::discrete_scale(
    aesthetics = "colour",
    palette = mariner_pal(theme = theme, family = "ordinal", reverse = reverse),
    ...
  )
}

#' @export
#' @rdname scale_mariner_o
scale_color_mariner_o <- scale_colour_mariner_o

#' @export
#' @rdname scale_mariner_o
scale_fill_mariner_o <- function(theme = "baylor", reverse = FALSE, ...) {
  ggplot2::discrete_scale(
    aesthetics = "fill",
    palette = mariner_pal(theme = theme, family = "ordinal", reverse = reverse),
    ...
  )
}

#' Diverging colour and fill scales for mariner
#'
#' @param theme One of [mariner_themes]. Defaults to `"baylor"`.
#' @param reverse Logical; if `TRUE`, reverses the color gradient.
#' @param ... Arguments passed to [ggplot2::scale_colour_gradientn()] or [ggplot2::scale_fill_gradientn()].
#' @return A ggplot2 diverging scale object.
#' @export
#' @rdname scale_mariner_div
scale_colour_mariner_div <- function(theme = "baylor", reverse = FALSE, ...) {
  ggplot2::scale_colour_gradientn(
    colours = mariner_pal(theme = theme, family = "diverging", reverse = reverse)(101),
    ...
  )
}

#' @export
#' @rdname scale_mariner_div
scale_color_mariner_div <- scale_colour_mariner_div

#' @export
#' @rdname scale_mariner_div
scale_fill_mariner_div <- function(theme = "baylor", reverse = FALSE, ...) {
  ggplot2::scale_fill_gradientn(
    colours = mariner_pal(theme = theme, family = "diverging", reverse = reverse)(101),
    ...
  )
}

#' Binned colour and fill scales for mariner
#'
#' @param theme One of [mariner_themes]. Defaults to `"baylor"`.
#' @param reverse Logical; if `TRUE`, reverses the color steps.
#' @param ... Arguments passed to [ggplot2::scale_colour_stepsn()] or [ggplot2::scale_fill_stepsn()].
#' @return A ggplot2 binned scale object.
#' @export
#' @rdname scale_mariner_b
scale_colour_mariner_b <- function(theme = "baylor", reverse = FALSE, ...) {
  ggplot2::scale_colour_stepsn(
    colours = mariner_pal(theme = theme, family = "sequential", reverse = reverse)(100),
    ...
  )
}

#' @export
#' @rdname scale_mariner_b
scale_color_mariner_b <- scale_colour_mariner_b

#' @export
#' @rdname scale_mariner_b
scale_fill_mariner_b <- function(theme = "baylor", reverse = FALSE, ...) {
  ggplot2::scale_fill_stepsn(
    colours = mariner_pal(theme = theme, family = "sequential", reverse = reverse)(100),
    ...
  )
}
