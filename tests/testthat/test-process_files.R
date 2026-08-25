# tests/testthat/test-process_files.R
library(future)

# Test Case 1: Sequential processing with an output directory specified
test_that("process_files places zips in the specified output_dir", {
  # --- 1. Setup ---
  temp_dir <- tempfile("test-")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  # Create document files (will be .qmd by default) in the base temp directory
  doc_files <- generate_reports(
    params_df = data.frame(
      chapter = 1,
      problem_numbers = 1:2,
      author = "Test Author"
    ),
    template_name = "simple_report",
    output_dir = temp_dir
  )

  # Define a separate subdirectory for the zip files
  zip_dir <- file.path(temp_dir, "zip_outputs")

  # --- 2. Execute ---
  suppressMessages({
    output_paths <- process_files(doc_files, output_dir = zip_dir)
  })

  # --- 3. Assertions ---
  expect_length(output_paths, 2)
  expect_true(all(!is.na(output_paths)))
  expect_true(all(file.exists(output_paths)))
  # Crucially, check that the output zips are in the correct directory
  expect_true(all(dirname(output_paths) == fs::path_norm(zip_dir)))
})


# Test Case 2: Parallel processing with mixed file types and failures
test_that("process_files works in parallel with mixed types and success", {
  # A multisession worker is a FRESH R process: it attaches mariner from the
  # library, not from the parent session. Under devtools::test() / load_all()
  # the package is loaded from source and is not installed anywhere the worker
  # can reach, so every future fails to attach it -- a failure about the test
  # setup, not about the code. R CMD check installs first and runs this for
  # real.
  #
  # requireNamespace() is no good as the test: pkgload registers the namespace,
  # so it answers TRUE for a source load too. Asking pkgload directly is the
  # question that actually distinguishes the two.
  skip_if(
    isTRUE(pkgload::is_dev_package("mariner")),
    "mariner is loaded from source; a multisession worker cannot attach it"
  )

  # --- 1. Setup ---
  old_plan <- future::plan(future::multisession, workers = 2)
  on.exit(future::plan(old_plan), add = TRUE)

  temp_dir <- tempfile("test-")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  # A valid .qmd file
  valid_qmd <- generate_reports(
    params_df = data.frame(
      chapter = 1,
      problem_numbers = 1,
      author = "Valid Author"
    ),
    template_name = "simple_report",
    output_dir = temp_dir
  )

  # A second valid .qmd file, written by hand
  simple_qmd <- file.path(temp_dir, "simple.qmd")
  writeLines(
    c("---", "title: 'Simple'", "format: html", "---", "A simple document."),
    simple_qmd
  )

  # An invalid .qmd file
  invalid_qmd <- file.path(temp_dir, "invalid.qmd")
  writeLines(
    c("---", "title: 'Invalid'", "---", "```{r}", "stop('error')", "```"),
    invalid_qmd
  )

  input_list <- c(valid_qmd, simple_qmd, invalid_qmd)

  # --- 2. Execute ---
  suppressMessages({
    output_paths <- process_files(input_list)
  })

  # --- 3. Assertions ---
  expect_length(output_paths, 3)
  expect_true(!is.na(output_paths[1])) # valid .qmd from the template
  expect_true(!is.na(output_paths[2])) # valid hand-written .qmd
  expect_true(is.na(output_paths[3])) # invalid .qmd
  expect_true(file.exists(output_paths[1]))
  expect_true(file.exists(output_paths[2]))
})


# Test Case 3: Empty input list
test_that("process_files handles an empty input vector gracefully", {
  suppressMessages({
    output_paths <- process_files(character(0))
  })
  expect_length(output_paths, 0)
})
