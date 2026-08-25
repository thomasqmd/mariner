# Colour maths, in R.
#
# These mirror the dataviz skill's validate_palette.js, which is what produced
# the measured numbers recorded in the comments of inst/brand/baylor/_brand.yml
# -- the contrast ratios, the CVD separations, and the gamut wall at Baylor
# green's hue. They exist in R as well so the gates run in testthat: a palette
# regression fails `R CMD check` rather than waiting for someone to re-run a
# script by hand.
#
# Ported from QMDThemes, where the palette was originally derived. mariner owns
# this code now.
#
# The constants below are part of the standard, not implementation details:
# swapping the CVD simulation model would move borderline pairs and would
# require recalibrating every threshold.

# sRGB -> linear light.
srgb_to_linear <- function(c) {
  ifelse(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055)^2.4)
}

linear_to_srgb <- function(c) {
  c <- pmin(pmax(c, 0), 1)
  ifelse(c <= 0.0031308, 12.92 * c, 1.055 * c^(1 / 2.4) - 0.055)
}

hex_to_linear <- function(hex) {
  rgb <- grDevices::col2rgb(hex)[, 1] / 255
  srgb_to_linear(rgb)
}

#' Relative luminance of a colour
#'
#' WCAG relative luminance, the quantity `contrast_ratio()` is built from.
#'
#' @param hex A colour, as a hex string.
#' @return A single number in `[0, 1]`.
#' @noRd
#' @examples
#' relative_luminance("#154734")
relative_luminance <- function(hex) {
  sum(hex_to_linear(hex) * c(0.2126, 0.7152, 0.0722))
}

#' WCAG contrast ratio between two colours
#'
#' The ratio ranges from 1 (identical) to 21 (black on white). WCAG AA asks for
#' 4.5:1 for body text and 3:1 for large text and non-text elements; a chart
#' mark needs 3:1 against its surface to be seen at all.
#'
#' @param a,b Colours, as hex strings.
#' @return A single number, at least 1.
#' @noRd
#' @examples
#' # University Gold cannot carry text on a near-white slide
#' contrast_ratio("#FFB81C", "#fefefe")
#' # ...which is why the theme ships a darkened ink
#' contrast_ratio("#9b6e06", "#fefefe")
contrast_ratio <- function(a, b) {
  l <- sort(c(relative_luminance(a), relative_luminance(b)), decreasing = TRUE)
  (l[1] + 0.05) / (l[2] + 0.05)
}

# Linear sRGB -> OKLab. Björn Ottosson's matrices.
linear_to_oklab <- function(rgb) {
  l <- (0.4122214708 * rgb[1] + 0.5363325363 * rgb[2] + 0.0514459929 * rgb[3])^(1 / 3)
  m <- (0.2119034982 * rgb[1] + 0.6806995451 * rgb[2] + 0.1073969566 * rgb[3])^(1 / 3)
  s <- (0.0883024619 * rgb[1] + 0.2817188376 * rgb[2] + 0.6299787005 * rgb[3])^(1 / 3)
  c(
    0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
  )
}

#' Convert a colour to OKLab or OKLCH
#'
#' OKLCH is the space the palette gates are expressed in: `L` is perceptual
#' lightness, `C` chroma (below ~0.10 a hue reads as grey), `H` hue in degrees.
#'
#' @param hex A colour, as a hex string.
#' @return A named numeric vector.
#' @noRd
#' @examples
#' # Baylor green is both too dark and too grey to carry a data series
#' hex_to_oklch("#154734")
hex_to_oklab <- function(hex) {
  stats::setNames(linear_to_oklab(hex_to_linear(hex)), c("L", "a", "b"))
}

#' @rdname hex_to_oklab
#' @noRd
hex_to_oklch <- function(hex) {
  lab <- hex_to_oklab(hex)
  c(
    L = unname(lab[["L"]]),
    C = unname(sqrt(lab[["a"]]^2 + lab[["b"]]^2)),
    H = unname((atan2(lab[["b"]], lab[["a"]]) * 180 / pi + 360) %% 360)
  )
}

# Machado, Oliveira & Fernandes (2009) CVD transforms at severity 1.0, applied
# in linear RGB. The thresholds in the gates are calibrated to THIS model.
MACHADO <- list(
  protan = matrix(c( 0.152286,  1.052583, -0.204868,
                     0.114503,  0.786281,  0.099216,
                    -0.003882, -0.048116,  1.051998), nrow = 3, byrow = TRUE),
  deutan = matrix(c( 0.367322,  0.860646, -0.227968,
                     0.280085,  0.672501,  0.047413,
                    -0.011820,  0.042940,  0.968881), nrow = 3, byrow = TRUE),
  tritan = matrix(c( 1.255528, -0.076749, -0.178779,
                    -0.078411,  0.930809,  0.147602,
                     0.004733,  0.691367,  0.303900), nrow = 3, byrow = TRUE)
)

#' Simulate colour vision deficiency
#'
#' @param hex A colour, as a hex string.
#' @param type One of `"protan"`, `"deutan"`, `"tritan"`.
#' @return The simulated colour, as a hex string.
#' @noRd
#' @examples
#' cvd_simulate("#c1393f", "deutan")
cvd_simulate <- function(hex, type = c("protan", "deutan", "tritan")) {
  type <- rlang::arg_match(type)
  out <- linear_to_srgb(as.vector(MACHADO[[type]] %*% hex_to_linear(hex)))
  grDevices::rgb(out[1], out[2], out[3])
}

#' Perceptual distance between two colours
#'
#' Euclidean distance in OKLab, times 100 -- the units every CVD threshold in
#' this package is expressed in. `cvd_delta_e()` returns the worst (smallest)
#' separation across protanopia and deuteranopia, which is the number the
#' categorical gate is applied to.
#'
#' @param a,b Colours, as hex strings.
#' @return A single number.
#' @noRd
#' @examples
#' # Two Baylor series slots, as a full-colour reader and as a protanope
#' delta_e("#017553", "#c08802")
#' cvd_delta_e("#017553", "#c08802")
delta_e <- function(a, b) {
  sqrt(sum((hex_to_oklab(a) - hex_to_oklab(b))^2)) * 100
}

# Simulate in LINEAR light, CLAMP each channel to [0, 1], then go to OKLab.
#
# All three steps matter and the middle one is easy to get wrong. Simulation
# routinely pushes a channel out of gamut -- Baylor's gold under protanopia
# lands at blue -0.013 -- and what a real display does with that is clip it, so
# the clamp is part of the model rather than defensive tidying. Skipping it
# reads the green/gold pair at 14.4; round-tripping through an 8-bit hex instead
# (which clamps AND quantises) reads 13.9; the standard is 13.7. A pair sitting
# near the 8.0 threshold could be waved through on that difference alone.
cvd_oklab <- function(hex, type) {
  sim <- as.vector(MACHADO[[type]] %*% hex_to_linear(hex))
  linear_to_oklab(pmin(pmax(sim, 0), 1))
}

#' @rdname delta_e
#' @noRd
cvd_delta_e <- function(a, b) {
  min(vapply(
    c("protan", "deutan"),
    function(t) sqrt(sum((cvd_oklab(a, t) - cvd_oklab(b, t))^2)) * 100,
    numeric(1)
  ))
}

# ---------------------------------------------------------------------------
# Deriving one colour from another
#
# These back the semantic role tokens in R/generate.R. They exist so that a
# derived colour carries the same guarantee a hand-picked one would: the
# stylesheets never compute a text colour themselves, because SCSS can mix two
# colours but cannot tell you whether the result is still legible.
# ---------------------------------------------------------------------------

#' Blend two colours in linear light
#'
#' Interpolation in linear light rather than in gamma-encoded sRGB. Blending
#' `#000000` and `#ffffff` at `t = 0.5` gives `#bcbcbc` here and `#808080` the
#' naive way; the first is the colour that actually sits halfway in emitted
#' light, which is what a contrast calculation is about.
#'
#' @param a,b Colours, as hex strings.
#' @param t How far to move from `a` towards `b`, in `[0, 1]`.
#' @return A hex string.
#' @noRd
#' @examples
#' mix_linear("#154734", "#fefefe", 0.5)
mix_linear <- function(a, b, t) {
  out <- linear_to_srgb((1 - t) * hex_to_linear(a) + t * hex_to_linear(b))
  # Lower case to match the hand-written brand files. Generated artefacts are
  # compared byte for byte, so "#303E4E" and "#303e4e" are a drift failure.
  tolower(grDevices::rgb(out[1], out[2], out[3]))
}

#' Pick a legible ink for a background
#'
#' Returns whichever candidate has the most contrast against `bg`, then, if it
#' still falls short of `target`, pushes it towards black or white -- whichever
#' direction it was already going -- until it clears.
#'
#' The second step is not decoration. The personal theme's teal accent reaches
#' 4.499:1 against its own near-black ink, which is a fail by 0.001, and no
#' choice between two candidates can fix that. Picking the best available is a
#' preference; clearing a threshold is a guarantee, and only the second one is
#' worth generating a token for.
#'
#' @param bg The background, as a hex string.
#' @param candidates Candidate text colours, as hex strings.
#' @param target Minimum contrast ratio to guarantee.
#' @return A hex string, not necessarily one of `candidates`.
#' @noRd
#' @examples
#' # White reads on Baylor green; on University Gold it does not
#' best_ink("#154734", c("#fefefe", "#222222"))
#' best_ink("#FFB81C", c("#fefefe", "#222222"))
best_ink <- function(bg, candidates, target = 4.5) {
  best <- candidates[[which.max(vapply(candidates, contrast_ratio, numeric(1), b = bg))]]
  if (contrast_ratio(best, bg) >= target) return(best)
  # Short of the target: keep going the way it was already headed. A light ink
  # gets lighter, a dark one darker -- moving it the other way would cross the
  # background and get worse before it got better.
  extreme <- if (relative_luminance(best) > relative_luminance(bg)) "#ffffff" else "#000000"
  darken_to_contrast(best, extreme, bg, target)
}

#' Darken a colour until it clears a contrast target
#'
#' Walks `hex` towards `toward` in linear light until it reaches `target`
#' against `bg`, and returns the *first* colour that does -- so the result is
#' the least-changed colour that passes rather than the darkest one available.
#'
#' Used for link hover states. Every source stylesheet this package replaces
#' hovers by *lightening* the link (`lighten($primary, 10%)`), which lowers
#' contrast against a light page at exactly the moment the user is pointing at
#' it. Darkening raises it, and the search makes the amount a consequence of the
#' target rather than a number someone picked.
#'
#' @param hex The starting colour.
#' @param toward The colour to move towards, usually the theme's ink.
#' @param bg The background the target is measured against.
#' @param target Minimum contrast ratio.
#' @param steps How finely to search.
#' @return A hex string. If `target` is unreachable, `toward` itself.
#' @noRd
#' @examples
#' darken_to_contrast("#3a6ea5", "#222222", "#ffffff", 7)
darken_to_contrast <- function(hex, toward, bg, target, steps = 100) {
  for (i in seq.int(0, steps)) {
    candidate <- mix_linear(hex, toward, i / steps)
    if (contrast_ratio(candidate, bg) >= target) return(candidate)
  }
  toward
}
