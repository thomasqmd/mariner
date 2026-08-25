# The colour gates, re-run in R against the shipped _brand.yml files.
#
# data-raw/palette-validation.md records what the dataviz skill's
# validate_palette.js measured. These tests reproduce those gates from R so a
# palette regression fails `R CMD check` instead of waiting for someone to
# re-run a script. R/contrast.R is verified against the reference numbers first
# -- a second implementation is only useful if it agrees with the first.

pal_of <- function(theme, prefix) {
  p <- yaml::read_yaml(
    system.file("brand", theme, "_brand.yml", package = "mariner")
  )$color$palette
  unlist(p[grep(paste0("^", prefix, "-"), names(p))], use.names = FALSE)
}
surface_of <- function(theme) {
  yaml::read_yaml(
    system.file("brand", theme, "_brand.yml", package = "mariner")
  )$color$background
}

test_that("the R colour maths agrees with the reference implementation", {
  # Values from validate_palette.js, recorded in palette-validation.md. If these
  # drift, every gate below is measuring something else and the recorded numbers
  # stop meaning anything.
  expect_equal(contrast_ratio("#FFB81C", "#fefefe"), 1.72, tolerance = 0.01)
  expect_equal(contrast_ratio("#154734", "#fefefe"), 10.50, tolerance = 0.01)
  expect_equal(unname(hex_to_oklch("#154734")["L"]), 0.359, tolerance = 0.002)
  expect_equal(unname(hex_to_oklch("#154734")["C"]), 0.063, tolerance = 0.002)
  expect_equal(delta_e("#c08802", "#017553"), 23.5, tolerance = 0.1)
  # The CVD path is the one with a trap in it: the simulation must clamp each
  # linear channel to [0,1] before converting, and must NOT round-trip through
  # an 8-bit hex. Unclamped this pair reads 14.4; via hex it reads 13.9.
  expect_equal(cvd_delta_e("#017553", "#c08802"), 13.7, tolerance = 0.1)
  expect_equal(cvd_delta_e("#c1393f", "#a8820a"), 8.7, tolerance = 0.1)
})

test_that("categorical slots sit inside the lightness band", {
  for (theme in mariner_themes) {
    for (col in pal_of(theme, "series")) {
      L <- unname(hex_to_oklch(col)["L"])
      expect_gte(L, 0.43); expect_lte(L, 0.77)
    }
  }
})

test_that("categorical slots clear the chroma floor", {
  # Below ~0.10 a hue reads as grey and stops doing identity work.
  for (theme in mariner_themes) {
    for (col in pal_of(theme, "series")) {
      expect_gte(unname(hex_to_oklch(col)["C"]), 0.10)
    }
  }
})

test_that("categorical slots clear 3:1 against their own surface", {
  for (theme in mariner_themes) {
    bg <- surface_of(theme)
    for (col in pal_of(theme, "series")) expect_gte(contrast_ratio(col, bg), 3.0)
  }
})

test_that("adjacent categorical pairs clear the CVD and normal-vision gates", {
  # The slot ORDER is the safety mechanism -- this is the test that would catch
  # someone "tidying" the palette into a prettier sequence.
  for (theme in mariner_themes) {
    s <- pal_of(theme, "series")
    for (i in seq_len(length(s) - 1L)) {
      expect_gte(cvd_delta_e(s[i], s[i + 1L]), 8.0)
      expect_gte(delta_e(s[i], s[i + 1L]), 15.0)
    }
  }
})

test_that("the first three slots clear the ALL-PAIRS gates", {
  # Scatter, bubble and choropleth put any two marks side by side, so the
  # leading three have to survive the harder test. This is what caps those
  # forms at three series.
  for (theme in mariner_themes) {
    s <- pal_of(theme, "series")[1:3]
    for (i in 1:2) for (j in (i + 1L):3) {
      expect_gte(cvd_delta_e(s[i], s[j]), 8.0)
      expect_gte(delta_e(s[i], s[j]), 15.0)
    }
  }
})

test_that("ordinal ramps are monotone, well spaced, and visible at the light end", {
  for (theme in mariner_themes) {
    o <- pal_of(theme, "ord"); L <- vapply(o, function(c) unname(hex_to_oklch(c)["L"]), 0)
    expect_true(all(diff(L) < 0))              # light -> dark
    expect_true(all(abs(diff(L)) >= 0.06))     # steps are visible
    # Every ordinal step is a mark someone has to see, so unlike the sequential
    # ramp the light end must clear 2:1. Baylor's failed here at 1.84 on the
    # first attempt and was re-stepped rather than excused.
    expect_gte(contrast_ratio(o[1], surface_of(theme)), 2.0)
  }
})

test_that("sequential ramps are monotone and single-hue", {
  for (theme in mariner_themes) {
    s <- pal_of(theme, "seq")
    L <- vapply(s, function(c) unname(hex_to_oklch(c)["L"]), 0)
    expect_true(all(diff(L) < 0))
    expect_true(all(abs(diff(L)) >= 0.06))
    h <- vapply(s, function(c) unname(hex_to_oklch(c)["H"]), 0)
    expect_lt(diff(range(h)), 12)
    # NOTE: deliberately NOT testing the light end against 2:1. On a continuous
    # scale "almost invisible" correctly reads as "near zero" -- personal's is
    # 1.12:1 and Baylor's 1.09:1, both intended. See palette-validation.md.
  }
})

test_that("diverging ramps have equal arms and a neutral midpoint", {
  for (theme in mariner_themes) {
    d <- pal_of(theme, "div")
    expect_length(d, 7L)
    expect_lt(unname(hex_to_oklch(d[4])["C"]), 0.02)   # midpoint carries no hue
    # arms move away from the midpoint in lightness at a comparable rate
    L <- vapply(d, function(c) unname(hex_to_oklch(c)["L"]), 0)
    expect_true(all(diff(L[1:4]) > 0))
    expect_true(all(diff(L[4:7]) < 0))
  }
})

test_that("text inks meet WCAG, and gold is only used where it legally can be", {
  b <- yaml::read_yaml(
    system.file("brand", "baylor", "_brand.yml", package = "mariner")
  )$color$palette
  expect_gte(contrast_ratio(b[["gold-ink"]], "#fefefe"), 4.5)   # AA body text
  expect_gte(contrast_ratio(b[["gold-rule"]], "#fefefe"), 3.0)  # large / UI
  expect_lt(contrast_ratio(b[["university-gold"]], "#fefefe"), 3.0)  # neither

  for (theme in mariner_themes) {
    p <- yaml::read_yaml(
      system.file("brand", theme, "_brand.yml", package = "mariner")
    )$color$palette
    bg <- surface_of(theme)
    expect_gte(contrast_ratio(p[["ink"]], bg), 4.5)
    expect_gte(contrast_ratio(p[["ink-secondary"]], bg), 4.5)
    expect_gte(contrast_ratio(p[["ink-muted"]], bg), 4.5)
  }
})
