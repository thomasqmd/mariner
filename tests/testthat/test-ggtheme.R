# ggplot2 and knitr setup tests

test_that("theme_mariner() returns a valid theme object", {
  for (theme in mariner_themes) {
    for (fmt in mariner_formats) {
      th <- theme_mariner(theme = theme, format = fmt)
      expect_s3_class(th, "theme")
      expect_s3_class(th, "gg")

      # Background matches theme background
      cols <- mariner_colors(theme)
      expect_equal(th$plot.background$fill, cols[["background"]])
      expect_equal(th$panel.background$fill, cols[["background"]])

      # Grid and axis colors
      expect_equal(th$panel.grid.major$colour, cols[["rule-grid"]])
      expect_equal(th$axis.line$colour, cols[["rule-axis"]])
    }
  }
})

test_that("mariner_fig_dims() returns proper dimensions for all formats", {
  # The slide figure is DERIVED -- the slide box less the heading bar, at
  # MARINER_SLIDE$px_per_in to the inch -- so this asserts the derivation rather
  # than a pair of numbers that would have to be edited alongside it.
  geom <- mariner_slide_geometry()
  rev_dims <- mariner_fig_dims("revealjs")
  expect_equal(rev_dims$width, geom$width / mariner:::MARINER_SLIDE$px_per_in)
  expect_equal(rev_dims$height, (geom$height - geom$chrome) / mariner:::MARINER_SLIDE$px_per_in)

  pdf_dims <- mariner_fig_dims("pdf")
  expect_equal(pdf_dims$width, 6.5)
  expect_equal(pdf_dims$height, 4.5)

  html_dims <- mariner_fig_dims("html")
  expect_equal(html_dims$width, 8.0)
  expect_equal(html_dims$height, 5.0)
})

test_that("mariner_knitr_setup() configures knitr chunk options", {
  skip_if_not_installed("knitr")
  old_opts <- mariner_knitr_setup("revealjs", theme = "baylor")

  opts <- knitr::opts_chunk$get()
  expect_equal(opts$fig.width, mariner_fig_dims("revealjs")$width)
  expect_equal(opts$fig.height, mariner_fig_dims("revealjs")$height)
  expect_equal(opts$dpi, 300)
  expect_equal(opts$fig.align, "center")
  expect_false(opts$echo)
  expect_false(opts$warning)
  expect_false(opts$message)

  # Restore
  knitr::opts_chunk$set(old_opts)
})
