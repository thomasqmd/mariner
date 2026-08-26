# Project settings: _mariner.yml, and how generate_reports() reads it.

# A directory that mariner_project_root() will accept as a root in its own
# right, so read_project_config() resolves to it rather than climbing past it.
# DESCRIPTION is the cheapest of the four markers to fake.
local_project <- function(env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  dir <- normalizePath(dir, winslash = "/")
  file.create(file.path(dir, "DESCRIPTION"))
  dir
}

# A template declaring the two params these tests care about. Written rather
# than borrowed from inst/, so a change to the packaged skeleton cannot make
# these pass or fail for a reason they are not about.
write_template <- function(dir, params = c("chapter: 1", 'author: "Placeholder"')) {
  path <- file.path(dir, "tmpl.qmd")
  writeLines(c("---", "title: T", "params:", paste0("  ", params), "---", "body"), path)
  path
}

# --- read_project_config -----------------------------------------------------

test_that("an absent settings file is an empty list, not an error", {
  expect_identical(read_project_config(local_project()), list())
})

test_that("an empty settings file is an empty list", {
  dir <- local_project()
  file.create(file.path(dir, "_mariner.yml"))
  expect_identical(read_project_config(dir), list())
})

test_that("a settings file holding a bare scalar is an empty list", {
  # `yaml.load_file()` returns a length-one character vector here, not a list.
  # Returning it unchanged would make config$author NULL by luck rather than by
  # design, and config[names] would subset a vector.
  dir <- local_project()
  writeLines("just a string", file.path(dir, "_mariner.yml"))
  expect_identical(read_project_config(dir), list())
})

test_that("unparseable settings warn rather than failing silently", {
  dir <- local_project()
  writeLines(c("author: [unclosed"), file.path(dir, "_mariner.yml"))
  expect_warning(read_project_config(dir), "Could not read")
})

# --- write_project_config ----------------------------------------------------

test_that("write_project_config round-trips through the reader", {
  dir <- local_project()
  write_project_config(dir, list(author = "Alice Smith"))
  expect_equal(read_project_config(dir)$author, "Alice Smith")
})

test_that("writing twice replaces the key rather than appending a second one", {
  # YAML takes the last of two duplicate keys, so an append-based writer would
  # LOOK correct to the reader while leaving a file with two author lines.
  dir <- local_project()
  write_project_config(dir, list(author = "First"))
  write_project_config(dir, list(author = "Second"))

  lines <- readLines(file.path(dir, "_mariner.yml"))
  expect_length(grep("^author:", lines), 1L)
  expect_equal(read_project_config(dir)$author, "Second")
})

test_that("writing one key preserves the others", {
  dir <- local_project()
  write_project_config(dir, list(author = "Alice", course = "STAT 3010"))
  write_project_config(dir, list(author = "Bob"))

  cfg <- read_project_config(dir)
  expect_equal(cfg$author, "Bob")
  expect_equal(cfg$course, "STAT 3010")
})

# --- mariner_setup_project(author = ) ----------------------------------------

test_that("setup writes the author and reports it", {
  dir <- local_project()
  suppressMessages(mariner_setup_project(
    root = dir, template = NULL, author = "Alice Smith"
  ))
  expect_equal(read_project_config(dir)$author, "Alice Smith")
})

test_that("setup without an author writes no settings file", {
  # Absent beats present-and-empty: a `_mariner.yml` holding only a comment
  # header would have to be opened to discover it says nothing.
  dir <- local_project()
  suppressMessages(mariner_setup_project(root = dir, template = NULL))
  expect_false(file.exists(file.path(dir, "_mariner.yml")))
})

test_that("re-running setup does not clear an author set earlier", {
  dir <- local_project()
  suppressMessages(mariner_setup_project(
    root = dir, template = NULL, author = "Alice Smith"
  ))
  suppressMessages(mariner_setup_project(root = dir, template = NULL))
  expect_equal(read_project_config(dir)$author, "Alice Smith")
})

test_that("setup warns when no author is configured", {
  dir <- local_project()
  expect_message(
    mariner_setup_project(root = dir, template = NULL),
    "No author is set"
  )
})

test_that("setup is quiet about the author once one is set", {
  dir <- local_project()
  expect_no_message(
    mariner_setup_project(root = dir, template = NULL, author = "Alice"),
    message = "No author is set"
  )
})

test_that("a non-string author is refused before anything is written", {
  dir <- local_project()
  for (bad in list(c("A", "B"), 42, NA_character_, "", "   ")) {
    expect_error(
      mariner_setup_project(root = dir, template = NULL, author = bad),
      "single non-empty string"
    )
  }
  # The abort happens before step 1, so no folders were left behind.
  expect_false(dir.exists(file.path(dir, "reports")))
})

test_that("an author is written whatever overwrite says", {
  # overwrite guards the scaffolded files a student may have edited. Passing
  # `author` IS the instruction to change this one.
  dir <- local_project()
  suppressMessages(mariner_setup_project(
    root = dir, template = NULL, author = "First"
  ))
  suppressMessages(mariner_setup_project(
    root = dir, template = NULL, author = "Second", overwrite = FALSE
  ))
  expect_equal(read_project_config(dir)$author, "Second")
})

# --- generate_reports() reading the settings ---------------------------------

test_that("a configured author fills the template parameter", {
  dir <- local_project()
  dir.create(file.path(dir, "reports"))
  write_project_config(dir, list(author = "Alice Smith"))
  tmpl <- write_template(dir)

  files <- suppressMessages(generate_reports(
    params_df = data.frame(chapter = 1:2),
    template_path = tmpl,
    output_dir = file.path(dir, "reports"),
    file_name = "r{chapter}"
  ))

  for (f in files) {
    expect_equal(front_matter(f)$params$author, "Alice Smith")
  }
})

test_that("a params_df column beats the configured author", {
  dir <- local_project()
  dir.create(file.path(dir, "reports"))
  write_project_config(dir, list(author = "Alice Smith"))
  tmpl <- write_template(dir)

  f <- suppressMessages(generate_reports(
    params_df = data.frame(chapter = 1, author = "Bob Jones"),
    template_path = tmpl,
    output_dir = file.path(dir, "reports"),
    file_name = "r{chapter}"
  ))

  expect_equal(front_matter(f)$params$author, "Bob Jones")
})

test_that("the configured author beats the template default", {
  dir <- local_project()
  dir.create(file.path(dir, "reports"))
  write_project_config(dir, list(author = "Alice Smith"))
  tmpl <- write_template(dir)

  f <- suppressMessages(generate_reports(
    params_df = data.frame(chapter = 1),
    template_path = tmpl,
    output_dir = file.path(dir, "reports"),
    file_name = "r{chapter}"
  ))

  expect_false(identical(front_matter(f)$params$author, "Placeholder"))
})

test_that("a setting the template does not declare is not injected", {
  # A project-wide `author` must not add an `author` parameter to a template
  # that has none: that changes the front matter of a document whose author is
  # deliberately elsewhere.
  dir <- local_project()
  dir.create(file.path(dir, "reports"))
  write_project_config(dir, list(author = "Alice Smith"))
  tmpl <- write_template(dir, params = "chapter: 1")

  f <- suppressMessages(generate_reports(
    params_df = data.frame(chapter = 1),
    template_path = tmpl,
    output_dir = file.path(dir, "reports"),
    file_name = "r{chapter}"
  ))

  expect_null(front_matter(f)$params$author)
})

test_that("settings are read from the output project, not the working directory", {
  # generate_reports() resolves the config from output_dir, so a batch written
  # into another project gets that project's author. A parallel worker's
  # working directory is not the caller's, and neither is a student's when they
  # run this from a subdirectory.
  here <- local_project()
  there <- local_project()
  dir.create(file.path(there, "reports"))
  write_project_config(here, list(author = "Wrong"))
  write_project_config(there, list(author = "Right"))
  tmpl <- write_template(here)

  withr::local_dir(here)
  f <- suppressMessages(generate_reports(
    params_df = data.frame(chapter = 1),
    template_path = tmpl,
    output_dir = file.path(there, "reports"),
    file_name = "r{chapter}"
  ))

  expect_equal(front_matter(f)$params$author, "Right")
})

test_that("an output_dir outside any project reads no settings", {
  # What keeps the examples and the rest of the suite hermetic: a tempdir is
  # its own root, so a _mariner.yml in whatever project the runner happens to
  # sit in cannot reach them.
  dir <- withr::local_tempdir()
  tmpl <- write_template(dir)

  f <- suppressMessages(generate_reports(
    params_df = data.frame(chapter = 1),
    template_path = tmpl,
    output_dir = dir,
    file_name = "r{chapter}"
  ))

  expect_equal(front_matter(f)$params$author, "Placeholder")
})
