# tests/testthat/test-process_files.R
library(future)

create_dummy_rmd <- function(dir, name, content = c("---", "title: 'Test'", "---")) {
  path <- file.path(dir, name)
  writeLines(content, path)
  return(path)
}

# ---
# Test Case 1: Sequential processing (Existing Test)
test_that("process_files works sequentially with mixed success and failure", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  valid_rmd <- create_dummy_rmd(temp_dir, "valid.Rmd")
  invalid_rmd <- create_dummy_rmd(
    temp_dir, "invalid.Rmd",
    content = c("---", "title: 'Invalid'", "---", "```{r}", "stop('error')", "```")
  )
  input_list <- c(valid_rmd, invalid_rmd)

  suppressMessages({
    output_paths <- process_files(input_list)
  })

  expect_length(output_paths, 2)
  expect_true(!is.na(output_paths[1]))
  expect_true(is.na(output_paths[2]))
  expect_true(file.exists(output_paths[1]))
})

# ---
# IMPROVEMENT: Add a test specifically for parallel execution
test_that("process_files works correctly in parallel with a future plan", {
  # --- 1. Setup: Set a parallel plan for this test only ---
  # We use on.exit() to ensure the plan is reset to sequential after the
  # test, which prevents interference with other tests.
  old_plan <- future::plan(future::multisession, workers = 2)
  on.exit(future::plan(old_plan), add = TRUE)

  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  # Create several valid Rmd files to process in parallel
  input_list <- purrr::map_chr(
    c("A.Rmd", "B.Rmd", "C.Rmd"),
    ~ create_dummy_rmd(temp_dir, .x)
  )

  # --- 2. Execute in parallel ---
  suppressMessages({
    output_paths <- process_files(input_list)
  })

  # --- 3. Assertions ---
  # The assertions are the same as the sequential test; we are just
  # confirming that it runs without errors in a parallel context.
  expect_length(output_paths, 3)
  expect_true(all(!is.na(output_paths)))
  expect_true(all(file.exists(output_paths)))
})

# ---
# Test Case 3: Empty input list (Existing Test)
test_that("process_files handles an empty input vector gracefully", {
  suppressMessages({
    output_paths <- process_files(character(0))
  })
  expect_length(output_paths, 0)
})
