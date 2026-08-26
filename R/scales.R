# ggplot2 scale functions tied to _brand.yml palettes.

#' Discrete colour and fill scales for mariner
#'
#' Categories with no order. Eight colours before the palette interpolates.
#'
#' @param reverse Logical; if `TRUE`, reverse the colours.
#' @param ... Further arguments for [ggplot2::discrete_scale()].
#' @return A ggplot2 discrete scale object.
#' @export
#' @rdname scale_mariner_d
#' @examples
#' library(ggplot2)
#' ggplot(mpg, aes(displ, hwy, colour = class)) +
#'   geom_point() +
#'   scale_colour_mariner_d()
scale_colour_mariner_d <- function(reverse = FALSE, ...) {
  ggplot2::discrete_scale(
    aesthetics = "colour",
    palette = mariner_pal(family = "discrete", reverse = reverse),
    ...
  )
}

#' @export
#' @rdname scale_mariner_d
scale_color_mariner_d <- scale_colour_mariner_d

#' @export
#' @rdname scale_mariner_d
scale_fill_mariner_d <- function(reverse = FALSE, ...) {
  ggplot2::discrete_scale(
    aesthetics = "fill",
    palette = mariner_pal(family = "discrete", reverse = reverse),
    ...
  )
}

#' Continuous colour and fill scales for mariner
#'
#' Magnitude on one hue, as a smooth gradient.
#'
#' @param reverse Logical; if `TRUE`, reverse the gradient.
#' @param ... Further arguments for [ggplot2::scale_colour_gradientn()] or
#'   [ggplot2::scale_fill_gradientn()].
#' @return A ggplot2 continuous scale object.
#' @export
#' @rdname scale_mariner_c
#' @examples
#' library(ggplot2)
#' ggplot(mpg, aes(displ, hwy, colour = cty)) +
#'   geom_point() +
#'   scale_colour_mariner_c()
scale_colour_mariner_c <- function(reverse = FALSE, ...) {
  ggplot2::scale_colour_gradientn(
    colours = mariner_pal(family = "sequential", reverse = reverse)(100),
    ...
  )
}

#' @export
#' @rdname scale_mariner_c
scale_color_mariner_c <- scale_colour_mariner_c

#' @export
#' @rdname scale_mariner_c
scale_fill_mariner_c <- function(reverse = FALSE, ...) {
  ggplot2::scale_fill_gradientn(
    colours = mariner_pal(family = "sequential", reverse = reverse)(100),
    ...
  )
}

#' Ordinal colour and fill scales for mariner
#'
#' A few ranked levels. The palette ramps rather than contrasts, so the colours
#' carry the order.
#'
#' @param reverse Logical; if `TRUE`, reverse the ramp.
#' @param ... Further arguments for [ggplot2::discrete_scale()].
#' @return A ggplot2 discrete scale object for ordered categories.
#' @export
#' @rdname scale_mariner_o
#' @examples
#' library(ggplot2)
#' mpg$size <- cut(mpg$displ, 3, labels = c("Small", "Medium", "Large"))
#' ggplot(mpg, aes(hwy, fill = size)) +
#'   geom_histogram(bins = 20) +
#'   scale_fill_mariner_o()
scale_colour_mariner_o <- function(reverse = FALSE, ...) {
  ggplot2::discrete_scale(
    aesthetics = "colour",
    palette = mariner_pal(family = "ordinal", reverse = reverse),
    ...
  )
}

#' @export
#' @rdname scale_mariner_o
scale_color_mariner_o <- scale_colour_mariner_o

#' @export
#' @rdname scale_mariner_o
scale_fill_mariner_o <- function(reverse = FALSE, ...) {
  ggplot2::discrete_scale(
    aesthetics = "fill",
    palette = mariner_pal(family = "ordinal", reverse = reverse),
    ...
  )
}

#' Diverging colour and fill scales for mariner
#'
#' A signed quantity, where the neutral step means no difference. Set `limits`
#' symmetrically, or the neutral step lands wherever the data straddles.
#'
#' @param reverse Logical; if `TRUE`, reverse the gradient.
#' @param ... Further arguments for [ggplot2::scale_colour_gradientn()] or
#'   [ggplot2::scale_fill_gradientn()].
#' @return A ggplot2 diverging scale object.
#' @export
#' @rdname scale_mariner_div
#' @examples
#' library(ggplot2)
#' mpg$delta <- mpg$hwy - mean(mpg$hwy)
#' lim <- max(abs(mpg$delta))
#' ggplot(mpg, aes(displ, hwy, colour = delta)) +
#'   geom_point() +
#'   scale_colour_mariner_div(limits = c(-lim, lim))
scale_colour_mariner_div <- function(reverse = FALSE, ...) {
  ggplot2::scale_colour_gradientn(
    colours = mariner_pal(family = "diverging", reverse = reverse)(101),
    ...
  )
}

#' @export
#' @rdname scale_mariner_div
scale_color_mariner_div <- scale_colour_mariner_div

#' @export
#' @rdname scale_mariner_div
scale_fill_mariner_div <- function(reverse = FALSE, ...) {
  ggplot2::scale_fill_gradientn(
    colours = mariner_pal(family = "diverging", reverse = reverse)(101),
    ...
  )
}

#' Binned colour and fill scales for mariner
#'
#' The sequential palette cut into steps. Use it when a reader has to name the
#' band a point falls in.
#'
#' @param reverse Logical; if `TRUE`, reverse the steps.
#' @param ... Further arguments for [ggplot2::scale_colour_stepsn()] or
#'   [ggplot2::scale_fill_stepsn()].
#' @return A ggplot2 binned scale object.
#' @export
#' @rdname scale_mariner_b
#' @examples
#' library(ggplot2)
#' ggplot(mpg, aes(displ, hwy, colour = cty)) +
#'   geom_point() +
#'   scale_colour_mariner_b()
scale_colour_mariner_b <- function(reverse = FALSE, ...) {
  ggplot2::scale_colour_stepsn(
    colours = mariner_pal(family = "sequential", reverse = reverse)(100),
    ...
  )
}

#' @export
#' @rdname scale_mariner_b
scale_color_mariner_b <- scale_colour_mariner_b

#' @export
#' @rdname scale_mariner_b
scale_fill_mariner_b <- function(reverse = FALSE, ...) {
  ggplot2::scale_fill_stepsn(
    colours = mariner_pal(family = "sequential", reverse = reverse)(100),
    ...
  )
}
