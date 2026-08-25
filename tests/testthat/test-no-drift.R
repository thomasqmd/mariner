# The generated artefacts must match what the generators produce right now.
#
# This is the test that makes "_brand.yml is the only place a hex is typed"
# true rather than aspirational. Editing a colour, a logo filename, a slide
# constant or a logo's pixel dimensions without re-running
# data-raw/build-tokens.R fails here, instead of shipping a stylesheet that
# disagrees with the brand file it claims to come from.
#
# Only the six files in inst/generated/<theme>/ are checked, because they are
# the only build outputs in the package. The assembled extension is not
# committed at all -- test-extension.R covers that, by building one.

test_that("generated files match their generators", {
  root <- skip_if_no_source()

  tmp <- withr::local_tempdir()
  # The generators read source assets from `root`'s inst/ and write beneath the
  # root they are given, so copying inst/ across gives them everything they need
  # without touching the committed tree.
  dir.create(file.path(tmp, "inst"), recursive = TRUE, showWarnings = FALSE)
  file.copy(file.path(root, "inst"), tmp, recursive = TRUE)

  build_tokens(root = tmp, quiet = TRUE)

  for (theme in mariner_themes) {
    for (spec in generated_files(theme)) {
      committed <- file.path(root, spec$path)
      regenerated <- file.path(tmp, spec$path)

      expect_true(file.exists(committed),
                  info = paste("missing generated file:", spec$path))

      # Bytes, not lines: a trailing-newline difference is a real difference,
      # and it is exactly the kind that survives a visual diff.
      expect_identical(
        readBin(regenerated, "raw", file.size(regenerated)),
        readBin(committed, "raw", file.size(committed)),
        info = paste0(
          spec$path, " is stale.\n",
          "Run: Rscript data-raw/build-tokens.R"
        )
      )
    }
  }
})

test_that("no hex colour is typed outside the brand file", {
  root <- skip_if_no_source()

  # Where a colour is ALLOWED to appear literally: the brand definition itself,
  # and any file carrying the generated marker.
  sources <- list.files(file.path(root, "inst", "tex"), full.names = TRUE)

  # Six- and three-digit hex, but not a Typst/CSS identifier that merely follows
  # a '#'. Requires a word boundary before the hash.
  hex <- "#[0-9a-fA-F]{6}\\b|#[0-9a-fA-F]{3}\\b"

  offenders <- character()
  for (f in sources) {
    lines <- readLines(f, warn = FALSE)
    if (any(grepl(GENERATED_MARKER, lines, fixed = TRUE))) next
    # Strip comments before looking. A comment explaining why #154734 cannot
    # carry a data series is documentation, not a hardcoded colour, and several
    # of these files carry exactly that.
    code <- sub("(//|%|/\\*).*$", "", lines)
    hits <- grep(hex, code, value = TRUE)
    if (length(hits)) {
      offenders <- c(offenders, paste0(basename(f), ": ", trimws(hits)))
    }
  }

  expect_identical(
    offenders, character(),
    info = paste(
      "Literal colours found outside _brand.yml. Reference a $qmd-* token instead:",
      paste(offenders, collapse = "\n"), sep = "\n"
    )
  )
})

test_that("nothing references the upstream package the theme came from", {
  root <- skip_if_no_source()

  files <- list.files(
    c(file.path(root, "inst"), file.path(root, "R")),
    recursive = TRUE, full.names = TRUE
  )
  # Text only. A .ttf that happens to contain the byte sequence is not a finding.
  files <- files[grepl("\\.(scss|css|tex|typ|yml|yaml|html|js|md|R)$", files)]

  offenders <- Filter(
    function(f) any(grepl("qmdthemes", readLines(f, warn = FALSE), fixed = TRUE)),
    files
  )

  expect_identical(
    basename(offenders), character(),
    info = "mariner vendors this theme outright and does not sync with QMDThemes."
  )
})
