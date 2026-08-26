# End-to-end Quarto PDF rendering tests.

local_dir <- function(env = parent.frame()) {
  withr::local_tempdir(.local_envir = env)
}

test_that("full PDF report renders end-to-end with theme", {
  skip_if_no_quarto()
  skip_if_no_latex()

  root <- local_dir()
  file.create(file.path(root, "DESCRIPTION"))
  dirs <- suppressMessages(mariner_setup_project(root = root))

  doc <- file.path(dirs$reports, "report.qmd")
  expect_true(file.exists(doc))

  out_zip <- file.path(dirs$zips, "report.zip")
  result <- suppressMessages(process_file(doc, output_zip = out_zip, assets_dir = dirs$assets))

  expect_true(file.exists(result))
  contents <- utils::unzip(result, list = TRUE)$Name
  expect_true("report.qmd" %in% contents)
  expect_true("report.pdf" %in% contents)
  expect_true("report.R" %in% contents)
  expect_false(any(grepl("_extensions", contents, fixed = TRUE)))
})

test_that("the markup classes reach their LaTeX commands", {
  skip_if_no_quarto()
  skip_if_no_latex()

  # The failure this guards is silent. Pandoc ignores span and div classes it
  # does not recognise, so a document that loses the filter -- or a command
  # renamed in the generator but not in mariner-markup.lua -- still renders,
  # still exits 0, and comes out as unmarked body text. Asserting on the PDF
  # would not catch it either; the intermediate .tex is where it shows.
  root <- local_dir()
  mariner_build_extension(root, quiet = TRUE)

  doc <- file.path(root, "markup.qmd")
  writeLines(c(
    "---",
    "title: \"Markup\"",
    "format:",
    "  mariner-pdf:",
    "    keep-tex: true",
    "toc: false",
    "---",
    "",
    "A [formal sum]{.defn}, a [basis]{.term}, a [combination]{.termref},",
    "an [unreduced]{.emph} thing, and *ordinary italics*.",
    "",
    "::: {.def}",
    "**Definition.** A body.",
    ":::",
    "",
    "::: {.thm}",
    "**Theorem.** Another body.",
    ":::",
    "",
    "A linked [support]{.defn #support} term."
  ), doc)

  quarto::quarto_render(doc, quiet = TRUE)

  tex <- paste(readLines(file.path(root, "markup.tex"), warn = FALSE), collapse = "\n")
  # Collapsed to one string first: pandoc wraps at the column, so a command and
  # its argument routinely land on different lines.
  tex <- gsub("\n", " ", tex)

  expect_match(tex, "\\\\defn\\{formal sum\\}", fixed = FALSE)
  expect_match(tex, "\\\\term\\{basis\\}", fixed = FALSE)
  expect_match(tex, "\\\\termref\\{combination\\}", fixed = FALSE)
  expect_match(tex, "\\\\marineremph\\{unreduced\\}", fixed = FALSE)
  expect_match(tex, "\\\\begin\\{marinerdef\\}", fixed = FALSE)
  expect_match(tex, "\\\\begin\\{marinerthm\\}", fixed = FALSE)
  # An identified .defn drives the cross-reference pair instead.
  expect_match(tex, "\\\\linkeddefn\\{support\\}\\{support\\}", fixed = FALSE)

  # And the one that is a regression rather than a feature: pandoc emits
  # \emph{} for every markdown italic, so a preamble that redefines \emph
  # restyles the whole document instead of the spans that asked for it.
  expect_match(tex, "\\\\emph\\{ordinary italics\\}", fixed = FALSE)
  expect_no_match(tex, "DeclareRobustCommand\\{\\\\emph\\}", fixed = FALSE)
})

test_that("rendering succeeds under a path with spaces", {
  skip_if_no_quarto()
  skip_if_no_latex()

  spaced_root <- withr::local_tempdir(pattern = "mariner render space ")
  file.create(file.path(spaced_root, "DESCRIPTION"))
  dirs <- suppressMessages(mariner_setup_project(root = spaced_root))

  doc <- file.path(dirs$reports, "report.qmd")
  out_zip <- file.path(dirs$zips, "report.zip")
  result <- suppressMessages(process_file(doc, output_zip = out_zip, assets_dir = dirs$assets))

  expect_true(file.exists(result))
  contents <- utils::unzip(result, list = TRUE)$Name
  expect_true("report.pdf" %in% contents)
})
