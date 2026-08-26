# The one parser that reads _brand.yml, and the semantic layer built on it.
#
# The fixtures below are synthetic on purpose. Reading the real brand file would
# test the file, and the file is already tested by test-contrast.R; what these
# assert is the parser's behaviour on shapes the real file does not happen to
# have.

fake_brand <- function(palette = list(), ...) {
  list(color = c(list(palette = palette), list(...)))
}

# --- brand_family ------------------------------------------------------------

test_that("brand_family orders slots numerically, not lexicographically", {
  # "series-10" sorts before "series-2" as a string. The palette has eight slots
  # today, so this is the assertion that survives a ninth being added.
  brand <- fake_brand(list(
    `series-1-a` = "#111111",
    `series-2-b` = "#222222",
    `series-10-j` = "#aaaaaa",
    `seq-1` = "#eeeeee"
  ))
  fam <- brand_family(brand, "series")

  expect_identical(unname(fam), c("#111111", "#222222", "#aaaaaa"))
  expect_identical(names(fam), c("a", "b", "j"))
})

test_that("brand_family labels an unsuffixed slot with its number", {
  # `seq-1` has no hue name, so the number is the only label there is.
  brand <- fake_brand(list(`seq-1` = "#111111", `seq-2` = "#222222"))
  expect_identical(names(brand_family(brand, "seq")), c("1", "2"))
})

test_that("brand_family returns nothing for a prefix the palette does not use", {
  expect_length(brand_family(fake_brand(list(`seq-1` = "#111111")), "div"), 0L)
})

test_that("the real palettes come back in file order", {
  brand <- read_brand("mariner")
  expect_length(brand_family(brand, "series"), 8L)
  expect_identical(brand_family(brand, "series")[["green"]], "#017553")
  expect_identical(unname(brand_family(brand, "div"))[[1]], "#017553")
})

# --- brand_tokens ------------------------------------------------------------

test_that("brand_tokens keeps the hex entries and drops the rest", {
  # A palette entry may name another entry rather than a colour. Emitting that
  # as a \definecolor would produce a LaTeX error naming a colour nobody typed.
  brand <- fake_brand(
    list(green = "#154734", alias = "green", sizes = list(1, 2)),
    background = "#fefefe", foreground = "#222222"
  )
  tokens <- brand_tokens(brand)

  expect_identical(tokens$background, "#fefefe")
  expect_identical(tokens$foreground, "#222222")
  expect_identical(tokens$green, "#154734")
  expect_false(any(c("alias", "sizes") %in% names(tokens)))
})

test_that("brand_tokens puts background and foreground first, every time", {
  # The generators emit in this order and the drift test compares bytes.
  tokens <- brand_tokens(read_brand("mariner"))
  expect_identical(names(tokens)[1:2], c("background", "foreground"))
})

# --- brand_name --------------------------------------------------------------

test_that("brand_name reads both shapes Quarto's spec allows", {
  # `meta.name` is either a bare string or a short/full pair.
  pair <- list(meta = list(name = list(short = "M", full = "Mariner Reports")))
  expect_identical(brand_name(pair), "Mariner Reports")
  expect_identical(brand_name(pair, "short"), "M")

  bare <- list(meta = list(name = "Mariner"))
  expect_identical(brand_name(bare), "Mariner")
  expect_identical(brand_name(bare, "short"), "Mariner")
})

test_that("brand_name falls back to whichever half the pair has", {
  expect_identical(brand_name(list(meta = list(name = list(short = "M")))), "M")
  expect_identical(
    brand_name(list(meta = list(name = list(full = "Mariner"))), "short"),
    "Mariner"
  )
})

# --- brand_resolve -----------------------------------------------------------

test_that("brand_resolve takes a palette key or a literal hex", {
  brand <- fake_brand(list(`mariner-green` = "#154734"))
  expect_identical(brand_resolve(brand, "mariner-green"), "#154734")
  expect_identical(brand_resolve(brand, "#abcdef"), "#abcdef")
})

# --- brand_roles -------------------------------------------------------------

test_that("the computed roles clear the contrast they are computed for", {
  # These four are derived rather than looked up, and the derivation is the
  # guarantee: a theme whose secondary is light gets dark text without anyone
  # remembering to pick it.
  brand <- read_brand("mariner")
  roles <- brand_roles(brand)
  bg <- brand$color$background

  expect_gte(contrast_ratio(roles$`accent-ink`, bg), 4.5)
  expect_gte(contrast_ratio(roles$`accent-rule`, bg), 3)
  expect_gte(contrast_ratio(roles$`on-primary`, roles$primary), 4.5)
  expect_gte(contrast_ratio(roles$`on-secondary`, roles$secondary), 4.5)
})

test_that("brand_roles numbers the series positionally", {
  # `$qmd-series-1` is the first slot whatever the theme; the hue-named alias
  # says which colour that happens to be here.
  brand <- read_brand("mariner")
  roles <- brand_roles(brand)
  series <- brand_family(brand, "series")

  expect_identical(roles$`series-1`, unname(series)[[1]])
  expect_identical(roles$`series-8`, unname(series)[[8]])
  expect_null(roles$`series-9`)
})

test_that("brand_roles resolves primary and secondary through the palette", {
  brand <- read_brand("mariner")
  roles <- brand_roles(brand)
  expect_match(roles$primary, "^#[0-9a-fA-F]{6}$")
  expect_match(roles$secondary, "^#[0-9a-fA-F]{6}$")
  expect_match(roles$link, "^#[0-9a-fA-F]{6}$")
})

# --- read_brand --------------------------------------------------------------

test_that("read_brand validates the theme name", {
  expect_error(read_brand("not-a-theme"))
})
