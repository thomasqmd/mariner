# Palettes and colour extraction.
#
# Connects R figures directly to the theme's _brand.yml so ggplot2 figures
# share the same palette as the document chrome without manual synchronisation.

#' Named colour vector for a theme
#'
#' Reads every named colour and role from the theme's `_brand.yml`.
#'
#' @param theme Theme name. Defaults to the built-in mariner theme.
#' @return A named character vector of hex codes.
#' @export
#' @examples
#' mariner_colors()
#' mariner_colors()[c("primary", "secondary")]
mariner_colors <- function(theme = mariner_themes) {
  theme <- check_theme(theme)
  brand <- read_brand(theme)
  tokens <- brand_tokens(brand)
  roles <- brand_roles(brand)
  c(unlist(tokens), unlist(roles))
}

#' Brand palette generator
#'
#' Builds a discrete, sequential, ordinal, or diverging palette for a theme.
#'
#' @param theme Theme name. Defaults to the built-in mariner theme.
#' @param family Palette family: `"discrete"`, `"sequential"`, `"ordinal"`, or
#'   `"diverging"`.
#' @param n Number of colours. `NULL` (the default) returns a palette function
#'   `function(n)` instead.
#' @param reverse Logical; if `TRUE`, reverse the colour vector.
#' @return A character vector of hex colours, or a palette function when `n` is
#'   `NULL`.
#' @export
#' @examples
#' mariner_pal(family = "discrete", n = 4)
#' mariner_pal(family = "diverging", n = 7)
#' pal_fn <- mariner_pal(family = "sequential")
#' pal_fn(5)
mariner_pal <- function(theme = mariner_themes,
                    family = c("discrete", "sequential", "ordinal", "diverging"),
                    n = NULL,
                    reverse = FALSE) {
  theme <- check_theme(theme)
  family <- rlang::arg_match(family)
  brand <- read_brand(theme)

  prefix_map <- c(
    discrete = "series",
    sequential = "seq",
    ordinal = "ord",
    diverging = "div"
  )

  raw_colors <- unname(brand_family(brand, prefix_map[[family]]))

  pal_fn <- function(num = length(raw_colors)) {
    if (missing(num) || is.null(num)) num <- length(raw_colors)
    if (num <= 0) return(character(0))

    if (family == "discrete") {
      if (num > length(raw_colors)) {
        cli::cli_warn(c(
          "Discrete palette for theme {.val {theme}} has only {length(raw_colors)} colours.",
          i = "Requested {num}; colours will be interpolated."
        ))
        cols <- grDevices::colorRampPalette(raw_colors)(num)
      } else {
        cols <- raw_colors[seq_len(num)]
      }
    } else {
      cols <- grDevices::colorRampPalette(raw_colors)(num)
    }

    if (reverse) rev(cols) else cols
  }

  if (is.null(n)) {
    pal_fn
  } else {
    pal_fn(n)
  }
}
