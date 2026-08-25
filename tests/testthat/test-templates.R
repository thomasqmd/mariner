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
