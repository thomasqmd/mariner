# The extension is assembled on demand rather than committed, so "is it
# complete?" is a question about mariner_build_extension() rather than about a
# directory someone remembered to update.
#
# Completeness is not cosmetic. brand-preamble.tex reaches the fonts through
# `Path=_extensions/mariner/fonts/`, which xelatex resolves against the
# directory holding the .tex -- the document's own. A missing fonts/ directory
# does not fall back to a system face: xelatex aborts with "the font
# Lora-Regular cannot be found".

test_that("mariner_build_extension assembles a complete extension", {
  dest <- withr::local_tempdir()

  ext <- mariner_build_extension(dest, "mariner", quiet = TRUE)

  expect_true(dir.exists(ext))
  expect_equal(basename(ext), "mariner")
  # The path the generated artefacts assume, spelled out rather than derived,
  # so a change to mariner_ext_rel() has to be made deliberately here too.
  expect_true(dir.exists(file.path(dest, "_extensions", "mariner")))

  # The manifest, every LaTeX include it names, and the markup filter.
  expect_true(file.exists(file.path(ext, "_extension.yml")))
  for (f in c("brand-preamble.tex", "_macros.tex", "mariner-markup.lua")) {
    expect_true(file.exists(file.path(ext, f)), info = paste("missing:", f))
  }

  # Read back rather than assumed: an include named in the manifest but absent
  # from the directory is a render failure, and this is the pairing that
  # catches it.
  manifest <- yaml::read_yaml(file.path(ext, "_extension.yml"))
  includes <- vapply(
    manifest$contributes$formats$pdf$`include-in-header`,
    function(x) x$file, character(1)
  )
  for (f in includes) {
    expect_true(file.exists(file.path(ext, f)), info = paste("named but missing:", f))
  }

  # Same pairing for the filter. A filter named in the manifest but absent from
  # the directory is the louder failure of the two -- Quarto stops with "filter
  # not found" -- but the quiet one is what this really guards: drop the
  # `filters:` block and every markup class silently stops working, because
  # pandoc ignores span and div classes it does not recognise.
  filters <- unlist(manifest$contributes$formats$pdf$filters)
  expect_setequal(filters, "mariner-markup.lua")
  for (f in filters) {
    expect_true(file.exists(file.path(ext, f)), info = paste("filter missing:", f))
  }

  # The three faces xelatex loads by file, in the static cuts fontspec needs.
  for (family in c("Lora", "AtkinsonHyperlegible", "JetBrainsMono")) {
    for (cut in c("Regular", "Bold", "Italic", "BoldItalic")) {
      f <- file.path(ext, "fonts", paste0(family, "-", cut, ".ttf"))
      expect_true(file.exists(f), info = paste("missing font cut:", basename(f)))
    }
  }
  # Bundling a face without its licence is the kind of omission nobody notices
  # until it matters.
  expect_length(list.files(file.path(ext, "fonts"), pattern = "OFL"), 4)

  # Every mark named in _brand.yml, at the path the generated files point at.
  for (slot in c("small", "medium", "large")) {
    expect_true(
      file.exists(file.path(ext, "logos", mariner_logo_name("mariner", slot))),
      info = paste("missing logo slot:", slot)
    )
  }
})

test_that("the package ships no second copy of any theme asset", {
  root <- skip_if_no_source()

  # The point of building the extension on demand: every font, logo and partial
  # exists once under inst/. A basename appearing twice means someone has
  # re-committed an assembled extension, and the two copies will disagree.
  files <- list.files(
    file.path(root, "inst"),
    recursive = TRUE, full.names = TRUE
  )
  # Templates carry their own skeleton.qmd and template.yaml, one per template,
  # and those names repeat legitimately.
  files <- files[!grepl("/(rmarkdown|templates)/", files)]
  # Assets only. A per-directory README.md explaining where the fonts came from
  # is not a duplicated asset, it is two different documents.
  files <- files[grepl("\\.(tex|ttf|otf|png|svg|yml)$", files)]

  dupes <- names(which(table(basename(files)) > 1))

  expect_identical(
    dupes, character(),
    info = paste(
      "These files appear more than once under inst/:",
      paste(dupes, collapse = ", "),
      "The extension is a build output -- do not commit an assembled copy.",
      sep = "\n"
    )
  )
})

# --- the manifest and what is missing from it --------------------------------

test_that("extension_missing calls an absent directory wholly missing", {
  # Not an empty answer: nothing is there, so everything is.
  want <- extension_manifest("mariner")
  expect_identical(extension_missing(file.path(tempdir(), "no-such-ext")), want)
  expect_gt(length(want), 20L)
})

test_that("extension_missing names the file that was deleted, and only that one", {
  dest <- withr::local_tempdir()
  ext <- mariner_build_extension(dest, "mariner", quiet = TRUE)
  expect_identical(extension_missing(ext), character())

  unlink(file.path(ext, "fonts", "Lora-Bold.ttf"))
  expect_identical(extension_missing(ext), file.path("fonts", "Lora-Bold.ttf"))
})

test_that("the manifest lists the generated half by what is on disk", {
  # build_tokens() decides what it writes, so a checker with its own list of
  # expected filenames goes stale the first time that changes.
  want <- extension_manifest("mariner")
  expect_true(all(c("_extension.yml", "brand-preamble.tex") %in% want))
  expect_true(all(c("_macros.tex", "mariner-markup.lua") %in% want))
  expect_true(file.path("logos", mariner_logo_name("mariner", "medium")) %in% want)
})

test_that("extension_manifest validates the theme name", {
  expect_error(extension_manifest("not-a-theme"))
})

# --- building ----------------------------------------------------------------

test_that("mariner_build_extension says what it built unless told to be quiet", {
  dest <- withr::local_tempdir()
  said <- paste(capture_messages(mariner_build_extension(dest, "mariner")), collapse = "")
  expect_match(said, "mariner")
  expect_match(said, "files")
})

test_that("overwrite = FALSE leaves a file a student edited alone", {
  dest <- withr::local_tempdir()
  ext <- mariner_build_extension(dest, "mariner", quiet = TRUE)

  edited <- file.path(ext, "_macros.tex")
  writeLines("% mine", edited)
  mariner_build_extension(dest, "mariner", overwrite = FALSE, quiet = TRUE)

  expect_identical(readLines(edited), "% mine")
})

test_that("overwrite = TRUE restores it", {
  dest <- withr::local_tempdir()
  ext <- mariner_build_extension(dest, "mariner", quiet = TRUE)

  edited <- file.path(ext, "_macros.tex")
  writeLines("% mine", edited)
  mariner_build_extension(dest, "mariner", quiet = TRUE)

  expect_false(identical(readLines(edited), "% mine"))
})

test_that("an install with no generated files is reported as an install problem", {
  # The generated half is the one part of the extension that is not shipped as a
  # source file, so its absence means a partial install rather than a bad call.
  real <- mariner_path
  empty <- withr::local_tempdir()
  local_mocked_bindings(mariner_path = function(...) {
    if (identical(..1, "generated")) empty else real(...)
  })

  expect_error(
    mariner_build_extension(withr::local_tempdir(), "mariner", quiet = TRUE),
    "No generated token files"
  )
})

test_that("mariner_build_extension validates the theme name", {
  expect_error(mariner_build_extension(withr::local_tempdir(), "not-a-theme"))
})
