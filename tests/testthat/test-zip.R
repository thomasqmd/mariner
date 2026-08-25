# Archive bundling, inclusion filters, overwrite and failure cleanup.

local_dir <- function(env = parent.frame()) {
  withr::local_tempdir(.local_envir = env)
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

test_that("include parameter selects exactly what is bundled", {
  skip_if_no_quarto()

  dir <- local_dir()
  doc <- write_qmd(dir, "simple")

  only_src <- file.path(dir, "src.zip")
  suppressMessages(process_file(doc, only_src, include = "source"))
  expect_equal(utils::unzip(only_src, list = TRUE)$Name, "simple.qmd")

  only_out <- file.path(dir, "out.zip")
  suppressMessages(process_file(doc, only_out, include = "output"))
  expect_false("simple.qmd" %in% utils::unzip(only_out, list = TRUE)$Name)
  expect_false("simple.R" %in% utils::unzip(only_out, list = TRUE)$Name)
})

test_that("re-running replaces an existing archive rather than appending", {
  skip_if_no_quarto()

  dir <- local_dir()
  out_zip <- file.path(dir, "bundle.zip")

  # Create an initial zip with a stale file
  stale_dir <- file.path(dir, "stale_scratch")
  dir.create(stale_dir)
  writeLines("old", file.path(stale_dir, "stale_entry.txt"))
  zip::zip(out_zip, files = "stale_entry.txt", root = stale_dir)
  expect_true("stale_entry.txt" %in% utils::unzip(out_zip, list = TRUE)$Name)

  doc <- write_qmd(dir, "fresh")
  suppressMessages(process_file(doc, out_zip))

  contents <- utils::unzip(out_zip, list = TRUE)$Name
  expect_false("stale_entry.txt" %in% contents)
  expect_true("fresh.qmd" %in% contents)
})

test_that("a failed render does not produce a zip archive", {
  skip_if_no_quarto()

  dir <- local_dir()
  bad_doc <- file.path(dir, "bad.qmd")
  writeLines(
    c("---", "title: Bad", "---", "```{r}", "stop('render failure')", "```"),
    bad_doc
  )
  out_zip <- file.path(dir, "bad.zip")

  expect_error(
    suppressMessages(process_file(bad_doc, out_zip)),
    "Failed while processing"
  )
  expect_false(file.exists(out_zip))
})
