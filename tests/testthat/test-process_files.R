# tests/testthat/test-process_files.R
library(future)

# Test Case 1: Sequential processing with an output directory specified
test_that("process_files places zips in the specified output_dir", {
  # --- 1. Setup ---
  temp_dir <- tempfile("test-")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  # Create Rmd files in the base temp directory
  # Corrected the data frame to use the new variable names
  rmd_files <- generate_reports(
    params_df = data.frame(chapter = 1, problem_numbers = 1:2, author = "Test Author"),
    template_name = "simple_report",
    output_dir = temp_dir
  )

  # Define a separate subdirectory for the zip files
  zip_dir <- file.path(temp_dir, "zip_outputs")

  # --- 2. Execute ---
  suppressMessages({
    output_paths <- process_files(rmd_files, output_dir = zip_dir)
  })

  # --- 3. Assertions ---
  expect_length(output_paths, 2)
  expect_true(all(!is.na(output_paths)))
  expect_true(all(file.exists(output_paths)))
  # Crucially, check that the output zips are in the correct directory
  expect_true(all(dirname(output_paths) == fs::path_norm(zip_dir)))
})


# Test Case 2: Parallel processing with mixed success and failure
test_that("process_files works in parallel with mixed success", {
  # --- 1. Setup ---
  old_plan <- future::plan(future::multisession, workers = 2)
  on.exit(future::plan(old_plan), add = TRUE)

  temp_dir <- tempfile("test-")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  valid_rmd <- generate_reports(
    params_df = data.frame(a = 1, b = 1, author = "Valid Author"),
    template_name = "simple_report",
    output_dir = temp_dir
  )

  invalid_rmd <- file.path(temp_dir, "invalid.Rmd")
  writeLines(
    c("---", "title: 'Invalid'", "---", "```{r}", "stop('error')", "```"),
    invalid_rmd
  )

  input_list <- c(valid_rmd, invalid_rmd)

  # --- 2. Execute ---
  suppressMessages({
    output_paths <- process_files(input_list)
  })

  # --- 3. Assertions ---
  expect_length(output_paths, 2)
  expect_true(!is.na(output_paths[1]))
  expect_true(is.na(output_paths[2]))
  expect_true(file.exists(output_paths[1]))
})


# Test Case 3: Empty input list
test_that("process_files handles an empty input vector gracefully", {
  suppressMessages({
    output_paths <- process_files(character(0))
  })
  expect_length(output_paths, 0)
})
