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

  ext_name <- mariner_ext_name("mariner")
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
  expect_error(mariner_setup_project(root = root, theme = "nosuch"), "must be one of")
  expect_error(
    suppressMessages(mariner_setup_project(root = root, template = "nosuch")),
    "No template named"
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

# --- has_markers -------------------------------------------------------------

test_that(".Rproj is matched as an extension, the rest as exact names", {
  # The project file is named after the project, so there is no fixed filename
  # to test for.
  dir <- withr::local_tempdir()
  expect_false(has_markers(dir, ROOT_MARKERS))

  file.create(file.path(dir, "Whatever.Rproj"))
  expect_true(has_markers(dir, ROOT_MARKERS))
})

test_that("a file merely mentioning a marker is not one", {
  dir <- withr::local_tempdir()
  file.create(file.path(dir, "DESCRIPTION.bak"))
  file.create(file.path(dir, "Rproj"))
  expect_false(has_markers(dir, ROOT_MARKERS))
})

test_that("has_markers takes the markers it is given", {
  dir <- withr::local_tempdir()
  dir.create(file.path(dir, ".git"))
  expect_false(has_markers(dir, ROOT_MARKERS))
  expect_true(has_markers(dir, PROJECT_MARKERS))
})

# --- append_gitignore --------------------------------------------------------

test_that("append_gitignore creates the file when there is none", {
  dir <- withr::local_tempdir()
  added <- append_gitignore(dir, c("zip_files/", "assets/_extensions/"))

  expect_identical(added, c("zip_files/", "assets/_extensions/"))
  expect_identical(
    readLines(file.path(dir, ".gitignore")),
    c("# mariner build outputs", "zip_files/", "assets/_extensions/")
  )
})

test_that("append_gitignore separates its block from existing content", {
  # Appending to a file whose last line is an entry would glue the first new
  # entry onto it.
  dir <- withr::local_tempdir()
  path <- file.path(dir, ".gitignore")
  writeLines(c(".Rhistory", ".Rproj.user"), path)

  append_gitignore(dir, "zip_files/")
  expect_identical(
    readLines(path),
    c(".Rhistory", ".Rproj.user", "", "# mariner build outputs", "zip_files/")
  )
})

test_that("append_gitignore does not add a second blank line", {
  dir <- withr::local_tempdir()
  path <- file.path(dir, ".gitignore")
  writeLines(c(".Rhistory", ""), path)

  append_gitignore(dir, "zip_files/")
  expect_identical(
    readLines(path),
    c(".Rhistory", "", "# mariner build outputs", "zip_files/")
  )
})

test_that("append_gitignore recognises an entry a student wrote with a stray space", {
  dir <- withr::local_tempdir()
  path <- file.path(dir, ".gitignore")
  writeLines(c("zip_files/ ", "  assets/_extensions/"), path)

  expect_identical(append_gitignore(dir, c("zip_files/", "assets/_extensions/")), character())
  expect_length(readLines(path), 2L)
})

test_that("append_gitignore adds only the entries that are missing", {
  dir <- withr::local_tempdir()
  path <- file.path(dir, ".gitignore")
  writeLines("zip_files/", path)

  expect_identical(
    append_gitignore(dir, c("zip_files/", "reports/_extensions/")),
    "reports/_extensions/"
  )
})

# --- setup_template_path -----------------------------------------------------

test_that("setup_template_path resolves a packaged skeleton and rejects the rest", {
  expect_true(file.exists(setup_template_path("report")))
  expect_error(setup_template_path("not-a-template"), "No template named")
})

# --- .onAttach ---------------------------------------------------------------

test_that(".onAttach creates nothing outside a project directory", {
  # The guard that holds whether or not the session is interactive, which is
  # what makes this the one to assert unconditionally: devtools::test() in
  # RStudio is interactive, and R CMD check is not.
  dir <- withr::local_tempdir()
  withr::local_dir(dir)

  expect_null(.onAttach("lib", "mariner"))
  expect_false(any(dir.exists(unlist(mariner_dirs(dir), use.names = FALSE))))
})

test_that(".onAttach does nothing in a non-interactive session", {
  # Rscript in CI, a future multisession worker and R CMD check all attach this
  # package, and none of them is a person opening a project. The guard under
  # test is `!interactive()`, so there is nothing to assert from a session that
  # is one.
  skip_if(interactive(), "this session is interactive")

  dir <- withr::local_tempdir()
  file.create(file.path(dir, "p.Rproj"))
  withr::local_dir(dir)

  expect_null(.onAttach("lib", "mariner"))
  expect_false(any(dir.exists(unlist(mariner_dirs(dir), use.names = FALSE))))
})

# --- the mariner layout as a root marker -------------------------------------
#
# mariner_setup_project() used to scaffold a project that mariner_project_root()
# could not afterwards find. The two resolve the root differently -- the
# scaffolder from the working directory, process_file() by walking up from the
# input file -- so without an .Rproj they disagreed, and a render wrote its
# bundle into reports/zip_files/ while the student was told to look in
# zip_files/.

# The three folders, and nothing else.
local_bare_project <- function(env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  for (d in MARINER_DIR_NAMES) dir.create(file.path(dir, d))
  dir
}

test_that("all three folders make a directory a root, with no .Rproj", {
  dir <- local_bare_project()
  expect_true(has_mariner_layout(dir))
  expect_equal(mariner_project_root(dir), normalizePath(dir, winslash = "/"))
})

test_that("the walk finds the layout from a subdirectory", {
  # The case that produced two zip_files/ directories: process_file() resolves
  # the root from the INPUT's directory, which is reports/.
  dir <- local_bare_project()
  expect_equal(
    mariner_project_root(file.path(dir, "reports")),
    normalizePath(dir, winslash = "/")
  )
})

test_that("a bundle lands in the project's zip_files, not the reports one", {
  # The bug, stated as the behaviour it broke.
  dir <- local_bare_project()
  expect_equal(
    mariner_dirs(mariner_project_root(file.path(dir, "reports")))$zips,
    file.path(normalizePath(dir, winslash = "/"), "zip_files")
  )
})

test_that("one or two of the folders is not a layout", {
  # `reports/` alone is an ordinary directory name. The full set is what this
  # package creates and what nothing else does.
  dir <- withr::local_tempdir()
  expect_false(has_mariner_layout(dir))

  dir.create(file.path(dir, "reports"))
  expect_false(has_mariner_layout(dir))

  dir.create(file.path(dir, "assets"))
  expect_false(has_mariner_layout(dir))

  dir.create(file.path(dir, "zip_files"))
  expect_true(has_mariner_layout(dir))
})

test_that("a real marker still beats the layout further up", {
  # An .Rproj in reports/ would be odd, but the walk must stop at the nearest
  # marker whichever kind it is.
  dir <- local_bare_project()
  file.create(file.path(dir, "reports", "inner.Rproj"))

  expect_equal(
    mariner_project_root(file.path(dir, "reports")),
    normalizePath(file.path(dir, "reports"), winslash = "/")
  )
})

test_that("setup makes a directory that resolves as its own root", {
  # The invariant the whole change exists for: scaffold, then find it again.
  dir <- withr::local_tempdir()
  suppressMessages(mariner_setup_project(root = dir, template = NULL))

  expect_equal(
    mariner_project_root(file.path(dir, "reports")),
    normalizePath(dir, winslash = "/")
  )
})

test_that("an abandoned layout in a parent does not capture a project below it", {
  # The file markers are deliberate; the three folders are created for you. So
  # a `folder/` left over from a run someone gave up on must not swallow the
  # `folder/new folder/` they started instead.
  dir <- local_bare_project()
  fresh <- file.path(dir, "new folder")
  dir.create(fresh)

  expect_equal(mariner_project_root(fresh), normalizePath(fresh, winslash = "/"))
})

test_that("a marker in a parent still captures, layout or not", {
  # The restriction is on the LAYOUT, not on the walk. An .Rproj above still
  # means "this is the project", which is the documented behaviour.
  outer <- make_project("DESCRIPTION")
  inner <- file.path(outer, "sub")
  dir.create(inner)

  expect_equal(mariner_project_root(inner), outer)
})

test_that("the walk climbs out of any of the three folders", {
  # process_file() resolves from reports/, but a file in the project's assets/
  # or zip_files/ belongs to it by the same argument.
  dir <- local_bare_project()
  for (d in MARINER_DIR_NAMES) {
    expect_equal(
      mariner_project_root(file.path(dir, d)),
      normalizePath(dir, winslash = "/"),
      info = d
    )
  }
})

test_that("a subdirectory of reports/ still reaches the project", {
  dir <- local_bare_project()
  deep <- file.path(dir, "reports", "chapter-1")
  dir.create(deep, recursive = TRUE)

  expect_equal(mariner_project_root(deep), normalizePath(dir, winslash = "/"))
})

test_that("accepts_layout answers where it started and what it climbed out of", {
  dir <- local_bare_project()

  expect_true(accepts_layout(dir, NULL))
  expect_true(accepts_layout(dir, file.path(dir, "reports")))
  expect_false(accepts_layout(dir, file.path(dir, "new folder")))
  # No layout, no answer, whatever it climbed out of.
  expect_false(accepts_layout(withr::local_tempdir(), NULL))
})
