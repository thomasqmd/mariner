# process_files(): the sequential/parallel wrapper.

library(future)

local_dir <- function(env = parent.frame()) {
  withr::local_tempdir(.local_envir = env)
}

write_qmd <- function(dir, name, format = "pdf", body = "A simple document.") {
  path <- file.path(dir, paste0(name, ".qmd"))
  writeLines(
    c("---", paste0("title: '", name, "'"), paste0("format: ", format),
      "---", body),
    path
  )
  path
}

test_that("process_files places zips in the specified output_dir", {
  dir <- local_dir()
  docs <- suppressMessages(generate_reports(
    params_df = data.frame(
      chapter = 1, problem_numbers = 1:2, author = "Test Author"
    ),
    template_name = "simple_report",
    output_dir = dir
  ))

  zip_dir <- file.path(dir, "zip_outputs")
  paths <- suppressMessages(process_files(docs, output_dir = zip_dir))

  expect_length(paths, 2L)
  expect_true(all(!is.na(paths)))
  expect_true(all(file.exists(paths)))
  expect_true(all(dirname(paths) == fs::path_norm(zip_dir)))
})

test_that("a NULL output_dir resolves per input file", {
  # Two documents in two different project roots. Resolving once in the parent
  # from getwd() would put both bundles in the same place.
  root_a <- local_dir()
  root_b <- local_dir()
  file.create(file.path(root_a, "A.Rproj"))
  file.create(file.path(root_b, "B.Rproj"))

  docs <- c(write_qmd(root_a, "a"), write_qmd(root_b, "b"))
  paths <- suppressMessages(process_files(docs))

  expect_equal(
    fs::path_norm(dirname(paths)),
    fs::path_norm(c(mariner_dirs(root_a)$zips, mariner_dirs(root_b)$zips))
  )
})

test_that("a failure is an NA and its message is reported, not discarded", {
  dir <- local_dir()
  good <- write_qmd(dir, "good")
  bad <- file.path(dir, "bad.qmd")
  writeLines(
    c("---", "title: 'Bad'", "---", "```{r}", "stop('boom')", "```"),
    bad
  )

  zip_dir <- file.path(dir, "zips")
  expect_message(
    paths <- process_files(c(good, bad), output_dir = zip_dir),
    "bad.qmd"
  )

  expect_false(is.na(paths[[1]]))
  expect_true(is.na(paths[[2]]))
  expect_true(file.exists(paths[[1]]))
})

test_that("include is forwarded to each file", {
  dir <- local_dir()
  docs <- c(write_qmd(dir, "one"), write_qmd(dir, "two"))
  zip_dir <- file.path(dir, "zips")

  paths <- suppressMessages(
    process_files(docs, output_dir = zip_dir, include = "source")
  )

  expect_equal(utils::unzip(paths[[1]], list = TRUE)$Name, "one.qmd")
  expect_equal(utils::unzip(paths[[2]], list = TRUE)$Name, "two.qmd")
})

test_that("process_files handles an empty input vector gracefully", {
  paths <- suppressMessages(process_files(character(0)))
  expect_length(paths, 0L)
})

test_that("process_files works in parallel", {
  # A multisession worker is a FRESH R process: it attaches mariner from the
  # library, not from the parent session. Under devtools::test() / load_all()
  # the package is loaded from source and is not installed anywhere the worker
  # can reach, so every future fails to attach it -- a failure about the test
  # setup, not about the code. R CMD check installs first and runs this for real.
  #
  # requireNamespace() is no good as the test: pkgload registers the namespace,
  # so it answers TRUE for a source load too. Asking pkgload directly is the
  # question that actually distinguishes the two.
  skip_if(
    isTRUE(pkgload::is_dev_package("mariner")),
    "mariner is loaded from source; a multisession worker cannot attach it"
  )

  old_plan <- future::plan(future::multisession, workers = 2)
  on.exit(future::plan(old_plan), add = TRUE)

  dir <- local_dir()
  valid <- suppressMessages(generate_reports(
    params_df = data.frame(chapter = 1, problem_numbers = 1, author = "Valid"),
    template_name = "simple_report",
    output_dir = dir
  ))
  simple <- write_qmd(dir, "simple", format = "html")
  invalid <- file.path(dir, "invalid.qmd")
  writeLines(
    c("---", "title: 'Invalid'", "---", "```{r}", "stop('error')", "```"),
    invalid
  )

  zip_dir <- file.path(dir, "zips")
  paths <- suppressMessages(
    process_files(c(valid, simple, invalid), output_dir = zip_dir)
  )

  expect_length(paths, 3L)
  expect_true(!is.na(paths[[1]]))
  expect_true(!is.na(paths[[2]]))
  expect_true(is.na(paths[[3]]))
  expect_true(all(file.exists(paths[1:2])))
})
