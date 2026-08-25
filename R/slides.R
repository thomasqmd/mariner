# Slide geometry.
#
# A reveal.js deck is measured in reveal's OWN coordinate space -- the slide is
# $width x $height whatever the display is, and reveal scales that box into the
# window at render time. Every number the deck is built from therefore has to be
# stated against that box: the figure sizes knitr draws at, the CSS caps that
# stop a figure running off the bottom, the corner logo, the footer, the slide
# counter, and the `width:`/`height:` pair Quarto puts in the YAML before any
# stylesheet exists.
#
# Those numbers used to be written down in four places -- mariner_fig_dims(), the
# reveal partial, _extension.yml, and a comment in every deck -- which is what
# plan.md's TODO was about. They are all derived from the constants below now,
# and the three artefacts that need them are GENERATED from here:
#
#   _qmd-tokens.scss   $qmd-slide-* , which qmd-revealjs.scss builds its rules on
#   _extension.yml     width/height/margin, and the knitr figure defaults
#   mariner_fig_dims()     the same figure size, for a deck that sets it in R
#
# so a change here reaches all of them and cannot reach only some.
#
# 1600x900 is 16:9, which is the shape of the room's display. reveal fits the
# slide inside the viewport at a single scale, so an aspect that does not match
# the screen is letterboxed -- the previous 3:2 box left a dead band down either
# side of a 16:9 display.
#
# Type is set in px and does NOT grow with the box, so a larger coordinate space
# is smaller type relative to the slide and more fits. That is a lever, not a
# side effect, which is why the root size moves deliberately when the box does:
# 32px at 700 tall scaled by the height the box gained is the one value that is
# neutral on vertical overflow, so a slide that fitted before still fits.

MARINER_SLIDE <- list(
  # The box, in reveal's coordinate space.
  width = 1600,
  height = 900,

  # Body type, and the size every `em` in the deck is ultimately measured
  # against. Scaling by the WIDTH instead (32 -> 48.8) would have held type at
  # the same share of the slide and cost more vertical room than the box gained;
  # leaving it at 32 would have shrunk every word on screen against a deck that
  # already reads correctly.
  root_font_size = 36,

  # reveal's own margin: the share of the window it will not scale the slide
  # into. Coupled to the slide counter, which sits in that band -- see
  # `margin_min` in mariner_slide_geometry(), which is asserted in the test suite
  # rather than left as a comment.
  margin = 0.08,

  # What the heading bar and the slide's padding take off the top before a
  # figure starts, in ROOT FONT SIZES rather than in px. The bar is one line of
  # `h2` plus its margins and those are `em`, so the allowance follows the type
  # and not the box: 5 x root is the 160px measured against the old 32px root.
  chrome_lines = 5,

  # A `{.smaller}` slide carries prose or a table around its figure, so the
  # figure gets this share of the height a bare slide would give it.
  smaller_ratio = 0.82,

  # What a tabset spends before its panel starts: the pill row (pills at 0.8em
  # plus their padding, and the gap beneath the row) and the caption Quarto puts
  # on the figure or table inside the panel. In root font sizes, for the same
  # reason chrome_lines is.
  #
  # CALIBRATED, not derived, and the only number here that is. The pill row and
  # the caption come to about 2.6 root sizes on paper, and 3.75 was set from
  # that with a little to spare -- but a rendered deck put a scrollbar on the
  # tabset slides anyway, so something in the band between the heading bar and
  # the panel is not in that sum. 5 is what clears it with room left. If a deck
  # ever overflows a tabset slide again, this is the number to move.
  tabset_lines = 5,

  # How much narrower than the slide a widget is drawn.
  #
  # A widget at exactly $slide-width has zero tolerance: reveal wraps a slide
  # whose content overflows in a scroll container, and a vertical scrollbar
  # takes width away from the content box, which then makes an exactly-full-width
  # plot overflow HORIZONTALLY as well. That is the second scrollbar on the
  # tabset slides -- the horizontal one is a consequence of the vertical one, not
  # a separate problem.
  #
  # 3% is twice the furniture inset below, so a widget sits inside the same
  # margin the corner logo does.
  widget_inset_frac = 0.03,

  # A table needs more of that tolerance than a plot does, which is why this is
  # a second number rather than the same one.
  #
  # A plot is a fixed-size canvas: give it a width and it draws to exactly that.
  # A table is not -- it carries a scroll wrapper, cell borders, and (with a
  # filter row) an input per column, all of which are laid out AROUND the width
  # it was given rather than inside it. `.reveal table` also sets `width: auto`
  # so columns size to their contents, and the deck's `nowrap` means none of them
  # can give way. At 3% the plots sit correctly and a nine-column table still
  # runs a little past the edge; 5% clears it.
  #
  # Both of these are tolerances calibrated against a rendered deck, not
  # quantities computed from anything.
  table_inset_frac = 0.05,

  # Deck furniture -- the corner logo, the footer line and the slide counter.
  # These are the only three things on screen reveal does not scale: Quarto puts
  # them outside `.slides`, fixed against the viewport, so they are drawn at
  # whatever px the stylesheet gives them on any display. qmd-revealjs.scss does
  # reveal's arithmetic again to put them back on the slide's corners, and these
  # are the sizes they should measure ON a 1600x900 slide.
  #
  # The three type-ish ones hang off the root font size, because what makes
  # furniture read as furniture is its size next to the words beside it. The
  # insets hang off the box, because what they are is a distance from a corner.
  logo_lines = 1.3,
  footer_lines = 0.55,
  number_lines = 0.5,
  number_pad_lines = 0.14,
  number_gap_frac = 0.007,
  inset_x_frac = 0.015,
  inset_y_frac = 0.016,

  # Figure sizes are inches (knitr) against pixels (reveal). 100px to the inch
  # keeps the conversion readable in both directions.
  px_per_in = 100
)

# Trailing zeros are noise in a stylesheet, and the drift test compares BYTES --
# so "590.4px" has to come out the same way every time it is generated.
num_str <- function(x) {
  format(round(x, 4), trim = TRUE, scientific = FALSE, drop0trailing = TRUE)
}

#' Slide geometry, and everything derived from it
#'
#' The reveal.js coordinate space a deck is measured in, and the sizes the
#' stylesheet, the extension YAML and [mariner_fig_dims()] are all built from. Every
#' value is derived from the constants in `MARINER_SLIDE`, so the three artefacts
#' cannot disagree about how big a slide is.
#'
#' @return A named list of numbers. Lengths are pixels in reveal's own
#'   coordinate space unless noted; `margin` is a fraction of the window.
#' @noRd
#' @examples
#' geom <- mariner_slide_geometry()
#' geom$width
#' geom$figure_height
mariner_slide_geometry <- function() {
  g <- MARINER_SLIDE
  root <- g$root_font_size

  chrome <- root * g$chrome_lines
  figure_height <- g$height - chrome

  number_size <- root * g$number_lines
  number_pad <- root * g$number_pad_lines
  number_gap <- g$height * g$number_gap_frac
  # What the counter occupies above the slide: its own line, the pill's padding
  # on both sides, and the gap between the pill and the slide's top edge.
  number_band <- number_size + 2 * number_pad + number_gap

  # The counter is the one thing in the deck that costs margin. It sits in the
  # gutter -- the band of window left over once the slide has been scaled into
  # it -- so the gutter has to be at least as tall as the counter's band:
  #
  #     margin/2 * H  >=  number_band * (1 - margin) * H / height
  #
  # A window at or wider than 16:9 binds on height, which is the worst case; a
  # taller one binds on width and the gutter only grows. Solving for margin:
  ratio <- 2 * number_band / g$height
  margin_min <- ratio / (1 + ratio)

  list(
    width = g$width,
    height = g$height,
    margin = g$margin,
    margin_min = margin_min,
    root_font_size = root,
    chrome = chrome,
    figure_height = figure_height,
    figure_height_smaller = figure_height * g$smaller_ratio,
    tabset_height = figure_height - root * g$tabset_lines,
    # What an htmlwidget should be BUILT at. Not the slide width -- see
    # widget_inset_frac. A widget given no width at all is worse still:
    # htmlwidgets falls back to `fig.width * dpi`, which at 300dpi is a canvas
    # several times the slide.
    widget_width = g$width * (1 - g$widget_inset_frac),
    # The same idea for a table, which lays its chrome out around the width it
    # is given rather than inside it. See table_inset_frac.
    table_width = g$width * (1 - g$table_inset_frac),
    logo_height = root * g$logo_lines,
    footer_size = root * g$footer_lines,
    number_size = number_size,
    number_pad = number_pad,
    number_gap = number_gap,
    number_band = number_band,
    inset_x = g$width * g$inset_x_frac,
    inset_y = g$height * g$inset_y_frac,
    # Inches, for knitr. A figure on a slide of its own is drawn at the full
    # width and at what is left of the height under the heading bar, so it binds
    # on width and fills the slide.
    fig_width_in = g$width / g$px_per_in,
    fig_height_in = figure_height / g$px_per_in
  )
}

# The $qmd-slide-* block of _qmd-tokens.scss, as name/value pairs.
#
# Theme-independent -- a slide is the same size in both themes -- but emitted
# into the per-theme token file all the same, because that is the ONE file a
# partial's defaults are allowed to reference. Defaults are assembled in reverse
# `theme:` order and _qmd-tokens.scss is listed last, so its variables are the
# only ones qmd-revealjs.scss can build on. See the note at the top of R/scss.R.
slide_scss_tokens <- function() {
  geom <- mariner_slide_geometry()
  px <- function(x) paste0(num_str(x), "px")
  c(
    "slide-width"                 = px(geom$width),
    "slide-height"                = px(geom$height),
    "slide-margin"                = num_str(geom$margin),
    "slide-root-font-size"        = px(geom$root_font_size),
    "slide-chrome"                = px(geom$chrome),
    "slide-figure-height"         = px(geom$figure_height),
    "slide-figure-height-smaller" = px(geom$figure_height_smaller),
    "slide-tabset-height"         = px(geom$tabset_height),
    "slide-logo-height"           = px(geom$logo_height),
    "slide-footer-size"           = px(geom$footer_size),
    "slide-number-size"           = px(geom$number_size),
    "slide-number-pad"            = px(geom$number_pad),
    "slide-number-band"           = px(geom$number_band),
    "slide-inset-x"               = px(geom$inset_x),
    "slide-inset-y"               = px(geom$inset_y)
  )
}
