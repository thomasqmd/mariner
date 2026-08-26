# Template discovery and resolution.

test_that("mariner_templates discovers packaged templates", {
  templates <- mariner_templates()
  expect_type(templates, "character")
  expect_true("report" %in% templates)
})

test_that("mariner_template_path resolves the default template", {
  path <- mariner_template_path()
  expect_true(file.exists(path))
  expect_equal(basename(path), "skeleton.qmd")
  expect_equal(basename(dirname(path)), "report")
})

test_that("mariner_template_path resolves by explicit name", {
  path <- mariner_template_path("report")
  expect_true(file.exists(path))
  expect_equal(basename(path), "skeleton.qmd")
})

test_that("mariner_template_path errors on unknown template naming available ones", {
  expect_error(
    mariner_template_path("nonexistent_template"),
    "No template named",
    fixed = FALSE
  )
})

test_that("mariner_template_path validates input argument", {
  expect_error(mariner_template_path(123))
  expect_error(mariner_template_path(c("a", "b")))
  expect_error(mariner_template_path(""))
})

test_that("a package with no templates directory lists none", {
  # system.file() returns "" on a miss, and "" is not a directory.
  expect_identical(mariner_templates(package = "stats"), character())
})

test_that("a template is only a template if it has a skeleton", {
  # The registry reports what generate_reports() can actually read.
  for (name in mariner_templates()) {
    expect_true(file.exists(mariner_template_path(name)))
    expect_identical(basename(mariner_template_path(name)), "skeleton.qmd")
  }
})

test_that("mariner_template_path says so when a package ships none at all", {
  expect_error(
    mariner_template_path("report", package = "stats"),
    "ships no mariner templates"
  )
})

test_that("mariner_template_path rejects a template name that is not one string", {
  expect_error(mariner_template_path(character()), "single non-empty string")
  expect_error(mariner_template_path(c("a", "b")), "single non-empty string")
  expect_error(mariner_template_path(""), "single non-empty string")
  expect_error(mariner_template_path(NA_character_), "single non-empty string")
  expect_error(mariner_template_path(1), "single non-empty string")
})
