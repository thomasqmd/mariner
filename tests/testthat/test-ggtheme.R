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

test_that("mariner_fig_dims() fits the page geometry in _extension.yml", {
  dims <- mariner_fig_dims("pdf")
  expect_equal(dims$width, 6.5)
  expect_equal(dims$height, 4.5)

  # The width is the text block: US Letter less the left and right margins the
  # manifest sets. A figure wider than this overflows into the margin, so the
  # two numbers are checked against each other rather than merely written down.
  geometry <- yaml::read_yaml(
    mariner_path("generated", "mariner", "_extension.yml")
  )$contributes$formats$pdf$geometry
  margin_in <- function(side) {
    as.numeric(sub("in$", "", sub(paste0("^", side, "="), "",
                                  grep(paste0("^", side, "="), geometry, value = TRUE))))
  }
  expect_equal(dims$width, 8.5 - margin_in("left") - margin_in("right"))

  expect_error(mariner_fig_dims("revealjs"))
})

test_that("mariner_knitr_setup() configures knitr chunk options", {
  skip_if_not_installed("knitr")
  old_opts <- mariner_knitr_setup("pdf")

  opts <- knitr::opts_chunk$get()
  expect_equal(opts$fig.width, mariner_fig_dims("pdf")$width)
  expect_equal(opts$fig.height, mariner_fig_dims("pdf")$height)
  expect_equal(opts$dpi, 300)
  expect_equal(opts$fig.align, "center")
  expect_false(opts$echo)
  expect_false(opts$warning)
  expect_false(opts$message)

  # Restore
  knitr::opts_chunk$set(old_opts)
})
