# Reading the source of truth.
#
# Everything downstream -- the LaTeX preamble, the R
# palettes -- comes through here, so there is exactly one parser and one place
# that knows the shape of a _brand.yml.
#
# Ported from QMDThemes. mariner owns this code now: there is no sync back.

#' Read the theme's brand definition
#'
#' Parses the theme's `_brand.yml`, the single file in this package where a
#' colour is written down. Every other colour artefact -- the LaTeX preamble
#' and the
#' ggplot2 palettes -- is generated or read from it.
#'
#' @param theme One of [mariner_themes].
#' @return A list, as parsed from the YAML.
#' @noRd
#' @examples
#' b <- read_brand("mariner")
#' b$color$palette[["mariner-green"]]
read_brand <- function(theme = mariner_themes) {
  theme <- check_theme(theme)
  yaml::read_yaml(mariner_path("brand", theme, "_brand.yml"))
}

# Pull one prefixed family (series / seq / ord / div) in file order.
brand_family <- function(brand, prefix) {
  pal <- brand$color$palette
  keys <- grep(paste0("^", prefix, "-\\d+"), names(pal), value = TRUE)
  # Numeric order, not lexicographic: "series-10" must not sort before
  # "series-2" if the palette ever grows past nine slots.
  keys <- keys[order(as.integer(sub(paste0("^", prefix, "-(\\d+).*$"), "\\1", keys)))]
  # "series-1-green" -> "green"; "seq-1" -> "1"
  labels <- sub(paste0("^", prefix, "-(\\d+)-?"), "", keys)
  labels[labels == ""] <- sub(paste0("^", prefix, "-"), "", keys[labels == ""])
  # unlist() of nothing is NULL, and setNames() on NULL is an error rather than
  # an empty vector -- so a theme that omits a family would take down every
  # caller instead of returning no colours.
  values <- unlist(pal[keys], use.names = FALSE)
  stats::setNames(values %||% character(), labels)
}

# Every colour token a generator emits, flattened to name -> hex, in a fixed
# order so generated files are byte-stable across runs (the drift test compares
# bytes).
brand_tokens <- function(brand) {
  pal <- brand$color$palette
  hex <- vapply(pal, function(v) if (is.character(v) && grepl("^#", v)) v else NA_character_,
                character(1))
  tokens <- pal[!is.na(hex)]
  c(
    list(background = brand$color$background, foreground = brand$color$foreground),
    tokens
  )
}

# The brand's display name. Quarto's spec allows `meta.name` to be either a bare
# string or a short/full pair, so both shapes are accepted rather than assuming
# the one this theme happens to use.
brand_name <- function(brand, which = c("full", "short")) {
  which <- match.arg(which)
  nm <- brand$meta$name
  if (is.character(nm)) return(nm)
  nm[[which]] %||% nm[["short"]] %||% nm[["full"]]
}

`%||%` <- function(x, y) if (is.null(x)) y else x

# A _brand.yml may name a colour either literally, as a hex string, or by
# palette key ("mariner-green"). `color.primary` uses the second form.
brand_resolve <- function(brand, value) {
  pal <- brand$color$palette
  if (!is.null(pal[[value]])) pal[[value]] else value
}

# The SEMANTIC layer.
#
# The stylesheets are written against these names rather than against palette
# keys like `mariner-green`, which is what would let a second theme drop in
# without a fork of every partial.
#
# Four of them are COMPUTED rather than looked up, and that is the point:
#
#   on-primary / on-secondary  the ink that goes ON that colour. Every source
#     stylesheet hard-codes a near-white on the heading bar, which is right for
#     mariner green and illegible on gold -- 1.7:1. Computing it means a theme
#     whose primary is light gets dark text without anyone remembering to.
#   accent-ink  the secondary, darkened until it can carry small text (4.5:1).
#     Mariner's `gold-ink` is this done by hand for one theme; a theme with a
#     lighter secondary would fail the same way if `.term` and `.citation` used
#     it raw. `accent-rule` is the same idea at the 3:1 a border needs, and both
#     return the secondary unchanged when it already passes.
#
# There is deliberately no `link-hover` here. The theme's links already clear
# AAA, so a derived hover came back equal to the link itself; hover is a wash
# and a thicker underline in _qmd-utilities.scss instead, which is visible and
# cannot cost contrast. The source stylesheets all `lighten()` on hover, which
# lowers it at exactly the moment the user is pointing at the link.
brand_roles <- function(brand) {
  bg <- brand$color$background
  ink <- brand$color$foreground
  primary <- brand_resolve(brand, brand$color$primary)
  secondary <- brand_resolve(brand, brand$color$secondary)
  link <- brand_resolve(brand, brand$typography$link$color)
  series <- brand_family(brand, "series")
  c(
    list(
      primary = primary,
      secondary = secondary,
      link = link,
      `accent-ink` = darken_to_contrast(secondary, ink, bg, 4.5),
      `accent-rule` = darken_to_contrast(secondary, ink, bg, 3),
      `on-primary` = best_ink(primary, c(bg, ink)),
      `on-secondary` = best_ink(secondary, c(bg, ink))
    ),
    # Positional aliases. `$qmd-series-1` is the deck's first series whatever
    # the theme; `$qmd-series-1-green` says which hue that happens to be here.
    stats::setNames(as.list(unname(series)), paste0("series-", seq_along(series)))
  )
}
