# Scaffolding: root resolution, the folder list, and the attach guard.

# A directory that satisfies mariner_looks_like_project(). `marker` picks which
# of the four signals it carries, so the guard can be tested one signal at a
# time rather than only in aggregate.
make_project <- function(marker = "DESCRIPTION") {
  dir <- withr::local_tempdir(.local_envir = parent.frame())
  # normalizePath, because macOS hands out /var/folders/... tempdirs that are
  # symlinks to /private/var/folders/..., and every path this package returns
  # has been normalised. Comparing an un-normalised tempdir against a normalised
  # result fails on macOS and passes everywhere else -- the worst kind of test.
  dir <- normalizePath(dir, winslash = "/")
  switch(marker,
    ".Rproj"      = file.create(file.path(dir, "Thing.Rproj")),
    ".git"        = dir.create(file.path(dir, ".git")),
    file.create(file.path(dir, marker))
  )
  dir
}

# --- mariner_looks_like_project ----------------------------------------------

test_that("all four markers make a directory a project", {
  for (marker in c(".Rproj", "_quarto.yml", "DESCRIPTION", ".git")) {
    expect_true(
      mariner_looks_like_project(make_project(marker)),
      info = marker
    )
  }
})

test_that("an unmarked directory is not a project", {
  expect_false(mariner_looks_like_project(withr::local_tempdir()))
})

test_that("a nonexistent directory is not a project", {
  expect_false(mariner_looks_like_project(file.path(tempdir(), "no-such-dir")))
})

# --- mariner_project_root ----------------------------------------------------

test_that("the root search walks up to the nearest marker", {
  root <- make_project("DESCRIPTION")
  deep <- file.path(root, "a", "b", "c")
  dir.create(deep, recursive = TRUE)

  expect_equal(mariner_project_root(deep), root)
})

test_that("the nearest marker wins over a further one", {
  outer <- make_project("DESCRIPTION")
  inner <- file.path(outer, "inner")
  dir.create(inner)
  file.create(file.path(inner, "inner.Rproj"))

  expect_equal(mariner_project_root(inner), inner)
})

test_that(".git is not a root marker, though it is a project marker", {
  # The asymmetry documented in R/setup.R: a home directory under version
  # control must not become every student's project root.
  dir <- make_project(".git")
  child <- file.path(dir, "child")
  dir.create(child)

  expect_true(mariner_looks_like_project(dir))
  expect_equal(mariner_project_root(child), normalizePath(child, winslash = "/"))
})

test_that("the option beats the search", {
  root <- make_project("DESCRIPTION")
  elsewhere <- normalizePath(withr::local_tempdir(), winslash = "/")

  withr::with_options(list(mariner.project_root = elsewhere), {
    expect_equal(mariner_project_root(root), elsewhere)
  })
})

test_that("an unmarked directory resolves to itself, not to /", {
  # The walk terminates at the filesystem root. Returning "/" from it would put
  # a reports/ folder at the top of the disk.
  dir <- normalizePath(withr::local_tempdir(), winslash = "/")
  expect_equal(mariner_project_root(dir), dir)
})

# --- mariner_dirs ------------------------------------------------------------

test_that("mariner_dirs returns the three folders under the root", {
  root <- normalizePath(withr::local_tempdir(), winslash = "/")
  dirs <- mariner_dirs(root)

  expect_named(dirs, c("assets", "reports", "zips"))
  expect_equal(dirs$assets, file.path(root, "assets"))
  expect_equal(dirs$reports, file.path(root, "reports"))
  # The one place the element name and the directory name differ, on purpose.
  expect_equal(dirs$zips, file.path(root, "zip_files"))
})

test_that("mariner_dirs reports paths without creating them", {
  root <- withr::local_tempdir()
  dirs <- mariner_dirs(root)
  expect_false(any(dir.exists(unlist(dirs))))
})

test_that("an explicit root beats the option", {
  root <- normalizePath(withr::local_tempdir(), winslash = "/")
  withr::with_options(list(mariner.project_root = tempdir()), {
    expect_equal(dirname(mariner_dirs(root)$reports), root)
  })
})

# --- mariner_setup_project ---------------------------------------------------

test_that("setup creates the folders, the theme, and a starter report", {
  root <- make_project("DESCRIPTION")
  dirs <- suppressMessages(mariner_setup_project(root = root))

  expect_true(all(dir.exists(unlist(dirs))))

  ext_name <- mariner_ext_name("baylor")
  assets_ext <- file.path(dirs$assets, "_extensions", ext_name)
  reports_ext <- file.path(dirs$reports, "_extensions", ext_name)

  expect_true(dir.exists(assets_ext))
  expect_true(dir.exists(reports_ext))
  expect_true(file.exists(file.path(dirs$reports, "report.qmd")))

  # The copy in reports/ is what xelatex actually reads. If it were a partial
  # copy the render would fail with a missing-font error naming nothing, so
  # assert the two trees match file for file rather than merely that both exist.
  expect_equal(
    sort(list.files(reports_ext, recursive = TRUE)),
    sort(list.files(assets_ext, recursive = TRUE))
  )
})

test_that("setup gitignores the build outputs", {
  root <- make_project("DESCRIPTION")
  suppressMessages(mariner_setup_project(root = root))

  ignored <- readLines(file.path(root, ".gitignore"))
  expect_true(all(
    c("zip_files/", "assets/_extensions/", "reports/_extensions/") %in% ignored
  ))
})

test_that("setup is idempotent", {
  root <- make_project("DESCRIPTION")
  suppressMessages(mariner_setup_project(root = root))

  before <- sort(list.files(root, recursive = TRUE, all.files = TRUE))
  starter <- file.path(root, "reports", "report.qmd")
  writeLines("edited by the student", starter)

  expect_no_error(suppressMessages(mariner_setup_project(root = root)))

  after <- sort(list.files(root, recursive = TRUE, all.files = TRUE))
  expect_equal(after, before)
  # overwrite = FALSE is the whole point: a second run must not eat the work.
  expect_equal(readLines(starter), "edited by the student")
})

test_that("setup does not duplicate .gitignore entries on a second run", {
  root <- make_project("DESCRIPTION")
  suppressMessages(mariner_setup_project(root = root))
  suppressMessages(mariner_setup_project(root = root))

  ignored <- readLines(file.path(root, ".gitignore"))
  expect_equal(sum(ignored == "zip_files/"), 1L)
})

test_that("setup preserves an existing .gitignore", {
  root <- make_project("DESCRIPTION")
  writeLines(c("*.log", "secrets.R"), file.path(root, ".gitignore"))
  suppressMessages(mariner_setup_project(root = root))

  ignored <- readLines(file.path(root, ".gitignore"))
  expect_true(all(c("*.log", "secrets.R", "zip_files/") %in% ignored))
})

test_that("overwrite = TRUE restores a clobbered starter", {
  root <- make_project("DESCRIPTION")
  suppressMessages(mariner_setup_project(root = root))
  starter <- file.path(root, "reports", "report.qmd")
  writeLines("clobbered", starter)

  suppressMessages(mariner_setup_project(root = root, overwrite = TRUE))
  expect_false(identical(readLines(starter), "clobbered"))
})

test_that("setup rejects an unknown theme and an unknown template", {
  root <- make_project("DESCRIPTION")
  expect_error(mariner_setup_project(root = root, theme = "nosuch"))
  expect_error(
    suppressMessages(mariner_setup_project(root = root, template = "nosuch")),
    "Unknown template"
  )
})

test_that("template = NULL leaves the starter out", {
  root <- make_project("DESCRIPTION")
  dirs <- suppressMessages(mariner_setup_project(root = root, template = NULL))
  expect_false(file.exists(file.path(dirs$reports, "report.qmd")))
})

# --- the attach guard --------------------------------------------------------
#
# auto_setup_dirs() rather than .onAttach(): the latter returns early under
# testthat, which is not interactive, so calling it here would exercise nothing.

test_that("attach creates nothing outside a project directory", {
  plain <- withr::local_tempdir()

  expect_equal(auto_setup_dirs(plain), character())
  expect_equal(list.files(plain, all.files = TRUE, no.. = TRUE), character())
})

test_that("attach creates the three folders inside a project", {
  root <- make_project(".Rproj")
  created <- auto_setup_dirs(root)

  expect_setequal(created, c("assets", "reports", "zip_files"))
  expect_true(all(dir.exists(unlist(mariner_dirs(root)))))
})

test_that("attach is silent once the folders exist", {
  root <- make_project(".Rproj")
  auto_setup_dirs(root)
  # Nothing left to create means nothing reported, which is what keeps the
  # startup message once-per-project rather than once-per-session.
  expect_equal(auto_setup_dirs(root), character())
})

test_that("attach does not assemble the extension", {
  # The startup path has to stay cheap: three mkdir calls, not a 1.3 MB copy.
  root <- make_project(".Rproj")
  auto_setup_dirs(root)

  expect_false(dir.exists(file.path(root, "assets", "_extensions")))
})

test_that("mariner.auto_setup = FALSE turns attach off entirely", {
  root <- make_project(".Rproj")
  withr::with_options(list(mariner.auto_setup = FALSE), {
    expect_equal(auto_setup_dirs(root), character())
  })
  expect_false(dir.exists(file.path(root, "reports")))
})

# --- the copy helpers --------------------------------------------------------

test_that("copy_file_safe declines rather than clobbers", {
  dir <- withr::local_tempdir()
  src <- file.path(dir, "src.txt")
  dst <- file.path(dir, "dst.txt")
  writeLines("new", src)
  writeLines("old", dst)

  expect_false(copy_file_safe(src, dst))
  expect_equal(readLines(dst), "old")

  expect_true(copy_file_safe(src, dst, overwrite = TRUE))
  expect_equal(readLines(dst), "new")
})

test_that("copy_dir_safe reproduces a tree and creates missing parents", {
  dir <- withr::local_tempdir()
  src <- file.path(dir, "src")
  dir.create(file.path(src, "nested"), recursive = TRUE)
  writeLines("a", file.path(src, "a.txt"))
  writeLines("b", file.path(src, "nested", "b.txt"))

  dst <- file.path(dir, "dst")
  copy_dir_safe(src, dst)

  expect_equal(
    sort(list.files(dst, recursive = TRUE)),
    c("a.txt", "nested/b.txt")
  )
})

test_that("copy_dir_safe restores a deleted file while sparing an edited one", {
  # The per-file overwrite semantics the scaffolder depends on.
  dir <- withr::local_tempdir()
  src <- file.path(dir, "src")
  dir.create(src)
  writeLines("a", file.path(src, "a.txt"))
  writeLines("b", file.path(src, "b.txt"))

  dst <- file.path(dir, "dst")
  copy_dir_safe(src, dst)
  writeLines("edited", file.path(dst, "a.txt"))
  file.remove(file.path(dst, "b.txt"))

  copy_dir_safe(src, dst)
  expect_equal(readLines(file.path(dst, "a.txt")), "edited")
  expect_equal(readLines(file.path(dst, "b.txt")), "b")
})
