# The colour primitives, one at a time.
#
# test-contrast.R runs the palette GATES and takes this arithmetic on trust,
# because it was checked once against validate_palette.js. These tests check the
# arithmetic itself, including the branches no shipped colour happens to reach.

# --- transfer functions ------------------------------------------------------

test_that("the sRGB transfer function round-trips", {
  x <- seq(0, 1, by = 0.05)
  expect_equal(linear_to_srgb(srgb_to_linear(x)), x, tolerance = 1e-12)
})

test_that("the transfer function uses the linear segment near black", {
  # Below 0.04045 sRGB is a straight line, not a power curve. A single-formula
  # implementation is wrong by ~0.001 there, which moves a contrast ratio.
  expect_equal(srgb_to_linear(0.02), 0.02 / 12.92)
  expect_equal(linear_to_srgb(0.002), 12.92 * 0.002)
})

test_that("linear_to_srgb clamps out-of-gamut input", {
  # CVD simulation pushes channels outside [0,1] and a display clips them, so
  # the clamp is part of the model.
  expect_equal(linear_to_srgb(-0.5), 0)
  expect_equal(linear_to_srgb(1.5), 1)
})

# --- luminance and contrast --------------------------------------------------

test_that("relative luminance spans black to white", {
  expect_equal(relative_luminance("#000000"), 0)
  expect_equal(relative_luminance("#ffffff"), 1)
  # Green carries most of the weight, blue least.
  expect_gt(relative_luminance("#00ff00"), relative_luminance("#ff0000"))
  expect_gt(relative_luminance("#ff0000"), relative_luminance("#0000ff"))
})

test_that("contrast_ratio runs 1 to 21 and is symmetric", {
  expect_equal(contrast_ratio("#000000", "#ffffff"), 21)
  expect_equal(contrast_ratio("#ffffff", "#000000"), 21)
  expect_equal(contrast_ratio("#154734", "#154734"), 1)
  expect_equal(
    contrast_ratio("#154734", "#fefefe"),
    contrast_ratio("#fefefe", "#154734")
  )
})

# --- OKLab and OKLCH ---------------------------------------------------------

test_that("a grey has no chroma", {
  # C below ~0.10 reads as grey, and a true neutral is the limiting case.
  expect_equal(unname(hex_to_oklch("#808080")[["C"]]), 0, tolerance = 1e-6)
})

test_that("OKLCH lightness orders greys the way the eye does", {
  Ls <- vapply(c("#111111", "#777777", "#dddddd"), function(h) hex_to_oklch(h)[["L"]], numeric(1))
  expect_true(all(diff(Ls) > 0))
})

test_that("hue comes back in degrees, on the full circle", {
  for (hex in c("#ff0000", "#00ff00", "#0000ff", "#ffff00")) {
    H <- hex_to_oklch(hex)[["H"]]
    expect_gte(H, 0)
    expect_lt(H, 360)
  }
})

test_that("hex_to_oklab names its three channels", {
  expect_identical(names(hex_to_oklab("#154734")), c("L", "a", "b"))
})

# --- CVD ---------------------------------------------------------------------

test_that("cvd_simulate returns a colour for each of the three types", {
  for (type in c("protan", "deutan", "tritan")) {
    expect_match(cvd_simulate("#c1393f", type), "^#[0-9A-Fa-f]{6}$")
  }
  expect_error(cvd_simulate("#c1393f", "nope"))
})

test_that("simulation collapses red and green and spares blue and yellow", {
  # The whole reason the categorical gate is applied to the simulated colours.
  expect_lt(
    cvd_delta_e("#ff0000", "#00ff00"),
    delta_e("#ff0000", "#00ff00")
  )
  expect_gt(cvd_delta_e("#0000ff", "#ffff00"), 50)
})

test_that("a colour is unchanged from itself under simulation", {
  expect_equal(cvd_delta_e("#017553", "#017553"), 0)
  expect_equal(delta_e("#017553", "#017553"), 0)
})

test_that("delta_e is symmetric", {
  expect_equal(delta_e("#017553", "#c08802"), delta_e("#c08802", "#017553"))
  expect_equal(cvd_delta_e("#017553", "#c08802"), cvd_delta_e("#c08802", "#017553"))
})

# --- mix_linear --------------------------------------------------------------

test_that("mix_linear returns its endpoints", {
  expect_identical(mix_linear("#154734", "#fefefe", 0), "#154734")
  expect_identical(mix_linear("#154734", "#fefefe", 1), "#fefefe")
})

test_that("mix_linear interpolates in emitted light, not in gamma-encoded sRGB", {
  # Halfway between black and white is #bcbcbc in linear light and #808080 the
  # naive way. The first is the colour that actually sits halfway in the
  # quantity a contrast ratio is computed from.
  expect_identical(mix_linear("#000000", "#ffffff", 0.5), "#bcbcbc")
})

test_that("mix_linear emits lower case", {
  # Generated artefacts are compared byte for byte, so "#303E4E" and "#303e4e"
  # are a drift failure.
  out <- mix_linear("#154734", "#FFB81C", 0.3)
  expect_identical(out, tolower(out))
})

# --- darken_to_contrast ------------------------------------------------------

test_that("darken_to_contrast returns the least-changed colour that passes", {
  bg <- "#fefefe"
  out <- darken_to_contrast("#FFB81C", "#222222", bg, 4.5)
  expect_gte(contrast_ratio(out, bg), 4.5)
  # One step back is the last colour that did not pass, which is what makes
  # this the first rather than the darkest.
  expect_lt(contrast_ratio("#FFB81C", bg), 4.5)
})

test_that("a colour already past the target is returned untouched", {
  expect_identical(darken_to_contrast("#154734", "#222222", "#fefefe", 3), "#154734")
})

test_that("an unreachable target gives back the colour it was walking towards", {
  expect_identical(darken_to_contrast("#ffffff", "#fefefe", "#ffffff", 21), "#fefefe")
})

# --- best_ink ----------------------------------------------------------------

test_that("best_ink picks whichever candidate reads on the background", {
  # White on Mariner green; the near-black on University Gold.
  candidates <- c("#fefefe", "#222222")
  expect_identical(best_ink("#154734", candidates), "#fefefe")
  expect_identical(best_ink("#FFB81C", candidates), "#222222")
})

test_that("best_ink pushes past the candidates when none of them clears", {
  # Picking the best available is a preference; clearing the threshold is a
  # guarantee, and only the second is worth generating a token for.
  bg <- "#777777"
  out <- best_ink(bg, c("#888888", "#666666"))

  expect_false(out %in% c("#888888", "#666666"))
  expect_gte(contrast_ratio(out, bg), 4.5)
})

test_that("best_ink honours a target other than 4.5", {
  out <- best_ink("#fefefe", c("#154734", "#FFB81C"), target = 7)
  expect_gte(contrast_ratio(out, "#fefefe"), 7)
})
