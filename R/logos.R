# Brand marks, and how big each one is drawn.
#
# Two things are typed by hand about a logo, and neither is a size:
#
#   inst/brand/baylor/_brand.yml   which FILE fills each of the three slots
#   LOGO_HEIGHT below              how TALL a mark stands in each placement
#
# Widths are read off the files. Every placement asks for a height, and the
# width follows from the image's own pixel dimensions.
#
# WHY HEIGHT AND NOT WIDTH. The three marks span 0.89:1 to 5.62:1, and what
# makes a set of marks look like one set is that they stand the same height --
# a wordmark and a square interlock given the same WIDTH look nothing alike, and
# the square one towers. The previous version of this theme hardcoded a width
# per file (1.3in for the wordmark, 0.7in for a square mark) and carried a
# comment explaining that the two numbers could not be reconciled because the
# shapes differ. They reconcile fine; the code was solving for the wrong
# dimension.
#
# The practical payoff is that adding a mark is one line in _brand.yml. Nothing
# here, and no number anywhere, has to change.

# Target heights per placement.
#
# pdf_corner is the one value carried over from the old theme rather than
# chosen: it used width = 1.3in on a 5.35:1 wordmark, which stands 0.243in tall.
# Rounding to 0.25in keeps the title-page mark visually where it was while the
# width moves to suit the new file's slightly wider 5.62:1.
#
# One placement, one number. The slide and html-header heights that used to sit
# beside it went with the formats that placed them.
LOGO_HEIGHT <- list(
  pdf_corner_in = 0.25
)

# PNG pixel dimensions, from the file's own header.
#
# A PNG's first chunk is required by the spec to be IHDR, and its width and
# height are the two big-endian uint32s at bytes 17-24. That is fixed for every
# valid PNG, so this needs no image library: reading 24 bytes answers it, and
# adding a `png` or `magick` dependency to a package whose whole point is
# working out of the box would be a poor trade for eight bytes.
#
# Errors rather than guessing. A logo whose dimensions cannot be read would
# otherwise produce a silently mis-sized mark, which is the failure mode this
# entire module exists to prevent.
png_dims <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con), add = TRUE)
  header <- readBin(con, "raw", n = 24L)
  if (length(header) < 24L ||
      !identical(header[1:8], as.raw(c(0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a))) ||
      !identical(rawToChar(header[13:16]), "IHDR")) {
    cli::cli_abort("{.file {path}} is not a readable PNG (no IHDR header).")
  }
  # as.integer() is safe here rather than merely convenient: the PNG spec caps
  # both dimensions at 2^31 - 1, which is exactly .Machine$integer.max, so a
  # valid PNG can never overflow. The arithmetic runs in double first because
  # 256^(3:0) is a double vector.
  be_uint32 <- function(bytes) as.integer(sum(as.integer(bytes) * 256^(3:0)))
  list(width = be_uint32(header[17:20]), height = be_uint32(header[21:24]))
}

# Which file fills a slot, as an absolute path into the installed package.
mariner_logo_file <- function(theme = mariner_themes,
                              slot = c("medium", "small", "large")) {
  theme <- check_theme(theme)
  slot <- rlang::arg_match(slot)
  brand <- read_brand(theme)
  file <- brand$logo[[slot]]
  if (is.null(file)) {
    cli::cli_abort(c(
      "No {.val {slot}} logo defined for theme {.val {theme}}.",
      i = "Add it under {.code logo:} in {.file inst/brand/{theme}/_brand.yml}."
    ))
  }
  mariner_path("assets", "logos", file)
}

# The slot's filename alone, for building a path the RENDERED DOCUMENT will
# resolve (relative to the project root, where Quarto writes the .tex/.typ).
mariner_logo_name <- function(theme = mariner_themes, slot = "medium") {
  basename(mariner_logo_file(theme, slot))
}

mariner_logo_aspect <- function(theme = mariner_themes, slot = "medium") {
  d <- png_dims(mariner_logo_file(theme, slot))
  d$width / d$height
}

#' Size a brand mark from its own dimensions
#'
#' Returns the width a logo should be drawn at to stand `height` tall, computed
#' from the file's actual pixel aspect ratio. Units are whatever `height` is in
#' -- since the ratio is unitless.
#'
#' This is the function that lets `_brand.yml` name a logo without also stating
#' how big it is.
#'
#' @param height Target height, in any unit.
#' @param theme One of [mariner_themes].
#' @param slot Which brand slot: `"medium"` (the horizontal wordmark, the
#'   default mark), `"small"` (the interlock) or `"large"` (the stacked lockup).
#' @return A single number: the width, in the same unit as `height`.
#' @noRd
#' @examples
#' # The pdf title-page mark, 0.25in tall
#' mariner_logo_width(0.25)
#'
#' # The same height applied to the stacked lockup gives a much narrower box,
#' # which is the point -- both marks stand 0.25in.
#' mariner_logo_width(0.25, slot = "large")
mariner_logo_width <- function(height, theme = mariner_themes, slot = "medium") {
  height * mariner_logo_aspect(theme, slot)
}
