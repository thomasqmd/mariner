# Logo sizing is derived, and these are the assertions that keep it that way.

test_that("png_dims reads real dimensions from the header", {
  # Measured with sips(1) at vendoring time. If a mark is replaced, these change
  # -- and they SHOULD, which is why the derived widths below are expressed as
  # relationships rather than as numbers.
  expect_identical(png_dims(mariner_logo_file("mariner", "medium")),
                   list(width = 949L, height = 169L))
  expect_identical(png_dims(mariner_logo_file("mariner", "large")),
                   list(width = 742L, height = 336L))
  expect_identical(png_dims(mariner_logo_file("mariner", "small")),
                   list(width = 288L, height = 324L))
})

test_that("png_dims rejects a file that is not a PNG", {
  f <- withr::local_tempfile(fileext = ".png")
  writeLines("this is not a png", f)
  expect_error(png_dims(f), "not a readable PNG")
})

test_that("width is derived from the file's own aspect ratio", {
  for (slot in c("small", "medium", "large")) {
    d <- png_dims(mariner_logo_file("mariner", slot))
    expect_equal(
      mariner_logo_width(1, "mariner", slot),
      d$width / d$height,
      tolerance = 1e-9
    )
    # Scaling the height scales the width by the same factor.
    expect_equal(
      mariner_logo_width(2.5, "mariner", slot),
      2.5 * mariner_logo_width(1, "mariner", slot),
      tolerance = 1e-9
    )
  }
})

test_that("the three marks stand the same height, not the same width", {
  # The whole reason sizing is by height. At a shared height the widths differ
  # by the ratio of the aspects; at a shared width the heights would differ by
  # more than 6x and the set would not read as one set.
  h <- 1
  widths <- vapply(
    c("small", "medium", "large"),
    function(s) mariner_logo_width(h, "mariner", s),
    numeric(1)
  )
  expect_gt(widths[["medium"]], widths[["large"]])
  expect_gt(widths[["large"]], widths[["small"]])
})

test_that("every logo named in _brand.yml is actually bundled", {
  brand <- read_brand("mariner")
  expect_true(length(brand$logo) > 0)
  for (slot in names(brand$logo)) {
    expect_true(
      file.exists(mariner_logo_file("mariner", slot)),
      info = paste("logo slot", slot, "names a file that is not bundled")
    )
  }
})

test_that("an undefined logo slot errors rather than sizing nothing", {
  expect_error(mariner_logo_file("mariner", "enormous"), class = "rlang_error")
})

test_that("the preamble names the medium mark and sizes it from the file", {
  wordmark <- mariner_logo_name("mariner", "medium")

  preamble <- build_pdf_preamble("mariner")
  expect_true(grepl(wordmark, preamble, fixed = TRUE))

  # And the derived width reached the preamble, rather than a leftover constant.
  expected <- num_str(mariner_logo_width(LOGO_HEIGHT$pdf_corner_in, "mariner", "medium"))
  expect_true(
    grepl(paste0("\\setlength{\\qmdlogowidth}{", expected, "in}"), preamble, fixed = TRUE),
    info = "pdf corner width is not the derived value"
  )

  # The stacked and interlock marks stay bundled but are placed by nothing, now
  # that the formats that placed them are gone. Asserting their absence keeps a
  # future edit from reaching for one without sizing it.
  for (slot in c("small", "large")) {
    expect_false(
      grepl(mariner_logo_name("mariner", slot), preamble, fixed = TRUE),
      info = paste("the", slot, "mark is placed but has no derived size")
    )
  }
})
