# The extension is assembled on demand rather than committed, so "is it
# complete?" is a question about mariner_build_extension() rather than about a
# directory someone remembered to update.
#
# Completeness is not cosmetic. brand-preamble.tex reaches the fonts through
# `Path=_extensions/mariner-baylor/fonts/`, which xelatex resolves against the
# directory holding the .tex -- the document's own. A missing fonts/ directory
# does not fall back to a system face: xelatex aborts with "the font
# Lora-Regular cannot be found".

test_that("mariner_build_extension assembles a complete extension", {
  dest <- withr::local_tempdir()

  ext <- mariner_build_extension(dest, "baylor", quiet = TRUE)

  expect_true(dir.exists(ext))
  expect_equal(basename(ext), "mariner-baylor")
  # The path the generated artefacts assume, spelled out rather than derived,
  # so a change to mariner_ext_rel() has to be made deliberately here too.
  expect_true(dir.exists(file.path(dest, "_extensions", "mariner-baylor")))

  # The manifest, and every LaTeX include it names.
  expect_true(file.exists(file.path(ext, "_extension.yml")))
  for (f in c("brand-preamble.tex", "_macros.tex", "defn.tex")) {
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
      file.exists(file.path(ext, "logos", mariner_logo_name("baylor", slot))),
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
