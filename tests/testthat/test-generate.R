# The generators, read as text.
#
# test-no-drift.R asserts that what is committed equals what these produce. It
# says nothing about what they produce, and it skips outside a source checkout,
# which is where R CMD check runs. These tests assert the content, from the
# installed package.

# --- tex_name ----------------------------------------------------------------

test_that("tex_name spells out digits and drops the punctuation", {
  # LaTeX command names cannot contain digits or hyphens.
  expect_identical(tex_name("series-1-green"), "qmdseriesonegreen")
  expect_identical(tex_name("on-primary"), "qmdonprimary")
  expect_identical(tex_name("seq-10"), "qmdseqonezero")
  expect_identical(tex_name("Ink"), "qmdink")
})

test_that("every generated command name is letters only", {
  for (key in names(c(brand_tokens(read_brand("mariner")), brand_roles(read_brand("mariner"))))) {
    expect_match(tex_name(key), "^[a-z]+$")
  }
})

test_that("distinct tokens get distinct command names", {
  # Two tokens colliding would silently redefine one colour as another.
  brand <- read_brand("mariner")
  keys <- names(c(brand_tokens(brand), brand_roles(brand)))
  expect_equal(anyDuplicated(vapply(keys, tex_name, character(1))), 0L)
})

# --- generated_header --------------------------------------------------------

test_that("the header carries the marker, the source and the way to rebuild it", {
  # The marker is what lets the drift test tell "this file is allowed to contain
  # hex codes" from "someone typed a colour here".
  header <- generated_header("mariner", "%")
  expect_match(header, GENERATED_MARKER, fixed = TRUE)
  expect_match(header, "inst/brand/mariner/_brand.yml", fixed = TRUE)
  expect_match(header, "data-raw/build-tokens.R", fixed = TRUE)
  expect_true(all(startsWith(strsplit(header, "\n")[[1]], "%")))
})

test_that("the comment character is the caller's", {
  expect_true(all(startsWith(strsplit(generated_header("mariner"), "\n")[[1]], "//")))
})

# --- build_pdf_preamble ------------------------------------------------------

test_that("the preamble defines a colour for every token and role", {
  brand <- read_brand("mariner")
  tex <- build_pdf_preamble("mariner")

  for (key in names(c(brand_tokens(brand), brand_roles(brand)))) {
    expect_match(tex, paste0("\\definecolor{", tex_name(key), "}{HTML}{"), fixed = TRUE)
  }
})

test_that("the preamble writes hex in upper case, without the hash", {
  # xcolor's HTML model takes six hex digits and nothing else.
  tex <- build_pdf_preamble("mariner")
  defs <- grep("definecolor", strsplit(tex, "\n")[[1]], value = TRUE, fixed = TRUE)
  expect_gt(length(defs), 20L)
  expect_true(all(grepl("\\{HTML\\}\\{[0-9A-F]{6}\\}$", defs)))
})

test_that("the preamble loads the three faces from the extension it ships in", {
  tex <- build_pdf_preamble("mariner")
  expect_match(tex, "\\setmainfont{Lora}", fixed = TRUE)
  expect_match(tex, "\\setsansfont{AtkinsonHyperlegible}", fixed = TRUE)
  expect_match(tex, "\\setmonofont{JetBrainsMono}", fixed = TRUE)
  expect_match(tex, "Path=_extensions/mariner/fonts/", fixed = TRUE)
})

test_that("the preamble declares the commands the Lua filter targets", {
  # Pandoc drops unrecognised span and div classes, so mariner-markup.lua maps
  # them onto these. Renaming one here means renaming it there.
  tex <- build_pdf_preamble("mariner")
  for (cmd in c("defn", "term", "termref", "marineremph", "fontheadings", "fontbody")) {
    expect_match(tex, paste0("\\DeclareRobustCommand{\\", cmd, "}"), fixed = TRUE)
  }
  for (env in c("marinerdef", "marinerthm")) {
    expect_match(tex, paste0("\\newenvironment{", env, "}"), fixed = TRUE)
  }
})

test_that("the preamble carries the marker and the theme it came from", {
  expect_match(build_pdf_preamble("mariner"), GENERATED_MARKER, fixed = TRUE)
})

test_that("the preamble ends in exactly one newline", {
  # build_tokens() writes with cat() rather than writeLines() for this reason,
  # and the drift test compares bytes.
  tex <- build_pdf_preamble("mariner")
  expect_true(endsWith(tex, "\n"))
  expect_false(endsWith(tex, "\n\n"))
})

test_that("build_pdf_preamble validates the theme name", {
  expect_error(build_pdf_preamble("not-a-theme"))
})

# --- build_extension_yml -----------------------------------------------------

test_that("the manifest parses as YAML and contributes a pdf format", {
  yml <- yaml::yaml.load(build_extension_yml("mariner"))
  expect_identical(names(yml$contributes$formats), "pdf")
  expect_identical(yml$contributes$formats$pdf$`pdf-engine`, "xelatex")
})

test_that("the manifest's version matches the package's", {
  # A hand-written copy falling behind is silent, which is why this file is
  # generated at all.
  yml <- yaml::yaml.load(build_extension_yml("mariner"))
  expect_identical(yml$version, as.character(packageVersion("mariner")))
})

test_that("the manifest names both header includes and the markup filter", {
  pdf <- yaml::yaml.load(build_extension_yml("mariner"))$contributes$formats$pdf
  expect_setequal(
    vapply(pdf$`include-in-header`, function(x) x$file, character(1)),
    c("brand-preamble.tex", "_macros.tex")
  )
  expect_identical(pdf$filters, "mariner-markup.lua")
})

test_that("figures float rather than being pinned where Quarto would pin them", {
  # Quarto defaults fig-pos to 'H', so a figure that does not fit runs off the
  # bottom of the page and the footer prints on top of it.
  pdf <- yaml::yaml.load(build_extension_yml("mariner"))$contributes$formats$pdf
  expect_identical(pdf$`fig-pos`, "htbp")
})

test_that("the manifest requires the Quarto version the preflight check asks for", {
  yml <- yaml::yaml.load(build_extension_yml("mariner"))
  expect_identical(yml$`quarto-required`, ">=1.4.0")
})

test_that("the manifest carries the marker and ends in one newline", {
  yml <- build_extension_yml("mariner")
  expect_match(yml, GENERATED_MARKER, fixed = TRUE)
  expect_true(endsWith(yml, "\n"))
  expect_false(endsWith(yml, "\n\n"))
})

# --- generated_files and build_tokens ----------------------------------------

test_that("generated_files names both outputs, under the theme", {
  spec <- generated_files("mariner")
  expect_setequal(names(spec), c("brand-preamble.tex", "_extension.yml"))
  for (s in spec) {
    expect_identical(dirname(s$path), file.path("inst", "generated", "mariner"))
    expect_true(is.function(s$fn))
  }
})

test_that("build_tokens writes every generated file beneath the root it is given", {
  root <- withr::local_tempdir()
  written <- build_tokens(root = root, quiet = TRUE)

  expect_length(written, 2L * length(mariner_themes))
  expect_true(all(file.exists(written)))
  expect_true(all(startsWith(normalizePath(written), normalizePath(root))))
})

test_that("what build_tokens writes is byte-for-byte what the generator returns", {
  # cat() rather than writeLines(): the generators already end in a newline, and
  # a second one is the difference between pass and fail in the drift test.
  root <- withr::local_tempdir()
  build_tokens(root = root, quiet = TRUE)

  for (spec in generated_files("mariner")) {
    path <- file.path(root, spec$path)
    expect_identical(
      readBin(path, "raw", file.size(path)),
      charToRaw(spec$fn("mariner"))
    )
  }
})

test_that("generated files are written with LF endings on every platform", {
  # The byte comparison above catches this too, but only on a machine whose
  # text-mode connections translate -- so on macOS and Linux it passes for a
  # reason unrelated to what it is checking, and the failure surfaces on a
  # Windows CI runner as an opaque "0d 0a" vs "0a" diff. This says the thing
  # directly.
  #
  # CR is not legal content here: both generated files are ASCII source that
  # the generators build with "\n" throughout.
  root <- withr::local_tempdir()
  written <- build_tokens(root = root, quiet = TRUE)

  for (path in written) {
    bytes <- readBin(path, "raw", file.size(path))
    expect_false(
      as.raw(13) %in% bytes,
      label = paste0("CR byte in ", basename(path))
    )
  }
})

test_that("build_tokens names each file it wrote unless told to be quiet", {
  root <- withr::local_tempdir()
  said <- paste(capture_messages(build_tokens(root = root)), collapse = "")
  expect_match(said, "brand-preamble.tex", fixed = TRUE)
  expect_match(said, "_extension.yml", fixed = TRUE)
})
