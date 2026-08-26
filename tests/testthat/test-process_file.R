# process_file(): render in a scratch directory, then bundle what came out.

zip_names <- function(path) utils::unzip(path, list = TRUE)$Name

# A .qmd written by hand, so a test does not depend on the packaged template.
write_qmd <- function(dir, name, format = "pdf", body = "Hello world.") {
  path <- file.path(dir, paste0(name, ".qmd"))
  writeLines(
    c("---", paste0("title: '", name, "'"), paste0("format: ", format),
      "---", body),
    path
  )
  path
}

local_dir <- function(env = parent.frame()) {
  withr::local_tempdir(.local_envir = env)
}

# --- bundling ----------------------------------------------------------------

test_that("process_file bundles source, script and output", {
  dir <- local_dir()
  doc <- suppressMessages(generate_reports(
    params_df = data.frame(chapter = 1, problem_numbers = 1, author = "Test"),
    template_name = "report",
    output_dir = dir
  ))
  expect_equal(tools::file_ext(doc), "qmd")

  out <- file.path(dir, "output_bundle.zip")
  result <- suppressMessages(process_file(doc, out))

  expect_equal(fs::path_norm(result), fs::path_norm(out))
  contents <- zip_names(out)
  expect_true(any(grepl("\\.qmd$", contents)))
  expect_true(any(grepl("\\.R$", contents)))
  expect_true(any(grepl("\\.pdf$", contents)))
})

test_that("the staged extension is never bundled", {
  # It is staged beside the document so xelatex can resolve the fonts, and on a
  # symlinking platform zipping it would dereference into the project's assets/.
  dir <- local_dir()
  doc <- write_qmd(dir, "simple")
  out <- file.path(dir, "b.zip")
  suppressMessages(process_file(doc, out))

  expect_false(any(grepl("_extensions", zip_names(out), fixed = TRUE)))
})

test_that("output_zip defaults into zip_files/", {
  dir <- local_dir()
  file.create(file.path(dir, "Thing.Rproj"))
  doc <- write_qmd(dir, "simple")

  result <- suppressMessages(process_file(doc, output_zip = NULL))

  expect_equal(fs::path_norm(dirname(result)), fs::path_norm(mariner_dirs(dir)$zips))
  expect_true(file.exists(result))
})

test_that("a document's _files directory travels with the output", {
  dir <- local_dir()
  doc <- write_qmd(
    dir, "report_with_plot", format = "html",
    body = c("```{r}", "plot(1:10)", "```")
  )
  out <- file.path(dir, "plot_bundle.zip")
  suppressMessages(process_file(doc, out))

  contents <- zip_names(out)
  expect_true("report_with_plot.qmd" %in% contents)
  expect_true("report_with_plot.html" %in% contents)
  expect_true(any(grepl("report_with_plot_files", contents)))
})

test_that("an html document keeps its _files when intermediates are dropped", {
  # _files/ is classed as OUTPUT, not intermediates: an html document without
  # it is broken, whereas for pdf it is merely redundant.
  dir <- local_dir()
  doc <- write_qmd(
    dir, "plotted", format = "html", body = c("```{r}", "plot(1:10)", "```")
  )
  out <- file.path(dir, "b.zip")
  suppressMessages(process_file(doc, out, include = c("source", "output")))

  contents <- zip_names(out)
  expect_true(any(grepl("plotted_files", contents)))
  expect_true("plotted.html" %in% contents)
})

# --- include -----------------------------------------------------------------

test_that("include selects what reaches the archive", {
  dir <- local_dir()
  doc <- write_qmd(dir, "simple")

  only_source <- file.path(dir, "src.zip")
  suppressMessages(process_file(doc, only_source, include = "source"))
  expect_equal(zip_names(only_source), "simple.qmd")

  no_script <- file.path(dir, "noscript.zip")
  suppressMessages(process_file(doc, no_script, include = c("source", "output")))
  expect_false(any(grepl("\\.R$", zip_names(no_script))))
  expect_true("simple.pdf" %in% zip_names(no_script))
})

test_that("include rejects an unknown category", {
  dir <- local_dir()
  doc <- write_qmd(dir, "simple")
  expect_error(process_file(doc, include = "everything"), "must be one of")
})

test_that("classify_artefacts sorts a render's leftovers", {
  # Unit-level, so the classification can be checked without a 7-second render.
  got <- classify_artefacts(
    c("r.qmd", "r.R", "r.pdf", "r.tex", "r_files", "r.log", "mystery.dat"),
    stem = "r"
  )

  expect_equal(got$source, "r.qmd")
  expect_equal(got$script, "r.R")
  expect_setequal(got$output, c("r.pdf", "r_files"))
  # Anything unrecognised travels rather than going missing in silence.
  expect_setequal(got$intermediates, c("r.tex", "r.log", "mystery.dat"))
})

# --- the staged extension (§0.4) ---------------------------------------------

test_that("a document using the branded format renders", {
  # The reason stage_extension() exists. brand-preamble.tex reaches the bundled
  # fonts through Path=_extensions/mariner/fonts/, which xelatex resolves
  # against the directory holding the .tex -- the document's own. Without the
  # extension staged beside the document this render finds its *format* and then
  # dies with "The font Lora-Regular cannot be found".
  #
  # This is the only test that proves the theme is reachable at render time, so
  # it renders for real rather than inspecting the scratch directory.
  skip_on_cran()
  skip_if_no_quarto()
  skip_if_no_latex()

  dir <- local_dir()
  mariner_build_extension(dir, "mariner", quiet = TRUE)

  doc <- write_qmd(dir, "branded", format = "mariner-pdf")
  out <- file.path(dir, "branded.zip")

  expect_no_error(
    suppressMessages(process_file(doc, out, assets_dir = dir))
  )
  expect_true("branded.pdf" %in% zip_names(out))
})

test_that("stage_extension serves from assets_dir when one is built", {
  dir <- local_dir()
  assets <- file.path(dir, "assets")
  mariner_build_extension(assets, "mariner", quiet = TRUE)

  scratch <- file.path(dir, "scratch")
  dir.create(scratch)
  unstage <- stage_extension(scratch, "mariner", assets)

  staged <- file.path(scratch, "_extensions", "mariner")
  expect_true(file.exists(file.path(staged, "brand-preamble.tex")))

  # Undoing the stage must not reach into the project's assets/.
  unstage()
  expect_true(file.exists(mariner_ext_dir(assets, "mariner")))
  expect_true(file.exists(
    file.path(mariner_ext_dir(assets, "mariner"), "brand-preamble.tex")
  ))
})

test_that("stage_extension builds into the scratch dir when there is no assets_dir", {
  dir <- local_dir()
  unstage <- stage_extension(dir, "mariner", assets_dir = NULL)

  staged <- file.path(dir, "_extensions", "mariner")
  expect_true(file.exists(file.path(staged, "brand-preamble.tex")))
  expect_true(file.exists(file.path(staged, "_extension.yml")))
  unstage()
})

# --- refusals ----------------------------------------------------------------

test_that("process_file errors on bad inputs", {
  expect_error(process_file("non_existent_file.qmd"), "does not exist")

  dir <- local_dir()
  invalid <- file.path(dir, "invalid.qmd")
  writeLines(
    c("---", "title: 'Invalid'", "---", "```{r}", "stop('error')", "```"),
    invalid
  )
  expect_error(
    suppressMessages(process_file(invalid, file.path(dir, "x.zip"))),
    "Failed while processing"
  )

  txt <- file.path(dir, "invalid.txt")
  writeLines("hello", txt)
  expect_error(process_file(txt), "must be a .qmd file", fixed = TRUE)
})

test_that("process_file rejects .Rmd input", {
  # The package is Quarto-only as of 0.2.0. The assertion is on the MESSAGE, so
  # it cannot start passing for the wrong reason if the file simply goes missing.
  dir <- local_dir()
  rmd <- file.path(dir, "legacy.Rmd")
  writeLines(c("---", "title: 'Legacy'", "---", "Hello."), rmd)

  expect_error(process_file(rmd), "must be a .qmd file", fixed = TRUE)
})

test_that("a failed render leaves no scratch directory behind", {
  dir <- local_dir()
  invalid <- file.path(dir, "invalid.qmd")
  writeLines(
    c("---", "title: 'Invalid'", "---", "```{r}", "stop('error')", "```"),
    invalid
  )
  before <- list.files(tempdir(), pattern = "^doc-bundle-")
  try(suppressMessages(process_file(invalid, file.path(dir, "x.zip"))), silent = TRUE)

  expect_equal(list.files(tempdir(), pattern = "^doc-bundle-"), before)
})
