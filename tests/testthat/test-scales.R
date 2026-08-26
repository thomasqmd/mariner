# ggplot2 scales tests

test_that("discrete scales construct valid ggplot2 ScaleDiscrete objects", {
  sc_d_col <- scale_colour_mariner_d()
  expect_s3_class(sc_d_col, "ScaleDiscrete")

  sc_d_fill <- scale_fill_mariner_d()
  expect_s3_class(sc_d_fill, "ScaleDiscrete")

  # Alias check
  expect_identical(scale_color_mariner_d, scale_colour_mariner_d)
})

test_that("continuous scales construct valid ggplot2 ScaleContinuous objects", {
  sc_c_col <- scale_colour_mariner_c()
  expect_s3_class(sc_c_col, "ScaleContinuous")

  sc_c_fill <- scale_fill_mariner_c()
  expect_s3_class(sc_c_fill, "ScaleContinuous")

  expect_identical(scale_color_mariner_c, scale_colour_mariner_c)
})

test_that("ordinal scales construct valid ggplot2 ScaleDiscrete objects", {
  sc_o_col <- scale_colour_mariner_o()
  expect_s3_class(sc_o_col, "ScaleDiscrete")

  sc_o_fill <- scale_fill_mariner_o()
  expect_s3_class(sc_o_fill, "ScaleDiscrete")

  expect_identical(scale_color_mariner_o, scale_colour_mariner_o)
})

test_that("diverging scales construct valid ggplot2 ScaleContinuous objects", {
  sc_div_col <- scale_colour_mariner_div()
  expect_s3_class(sc_div_col, "ScaleContinuous")

  sc_div_fill <- scale_fill_mariner_div()
  expect_s3_class(sc_div_fill, "ScaleContinuous")

  expect_identical(scale_color_mariner_div, scale_colour_mariner_div)
})

test_that("binned scales construct valid ggplot2 ScaleBinned objects", {
  sc_b_col <- scale_colour_mariner_b()
  expect_s3_class(sc_b_col, "ScaleBinned")

  sc_b_fill <- scale_fill_mariner_b()
  expect_s3_class(sc_b_fill, "ScaleBinned")

  expect_identical(scale_color_mariner_b, scale_colour_mariner_b)
})

test_that("scales accept additional ggplot2 parameters", {
  sc <- scale_colour_mariner_d(name = "Test Scale", na.value = "grey50")
  expect_equal(sc$name, "Test Scale")
  expect_equal(sc$na.value, "grey50")
})
