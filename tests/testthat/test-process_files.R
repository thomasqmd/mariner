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

  # A valid .Rmd file
  valid_rmd <- file.path(temp_dir, "valid.Rmd")
  writeLines(
    c("---", "title: 'Valid Rmd'", "---", "A simple Rmd."),
    valid_rmd
  )

  # An invalid .qmd file
  invalid_qmd <- file.path(temp_dir, "invalid.qmd")
  writeLines(
    c("---", "title: 'Invalid'", "---", "```{r}", "stop('error')", "```"),
    invalid_qmd
  )

  input_list <- c(valid_qmd, valid_rmd, invalid_qmd)

  # --- 2. Execute ---
  suppressMessages({
    output_paths <- process_files(input_list)
  })

  # --- 3. Assertions ---
  expect_length(output_paths, 3)
  expect_true(!is.na(output_paths[1])) # valid .qmd
  expect_true(!is.na(output_paths[2])) # valid .Rmd
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
