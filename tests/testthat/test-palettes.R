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
