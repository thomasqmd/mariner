# Paths with spaces in them.
#
# Not a hypothetical: this package's own checkout lives under
# `.../OneDrive-Personal/Personal R Projects/mariner`, and a Windows student's
# temp directory is `C:\Users\First Last\AppData\Local\Temp\...`. Every render
# in this package happens in a scratch directory and shells out to the Quarto
# CLI, which is a separate process that re-resolves the paths we hand it -- so a
# space is a quoting question at every boundary, and a boundary that gets it
# wrong fails with "file not found" naming a path that visibly exists.
#
# These tests put the space in the caller's path rather than in the scratch
# directory, because the scratch directory is tempfile()'s to name and the
# caller's is not.

spaced_dir <- function(env = parent.frame()) {
  withr::local_tempdir(pattern = "mariner space ", .local_envir = env)
}

write_qmd <- function(dir, name, format = "pdf", body = "Hello world.") {
  path <- file.path(dir, paste0(name, ".qmd"))
  writeLines(
    c("---", paste0("title: '", name, "'"), paste0("format: ", format),
      "---", body),
    path
  )
  path
}

test_that("the scratch directory is a real path", {
  skip_if_no_quarto()
  dir <- spaced_dir()
  doc <- write_qmd(dir, "spaced")

  # macOS tempdir() is /var/..., a symlink to /private/var/...; Windows can hand
  # back an 8.3 short name. Either way the directory Quarto runs in is not
  # spelled the way tempfile() spelled it, and "it rendered but the outputs are
  # not where I looked" is what that costs. Asserted through the outcome rather
  # than by reaching into process_file(): the archive lands where asked.
  out <- file.path(dir, "spaced bundle.zip")
  result <- suppressMessages(process_file(doc, out))

  expect_true(file.exists(result))
  expect_true("spaced.qmd" %in% utils::unzip(result, list = TRUE)$Name)
})

test_that("process_file renders a document whose own name has a space", {
  skip_if_no_quarto()
  dir <- spaced_dir()
  doc <- write_qmd(dir, "report with spaces")
  out <- file.path(dir, "b.zip")

  result <- suppressMessages(process_file(doc, out))

  contents <- utils::unzip(result, list = TRUE)$Name
  expect_true("report with spaces.qmd" %in% contents)
  # SLUGIFIED, and not by us. Quarto names its output after a sanitised form of
  # the input stem, so the source keeps its spaces and the PDF loses them. The
  # assertion spells out the name Quarto actually writes rather than the one it
  # was handed, because the two differ and a test asserting the input stem would
  # be asserting something no render produces.
  expect_true("report-with-spaces.pdf" %in% contents)
})

test_that("a spaced html document keeps its _files directory", {
  skip_if_no_quarto()
  # The bug the slugified name hides. classify_artefacts() used to look for
  # `<input stem>_files`, so `report-with-spaces_files/` fell through to
  # `intermediates`: invisible under the default include, and a BROKEN html
  # bundle the moment someone asked for source and output only.
  dir <- spaced_dir()
  doc <- write_qmd(
    dir, "plotted with spaces", format = "html",
    body = c("```{r}", "plot(1:10)", "```")
  )
  out <- file.path(dir, "b.zip")
  suppressMessages(process_file(doc, out, include = c("source", "output")))

  contents <- utils::unzip(out, list = TRUE)$Name
  expect_true(any(grepl("_files/", contents, fixed = TRUE)))
  expect_true(any(grepl("\\.html$", contents)))
})

test_that("the default zip location survives a spaced project root", {
  dir <- spaced_dir()
  file.create(file.path(dir, "Spaced Project.Rproj"))
  doc <- write_qmd(dir, "simple")

  result <- suppressMessages(process_file(doc, output_zip = NULL))

  expect_true(file.exists(result))
  expect_equal(
    fs::path_norm(dirname(result)),
    fs::path_norm(mariner_dirs(dir)$zips)
  )
})

test_that("generate_reports writes into a spaced output_dir", {
  dir <- spaced_dir()
  files <- suppressMessages(generate_reports(
    params_df = data.frame(chapter = 1, problem_numbers = 1, author = "A"),
    output_dir = file.path(dir, "my reports")
  ))

  expect_true(all(file.exists(files)))
  expect_equal(basename(files), "Report-1_1.qmd")
})

test_that("the project scaffolding works under a spaced root", {
  # No render here, so this is cheap -- but mariner_setup_project() composes
  # paths for four different things, and a root with a space is the input that
  # finds the one place that used paste() instead of file.path().
  dir <- spaced_dir()
  dirs <- suppressMessages(mariner_setup_project(root = dir))

  expect_true(all(dir.exists(unlist(dirs, use.names = FALSE))))
  expect_equal(extension_missing(mariner_ext_dir(dirs$reports, "mariner")), character())
  expect_true(file.exists(file.path(dirs$reports, "report.qmd")))
})

test_that("mariner_check_setup passes under a spaced, set-up root", {
  dir <- spaced_dir()
  suppressMessages(mariner_setup_project(root = dir))

  report <- mariner_check_setup(root = dir, quiet = TRUE)
  expect_equal(report[report$check == "Project folders", ]$status, "ok")
  expect_equal(report[report$check == "Theme in reports/", ]$status, "ok")
})
