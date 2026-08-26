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

# --- mariner_set_theme -------------------------------------------------------

test_that("mariner_set_theme installs the theme and hands back the old one", {
  skip_if_not_installed("ggplot2")
  before <- ggplot2::theme_get()

  old <- mariner_set_theme()
  withr::defer(ggplot2::theme_set(before))

  expect_s3_class(old, "theme")
  expect_equal(old, before)
  expect_equal(ggplot2::theme_get(), theme_mariner())
})

test_that("mariner_set_theme makes the brand palettes the scale defaults", {
  skip_if_not_installed("ggplot2")
  before <- ggplot2::theme_get()
  withr::defer(ggplot2::theme_set(before))
  withr::local_options(list(
    ggplot2.discrete.colour = NULL,
    ggplot2.discrete.fill = NULL,
    ggplot2.continuous.colour = NULL,
    ggplot2.continuous.fill = NULL
  ))

  mariner_set_theme()

  for (opt in c("ggplot2.discrete.colour", "ggplot2.discrete.fill",
                "ggplot2.continuous.colour", "ggplot2.continuous.fill")) {
    expect_true(is.function(getOption(opt)), info = opt)
  }
  # The option is a wrapper, so what it builds is what matters.
  expect_s3_class(getOption("ggplot2.discrete.colour")(), "Scale")
  expect_s3_class(getOption("ggplot2.continuous.fill")(), "Scale")
})

test_that("mariner_set_theme forwards its extra arguments to the theme", {
  skip_if_not_installed("ggplot2")
  before <- ggplot2::theme_get()
  withr::defer(ggplot2::theme_set(before))

  mariner_set_theme(base_size = 18)
  expect_equal(ggplot2::theme_get()$text$size, 18)
})

test_that("mariner_set_theme validates its theme and format", {
  expect_error(mariner_set_theme(theme = "not-a-theme"))
  expect_error(mariner_set_theme(format = "html"))
})

# --- theme_mariner arguments -------------------------------------------------

test_that("theme_mariner takes an explicit family over the detected one", {
  skip_if_not_installed("ggplot2")
  th <- theme_mariner(base_family = "Courier")
  expect_identical(th$text$family, "Courier")
})

test_that("theme_mariner forwards extra arguments to ggplot2::theme()", {
  skip_if_not_installed("ggplot2")
  th <- theme_mariner(legend.position = "bottom")
  expect_identical(th$legend.position, "bottom")
})

test_that("theme_mariner validates its theme and format", {
  expect_error(theme_mariner(theme = "not-a-theme"))
  expect_error(theme_mariner(format = "html"))
})

# --- mariner_fig_dims / mariner_knitr_setup ----------------------------------

test_that("mariner_fig_dims rejects a format the extension does not contribute", {
  expect_error(mariner_fig_dims("html"))
})

test_that("mariner_knitr_setup takes the device it is given", {
  skip_if_not_installed("knitr")
  old <- mariner_knitr_setup(fig_format = "png", dpi = 96)
  withr::defer(knitr::opts_chunk$set(old))

  expect_identical(knitr::opts_chunk$get("dev"), "png")
  expect_equal(knitr::opts_chunk$get("dpi"), 96)
})

test_that("mariner_knitr_setup passes further chunk options through", {
  skip_if_not_installed("knitr")
  old <- mariner_knitr_setup(echo = TRUE, fig.cap = "A caption")
  withr::defer(knitr::opts_chunk$set(old))

  expect_true(knitr::opts_chunk$get("echo"))
  expect_identical(knitr::opts_chunk$get("fig.cap"), "A caption")
})
