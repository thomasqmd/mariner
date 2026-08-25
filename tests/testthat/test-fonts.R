# The bundled faces have to be reachable from a graphics device.
#
# This failed silently for the whole project and nothing caught it. The fonts
# are vendored rather than installed, so R asked for a family no device could
# resolve and every figure was drawn with:
#
#   no font could be found for family "Atkinson Hyperlegible Next"
#   Unable to calculate text width/height (using zero)
#
# Zero-width text is not cosmetic. The device lays the panel out around labels
# it believes have no size, so axis titles collide and legends overlap the
# panel. Worse, base pdf() does not degrade at all -- it refuses with "invalid
# font type" and takes the whole render down.
#
# The old workaround was theme_mariner() passing base_family = "" for pdf, which
# meant a report's figures were drawn in the device default while the body text
# around them was Atkinson, and nothing said so.

test_that("the bundled fonts are found regardless of working directory", {
  # The directory has to resolve from anywhere. testthat runs with the working
  # directory at tests/testthat, which is precisely where a relative
  # "inst/assets/fonts" fallback fails -- and it fails by returning nothing, so
  # registration quietly registers zero families and the symptom shows up later
  # as a font that will not load.
  dir <- mariner:::mariner_font_dir()
  expect_true(nzchar(dir) && dir.exists(dir),
              info = "mariner_font_dir() did not resolve from the test working directory")

  withr::with_dir(tempdir(), {
    expect_identical(mariner:::mariner_font_dir(), dir,
                     label = "mariner_font_dir() from an unrelated working directory")
  })
})

test_that("every bundled family resolves to a real font file", {
  skip_if_not_installed("systemfonts")

  mariner_register_fonts(quiet = TRUE)

  # Asserted through match_fonts(), which is the lookup a graphics device
  # actually performs -- NOT through registry_fonts().
  #
  # Two earlier versions of this test asked the wrong question. Checking the
  # return value of mariner_register_fonts() made the result depend on whatever had
  # already registered in the session, since the return names only what that
  # call registered. Checking registry_fonts() membership was closer but still
  # wrong: a family can be perfectly resolvable without being in OUR registry,
  # because it may be installed on the machine. The requirement is not "we
  # registered it", it is "the device can find it", and only the second is worth
  # failing a build over.
  for (family in c("Atkinson Hyperlegible Next", "Atkinson Hyperlegible",
                   "Lora", "JetBrains Mono")) {
    m <- systemfonts::match_fonts(family)
    expect_true(nzchar(m$path) && file.exists(m$path),
                info = sprintf("%s does not resolve to a font file", family))
  }
})

test_that("Atkinson resolves to the copy vendored in this package", {
  skip_if_not_installed("systemfonts")
  mariner_register_fonts(quiet = TRUE)

  # Atkinson is the family that proves registration happened. Lora and JetBrains
  # Mono are common enough to be installed already, so their resolving says
  # nothing; Atkinson is not, so if it resolves at all it resolved through us.
  m <- systemfonts::match_fonts("Atkinson Hyperlegible Next")
  skip_if(!nzchar(m$path) || !file.exists(m$path))

  expect_equal(
    normalizePath(dirname(m$path), winslash = "/"),
    normalizePath(mariner:::mariner_font_dir(), winslash = "/"),
    label = "the directory Atkinson resolved from"
  )
})

test_that("the four styles are real cuts, not one file four times", {
  skip_if_not_installed("systemfonts")
  mariner_register_fonts(quiet = TRUE)

  # Resolved style by style, the way the device asks for them.
  fam <- rep("Atkinson Hyperlegible Next", 4)
  rows <- systemfonts::match_fonts(
    fam,
    italic = c(FALSE, FALSE, TRUE, TRUE),
    weight = c("normal", "bold", "normal", "bold")
  )
  skip_if(!all(nzchar(rows$path)))

  expect_equal(length(unique(rows$path)), 4L,
               label = "distinct files behind the four Atkinson styles")

  # The STATIC cuts, deliberately. systemfonts cannot instance a variable axis
  # for a font it did not find on the system -- register_variant() only sees
  # installed families -- so registering AtkinsonHyperlegibleNext[wght].ttf as
  # `bold` would resolve to its default instance and fake the weight. That is
  # the same limitation XeTeX has, and brand-preamble.tex answers it the same
  # way, which is what keeps the figures and the PDF body text on one file set.
  expect_false(any(grepl("[wght]", rows$path, fixed = TRUE)),
               label = "a variable font registered as a static cut")
})

test_that("theme_mariner() never asks the pdf device for a face it cannot reach", {
  # The regression this exists for takes a whole render down rather than
  # degrading: knitr draws the LaTeX pdf figures with cairo_pdf(), or with base
  # pdf() on a build without cairo, and NEITHER reads the systemfonts registry
  # -- cairo goes to fontconfig, pdf() to the PostScript font database. Asserting
  # a registered-but-not-installed TTF family there produced
  #
  #   font family 'Atkinson Hyperlegible Next' not found in PostScript font database
  #   Error in grid.Call.graphics(...) : invalid font type
  #
  # and `quarto render` exited non-zero on the fourth chunk of pdf.qmd.
  #
  # So: for pdf the face is used only when it is genuinely INSTALLED, and the
  # fallback is the device default. Registering it changes nothing here, which
  # is the property being asserted -- the test registers first precisely so that
  # a check which looked at the registry would fail.
  skip_if_not_installed("systemfonts")
  mariner_register_fonts(quiet = TRUE)

  sys <- tryCatch(systemfonts::system_fonts(), error = function(e) NULL)
  installed <- !is.null(sys) && any(grepl("^Atkinson Hyperlegible", sys$family))

  th <- theme_mariner("baylor", format = "pdf")
  if (installed) {
    expect_equal(th$text$family, "Atkinson Hyperlegible Next")
  } else {
    expect_equal(
      th$text$family, "",
      label = "theme_mariner(format = 'pdf') falls back to the device default when the face is only registered"
    )
  }

  # And the check itself answers the narrower question for pdf regardless of
  # what the registry holds.
  expect_equal(mariner:::mariner_fonts_available("pdf"), installed)
})

test_that("a report figure draws with real text metrics and no font warning", {
  skip_if_not_installed("systemfonts")
  skip_if_not_installed("ggplot2")
  mariner_register_fonts(quiet = TRUE)

  # cairo_pdf() is the device a report's figures are actually drawn with, and
  # the only one whose answer matters now. It reads fontconfig rather than the
  # registry, so this runs only where the faces are genuinely installed --
  # which is exactly the condition mariner_fonts_available("pdf") reports.
  skip_if_not(capabilities("cairo"))
  skip_if_not(mariner:::mariner_fonts_available("pdf"))

  dims <- mariner_fig_dims("pdf")
  p <- ggplot2::ggplot(ggplot2::mpg, ggplot2::aes(class, hwy)) +
    ggplot2::geom_point() +
    ggplot2::labs(x = "Vehicle class", y = "Highway MPG") +
    theme_mariner("baylor")

  out <- withr::local_tempfile(fileext = ".pdf")
  warnings_seen <- character()
  withCallingHandlers(
    ggplot2::ggsave(out, p, device = grDevices::cairo_pdf,
                    width = dims$width, height = dims$height),
    warning = function(w) {
      warnings_seen <<- c(warnings_seen, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  expect_false(any(grepl("no font could be found|Unable to calculate text|invalid font",
                         warnings_seen)),
               label = paste("font warnings while drawing:",
                             paste(unique(warnings_seen), collapse = "; ")))

  # An empty file is the failure mode this is really guarding: zero metrics
  # produced a figure that read as "the plot did not appear".
  expect_gt(file.size(out), 5000)

  # The metric itself, asked of the device directly. Zero-width text shows up
  # here before it shows up as a collapsed panel layout.
  grDevices::cairo_pdf(withr::local_tempfile(fileext = ".pdf"))
  withr::defer(grDevices::dev.off())
  graphics::par(family = "Atkinson Hyperlegible Next")
  expect_gt(graphics::strwidth("Vehicle class", units = "inches"), 0)
})

test_that("mariner_knitr_setup() picks a vector device for the report", {
  skip_if_not_installed("knitr")

  old <- knitr::opts_chunk$get()
  withr::defer(knitr::opts_chunk$set(old))

  mariner_knitr_setup("pdf", theme = "baylor")
  expect_true(knitr::opts_chunk$get("dev") %in% c("cairo_pdf", "pdf"))

  # The format vocabulary is one value, and asking for anything else is an
  # error rather than a silent fallback to pdf defaults.
  expect_error(mariner_knitr_setup("revealjs", theme = "baylor"))
})
