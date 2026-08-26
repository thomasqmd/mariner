# Parallel batch processing tests across future workers.

library(future)

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

test_that("process_files executes across parallel workers", {
  skip_if_no_quarto()
  skip_on_covr()
  skip_if(
    isTRUE(pkgload::is_dev_package("mariner")),
    "mariner is loaded from source; a multisession worker cannot attach it"
  )

  old_plan <- future::plan(future::multisession, workers = 2)
  on.exit(future::plan(old_plan), add = TRUE)

  dir <- local_dir()
  doc1 <- write_qmd(dir, "worker_doc1")
  doc2 <- write_qmd(dir, "worker_doc2")

  zip_dir <- file.path(dir, "zips")
  paths <- suppressMessages(process_files(c(doc1, doc2), output_dir = zip_dir))

  expect_length(paths, 2L)
  expect_true(all(!is.na(paths)))
  expect_true(all(file.exists(paths)))
})
