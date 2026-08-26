# Palette and colour extraction tests

test_that("mariner_colors() returns named colours for both themes", {
  for (theme in mariner_themes) {
    cols <- mariner_colors(theme)
    expect_true(is.character(cols))
    expect_gt(length(cols), 20)
    expect_true(all(grepl("^#[0-9a-fA-F]{6}$", cols)))

    # Semantic roles and core tokens
    expect_true(all(c("background", "foreground", "primary", "secondary", "link",
                      "accent-ink", "accent-rule", "on-primary", "on-secondary",
                      "ink", "ink-secondary", "ink-muted", "rule-grid", "rule-axis") %in% names(cols)))
  }
})

test_that("mariner_colors() errors on unknown theme", {
  expect_error(mariner_colors("invalid_theme"))
})

test_that("mariner_pal() returns functions when n is NULL", {
  for (theme in mariner_themes) {
    for (fam in c("discrete", "sequential", "ordinal", "diverging")) {
      pal_fn <- mariner_pal(theme, family = fam)
      expect_true(is.function(pal_fn))

      # Generating colours
      res <- pal_fn(3)
      expect_equal(length(res), 3)
      expect_true(all(grepl("^#[0-9a-fA-F]{6}$", res)))
    }
  }
})

test_that("mariner_pal() returns character vector when n is provided", {
  cols4 <- mariner_pal("mariner", "discrete", n = 4)
  expect_equal(length(cols4), 4)
  expect_true(is.character(cols4))

  cols_rev <- mariner_pal("mariner", "discrete", n = 4, reverse = TRUE)
  expect_equal(cols_rev, rev(cols4))
})

test_that("mariner_pal() warns when discrete n exceeds 8", {
  expect_warning(mariner_pal("mariner", "discrete", n = 10), "Discrete palette")
})

test_that("mariner_pal() returns empty vector on n <= 0", {
  expect_equal(mariner_pal("mariner", "discrete", n = 0), character(0))
})

test_that("mariner_pal reverses whichever family it is asked for", {
  for (fam in c("sequential", "ordinal", "diverging")) {
    forward <- mariner_pal(family = fam, n = 5)
    expect_identical(mariner_pal(family = fam, n = 5, reverse = TRUE), rev(forward))
  }
})

test_that("a reversed palette function reverses at call time too", {
  pal <- mariner_pal(family = "sequential", reverse = TRUE)
  expect_identical(pal(4), rev(mariner_pal(family = "sequential", n = 4)))
})

test_that("a palette function called with no argument returns the whole family", {
  # The default is the slot count, which is what the discrete scales rely on.
  expect_length(mariner_pal(family = "discrete")(), 8L)
  expect_length(mariner_pal(family = "sequential")(), 7L)
  expect_length(mariner_pal(family = "ordinal")(), 5L)
  expect_length(mariner_pal(family = "diverging")(), 7L)
})

test_that("a NULL n is the same as no n", {
  pal <- mariner_pal(family = "discrete")
  expect_identical(pal(NULL), pal())
})

test_that("the continuous families interpolate rather than warn", {
  # Only the discrete family is capped: its colours are chosen to separate, and
  # interpolating between them undoes that. A ramp has no such property to lose.
  expect_silent(mariner_pal(family = "sequential", n = 100))
  expect_length(mariner_pal(family = "diverging", n = 101), 101L)
})

test_that("the discrete family returns its own colours unchanged below the cap", {
  cols <- mariner_pal(family = "discrete", n = 8)
  expect_identical(cols, unname(brand_family(read_brand("mariner"), "series")))
})

test_that("mariner_pal rejects a family it does not have", {
  expect_error(mariner_pal(family = "categorical"))
})

test_that("mariner_colors puts every palette key and every role in one vector", {
  cols <- mariner_colors("mariner")
  brand <- read_brand("mariner")

  expect_true(all(names(brand$color$palette) %in% names(cols)))
  expect_identical(cols[["background"]], brand$color$background)
  expect_identical(cols[["mariner-green"]], brand$color$palette[["mariner-green"]])
  expect_equal(anyDuplicated(names(cols)), 0L)
})
