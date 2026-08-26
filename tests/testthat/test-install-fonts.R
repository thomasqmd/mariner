# Installing and registering the bundled faces.
#
# mariner_install_fonts() is the one operation in the package that writes
# outside the project, so no test may run it against a real font directory. Both
# ends are mocked instead: mariner_font_dir() says where the files come from and
# user_font_dir() says where they go, and every test below redirects the second
# one into a temp directory.
#
# The Windows registry write and the Linux fc-cache call are skipped rather than
# faked. Both shell out, and a test that faked the shell would assert what the
# fake does.

bundled_ttf <- function() {
  list.files(mariner_font_dir(), pattern = "\\.ttf$")
}

# --- user_font_dir -----------------------------------------------------------

test_that("user_font_dir names one directory for this platform", {
  dir <- user_font_dir()
  expect_type(dir, "character")
  expect_length(dir, 1L)
})

test_that("macOS installs into the user's own font directory, not the system one", {
  # Never the system one: that needs administrator rights, and this function is
  # documented as needing none.
  expect_identical(
    user_font_dir(sysname = "Darwin", ostype = "unix"),
    path.expand("~/Library/Fonts")
  )
})

test_that("Windows installs under LOCALAPPDATA", {
  withr::with_envvar(c(LOCALAPPDATA = "C:/Users/Someone/AppData/Local"), {
    expect_identical(
      user_font_dir(sysname = "Windows", ostype = "windows"),
      file.path("C:/Users/Someone/AppData/Local", "Microsoft", "Windows", "Fonts")
    )
  })
})

test_that("a Windows without LOCALAPPDATA gives NA rather than a guess", {
  # mariner_install_fonts() aborts on the NA. Guessing a path would copy 14
  # files somewhere Windows does not read.
  withr::with_envvar(c(LOCALAPPDATA = ""), {
    expect_identical(user_font_dir(sysname = "Windows", ostype = "windows"), NA_character_)
  })
})

test_that("Linux honours XDG_DATA_HOME and falls back to ~/.local/share", {
  withr::with_envvar(c(XDG_DATA_HOME = "/tmp/xdg"), {
    expect_identical(
      user_font_dir(sysname = "Linux", ostype = "unix"),
      file.path("/tmp/xdg", "fonts")
    )
  })
  withr::with_envvar(c(XDG_DATA_HOME = ""), {
    expect_identical(
      user_font_dir(sysname = "Linux", ostype = "unix"),
      file.path(path.expand("~/.local/share"), "fonts")
    )
  })
})

test_that("every platform's answer is one path, and only macOS is special-cased", {
  # Darwin is `unix` under .Platform, so the sysname test has to come first or
  # a Mac would take the XDG branch.
  for (os in list(c("Darwin", "unix"), c("Windows", "windows"), c("Linux", "unix"))) {
    dir <- user_font_dir(sysname = os[[1]], ostype = os[[2]])
    expect_length(dir, 1L)
    expect_type(dir, "character")
  }
})

# --- mariner_install_fonts ---------------------------------------------------

test_that("every bundled face is copied into the user font directory", {
  skip_on_os("windows")
  dest <- withr::local_tempdir()
  local_mocked_bindings(user_font_dir = function() dest)

  installed <- mariner_install_fonts(quiet = TRUE)

  expect_setequal(basename(installed), bundled_ttf())
  expect_true(all(file.exists(installed)))
  # The licence and README files stay behind; only the faces are installed.
  expect_setequal(list.files(dest), bundled_ttf())
})

test_that("the destination directory is created rather than required", {
  skip_on_os("windows")
  dest <- file.path(withr::local_tempdir(), "nested", "fonts")
  local_mocked_bindings(user_font_dir = function() dest)

  mariner_install_fonts(quiet = TRUE)
  expect_true(dir.exists(dest))
})

test_that("a second run writes nothing and says the fonts are already there", {
  skip_on_os("windows")
  dest <- withr::local_tempdir()
  local_mocked_bindings(user_font_dir = function() dest)
  mariner_install_fonts(quiet = TRUE)

  expect_message(second <- mariner_install_fonts(), "already installed")
  expect_identical(second, character())
})

test_that("overwrite = TRUE replaces what is already installed", {
  skip_on_os("windows")
  dest <- withr::local_tempdir()
  local_mocked_bindings(user_font_dir = function() dest)
  mariner_install_fonts(quiet = TRUE)

  # A face a student clobbered, restored.
  victim <- file.path(dest, "Lora-Regular.ttf")
  writeLines("not a font", victim)

  again <- mariner_install_fonts(overwrite = TRUE, quiet = TRUE)
  expect_setequal(basename(again), bundled_ttf())
  expect_gt(file.size(victim), 1000)
})

test_that("the summary counts the files and asks for a restart", {
  skip_on_os("windows")
  dest <- withr::local_tempdir()
  local_mocked_bindings(user_font_dir = function() dest)

  said <- paste(capture_messages(mariner_install_fonts()), collapse = "")
  expect_match(said, "Installed")
  expect_match(said, "Restart R")
})

test_that("a copy that cannot happen is reported, not passed over", {
  skip_on_os("windows")
  # A file where the directory should be: dir.create() declines and every copy
  # into it fails. A silent failure here leaves the student with a missing-font
  # error at render time that names nothing.
  dest <- file.path(withr::local_tempdir(), "blocked")
  writeLines("in the way", dest)
  local_mocked_bindings(user_font_dir = function() dest)

  # Every warning, not the first: file.copy() warns per file before the summary.
  warned <- paste(capture_warnings(installed <- mariner_install_fonts()), collapse = "\n")
  expect_match(warned, "Could not copy")
  expect_identical(installed, character())
})

test_that("a missing bundled font directory is a broken install, and says so", {
  local_mocked_bindings(mariner_font_dir = function() "")
  expect_error(mariner_install_fonts(), "bundled fonts could not be found")
})

test_that("a platform with no user font directory errors rather than guessing", {
  local_mocked_bindings(user_font_dir = function() NA_character_)
  expect_error(mariner_install_fonts(), "font directory")
})

# --- mariner_register_fonts --------------------------------------------------

test_that("registration reports the families it made resolvable", {
  registered <- mariner_register_fonts()
  expect_type(registered, "character")
  expect_true(all(registered %in% names(mariner_font_files())))
})

test_that("registration announces itself when asked to", {
  skip_if_not_installed("systemfonts")
  said <- paste(
    suppressWarnings(capture_messages(mariner_register_fonts(quiet = FALSE))),
    collapse = ""
  )
  expect_match(said, "font famil")
})

test_that("a family missing any of its four cuts is skipped whole", {
  # Registering three of four styles is worse than registering none: the fourth
  # resolves somewhere else entirely, and the document gets two typefaces.
  local_mocked_bindings(mariner_font_files = function() {
    list("Nonesuch" = c(
      plain = "no-such-plain.ttf", bold = "no-such-bold.ttf",
      italic = "no-such-italic.ttf", bolditalic = "no-such-bolditalic.ttf"
    ))
  })
  expect_identical(mariner_register_fonts(), character())
})

test_that("no font directory means nothing is registered and nothing fails", {
  # Loading the package must not fail over a font.
  local_mocked_bindings(mariner_font_dir = function() "")
  expect_identical(mariner_register_fonts(), character())
})

test_that("every family names four distinct cuts", {
  for (family in names(mariner_font_files())) {
    files <- mariner_font_files()[[family]]
    expect_identical(names(files), c("plain", "bold", "italic", "bolditalic"))
    expect_length(unique(files), 4L)
    expect_true(all(file.exists(file.path(mariner_font_dir(), files))))
  }
})

test_that("both Atkinson names map to the same static cuts", {
  # _brand.yml names the family "Atkinson Hyperlegible Next", so that is what
  # theme_mariner() asks for; a document asking for the original name has to
  # resolve as well.
  files <- mariner_font_files()
  expect_identical(files[["Atkinson Hyperlegible Next"]], files[["Atkinson Hyperlegible"]])
})

# --- mariner_fonts_available -------------------------------------------------

test_that("the pdf answer is about installation, not about the registry", {
  # cairo_pdf() and pdf() read fontconfig and ignore the registry that
  # mariner_register_fonts() populates, so a registered-but-not-installed face
  # is invisible to them.
  skip_if_not_installed("systemfonts")
  mariner_register_fonts(quiet = TRUE)

  sys <- systemfonts::system_fonts()
  installed <- any(grepl("^Atkinson Hyperlegible", sys$family))

  expect_identical(mariner_fonts_available("pdf"), installed)
  # Registration alone is enough for the svg devices.
  expect_true(mariner_fonts_available())
})
