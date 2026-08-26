# Making the bundled faces reachable from R's graphics devices.
#
# The three families are vendored, not installed, which is deliberate -- a
# document has to render the same on a machine that has never heard of Atkinson
# Hyperlegible. The CSS reaches them through @font-face and the LaTeX preamble
# through fontspec's Path=, but R's graphics devices had no equivalent, so every
# figure asked for a family the device could not resolve:
#
#   no font could be found for family "Atkinson Hyperlegible Next"
#   Unable to calculate text width/height (using zero)
#
# Zero-width text is not a cosmetic problem. The device lays the panel out
# around labels it believes have no size, so axis titles collide, legends
# overlap the panel, and an svg can come out effectively blank.
#
# theme_mariner() used to work around this by passing base_family = "" for pdf,
# which meant a report's FIGURES quietly opted out of the theme's own typeface
# while the body text around them kept it.
#
# THE STATIC CUTS, NOT THE VARIABLE FILE. systemfonts can register a file per
# style but cannot instance a variable axis for a font it did not find on the
# system -- register_variant() only sees installed families, so a variable file
# registered as `bold` resolves to its default instance and the weight is faked.
# That is the same limitation XeTeX has, and brand-preamble.tex already answers
# it the same way, so the figures and the PDF body text now come from the same
# files.

# Which device honours this registry is not a detail: it is read by svglite and
# ragg, and NOT by cairo_pdf(), which goes to fontconfig instead. That is why
# mariner_install_fonts() exists -- a report's FIGURES need the faces installed,
# not merely registered, even though its body text does not.

mariner_font_files <- function() {
  list(
    # Both names map to the static cuts. _brand.yml names the family "Atkinson
    # Hyperlegible Next", so that is the name theme_mariner() asks for; the second
    # entry means a document that asks for the original name also resolves.
    "Atkinson Hyperlegible Next" = c(
      plain      = "AtkinsonHyperlegible-Regular.ttf",
      bold       = "AtkinsonHyperlegible-Bold.ttf",
      italic     = "AtkinsonHyperlegible-Italic.ttf",
      bolditalic = "AtkinsonHyperlegible-BoldItalic.ttf"
    ),
    "Atkinson Hyperlegible" = c(
      plain      = "AtkinsonHyperlegible-Regular.ttf",
      bold       = "AtkinsonHyperlegible-Bold.ttf",
      italic     = "AtkinsonHyperlegible-Italic.ttf",
      bolditalic = "AtkinsonHyperlegible-BoldItalic.ttf"
    ),
    "Lora" = c(
      plain      = "Lora-Regular.ttf",
      bold       = "Lora-Bold.ttf",
      italic     = "Lora-Italic.ttf",
      bolditalic = "Lora-BoldItalic.ttf"
    ),
    "JetBrains Mono" = c(
      plain      = "JetBrainsMono-Regular.ttf",
      bold       = "JetBrainsMono-Bold.ttf",
      italic     = "JetBrainsMono-Italic.ttf",
      bolditalic = "JetBrainsMono-BoldItalic.ttf"
    )
  )
}

# Where the vendored fonts are, in an installed package or a source checkout.
#
# Nothing here may depend on the working directory. An earlier version fell back
# to the relative path "inst/assets/fonts", which resolves from the package root
# and nowhere else -- under testthat the working directory is tests/testthat, so
# the fallback silently found nothing, registration returned an empty set, and
# the failure looked like a font problem rather than a path problem.
mariner_font_dir <- function() {
  dir <- system.file("assets", "fonts", package = "mariner")
  if (nzchar(dir) && dir.exists(dir)) return(dir)

  # pkgload records the SOURCE root on the namespace, so this resolves under
  # devtools::load_all() from any working directory.
  root <- tryCatch(getNamespaceInfo("mariner", "path"), error = function(e) "")
  if (!nzchar(root)) return("")

  candidates <- c(
    file.path(root, "assets", "fonts"),          # installed layout
    file.path(root, "inst", "assets", "fonts")   # source checkout
  )
  candidates <- candidates[dir.exists(candidates)]
  if (length(candidates)) candidates[[1]] else ""
}

#' Register the bundled fonts with R's graphics devices
#'
#' Makes Atkinson Hyperlegible, Lora and JetBrains Mono resolvable by family
#' name, so [theme_mariner()] figures are drawn in the theme's own typefaces rather
#' than falling back. Called automatically when the package is loaded; exported
#' so it can be re-run after something else clears the registry.
#'
#' Registration is read by the svglite and ragg devices. The cairo-backed
#' `grDevices::svg()` and `cairo_pdf()` consult fontconfig instead and are
#' unaffected, which is why [mariner_knitr_setup()] selects svglite for the formats
#' whose figures are svg.
#'
#' @param quiet Suppress the message naming what was registered.
#' @return Invisibly, the character vector of family names registered.
#' @noRd
#' @examples
#' \dontrun{
#' mariner_register_fonts()
#' }
mariner_register_fonts <- function(quiet = TRUE) {
  if (!requireNamespace("systemfonts", quietly = TRUE)) {
    if (!quiet) cli::cli_warn("Package {.pkg systemfonts} is not available; fonts were not registered.")
    return(invisible(character()))
  }

  dir <- mariner_font_dir()
  if (!nzchar(dir) || !dir.exists(dir)) return(invisible(character()))

  registered <- character()
  for (family in names(mariner_font_files())) {
    files <- mariner_font_files()[[family]]
    # file.path() returns an UNNAMED vector, so the style names have to be put
    # back or paths[["plain"]] below is a subscript error -- which, wrapped in
    # the tryCatch, would fail silently and register nothing at all.
    paths <- stats::setNames(file.path(dir, files), names(files))

    # A partial family is worse than none: registering three of four styles
    # leaves the fourth resolving somewhere else entirely.
    if (!all(file.exists(paths))) next

    err <- NULL
    ok <- tryCatch({
      systemfonts::register_font(
        name       = family,
        plain      = paths[["plain"]],
        bold       = paths[["bold"]],
        italic     = paths[["italic"]],
        bolditalic = paths[["bolditalic"]]
      )
      TRUE
    }, error = function(e) { err <<- conditionMessage(e); FALSE })

    # "already exists" is SUCCESS, not failure.
    #
    # systemfonts::register_font() refuses to shadow a family that is installed
    # system-wide, and reports that refusal as an error. But the outcome it
    # describes is the one we wanted: the family resolves by name. Lora and
    # JetBrains Mono are common enough to be installed already, so treating the
    # refusal as a failure meant a machine that was BETTER equipped produced a
    # warning per family and an under-count of what is drawable.
    #
    # The installed copy is used instead of the bundled one, which is a
    # difference only if the two are different cuts of the font. They are the
    # same faces from the same foundries, and a document rendered on a machine
    # without them falls back to the bundled copies.
    already <- !ok && grepl("already exists", err %||% "", fixed = TRUE)

    if (ok || already) {
      registered <- c(registered, family)
    } else if (!quiet) {
      # Surfaced rather than swallowed. Loading the package must not fail over a
      # font, but a silent failure here is indistinguishable from a device that
      # cannot draw -- which is the bug this whole file exists to fix.
      cli::cli_warn("Could not register {.val {family}}: {err}")
    }
  }

  if (!quiet && length(registered)) {
    cli::cli_alert_success("Registered {length(registered)} font famil{?y/ies}: {.val {registered}}")
  }
  invisible(registered)
}

# TRUE when the theme's display face can actually be drawn BY THE DEVICE THAT
# WILL DRAW IT. theme_mariner() asks so that a device which cannot reach the face
# falls back deliberately rather than emitting a warning per label.
#
# The `format` argument is the whole point, and leaving it out was a real bug.
# Registration is read by svglite and ragg and by nothing else -- the note at the
# top of this file says so -- so "is it in the registry" is the right question
# only for the formats whose figures are svg. The LaTeX pdf path draws through
# cairo_pdf(), which consults FONTCONFIG, or, on a build without cairo, through
# base pdf(), which knows only the PostScript font database and cannot use a TTF
# family at all.
#
# Answering "yes, it is registered" for that path is what produced
#
#   font family 'Atkinson Hyperlegible Next' not found in PostScript font database
#   Error in grid.Call.graphics(...) : invalid font type
#
# and took the whole render down. A registered-but-not-installed face is simply
# not reachable there, so for pdf the question is the narrower one: is it
# INSTALLED on this machine?
mariner_fonts_available <- function(format = NULL) {
  if (!requireNamespace("systemfonts", quietly = TRUE)) return(FALSE)

  installed <- function() {
    sys <- tryCatch(systemfonts::system_fonts(), error = function(e) NULL)
    !is.null(sys) && any(grepl("^Atkinson Hyperlegible", sys$family))
  }

  # cairo_pdf() and pdf() both ignore the registry; only an installed face
  # reaches them. svglite, used outside a render, reads the registry instead.
  if (identical(format, "pdf")) return(installed())

  reg <- tryCatch(systemfonts::registry_fonts(), error = function(e) NULL)
  if (!is.null(reg) && "Atkinson Hyperlegible Next" %in% reg$family) return(TRUE)
  # Registered families are not the only way to have it -- it may be installed.
  installed()
}

# ---------------------------------------------------------------------------
# Installing the bundled faces system-wide
#
# WHY THIS EXISTS, when the fonts are already bundled and registered.
#
# Registration reaches svglite and ragg and nothing else. The LaTeX pdf path
# draws its figures through cairo_pdf(), which consults FONTCONFIG, so a face
# that is registered but not installed is invisible to it -- and base pdf(), the
# fallback on a build without cairo, cannot use a TTF family at all.
#
# The result, before this function existed: in a PDF report the BODY TEXT was
# Atkinson and Lora (fontspec reads the bundled files directly, by path), while
# every FIGURE fell back to the device default. One document, two typefaces,
# and nothing saying so. theme_mariner() detects the gap and passes
# base_family = "" rather than asking for a face the device cannot measure --
# the alternative is zero-width text metrics and a collapsed panel layout -- but
# falling back deliberately is still falling back.
#
# Installing the faces closes it. This is the one operation in the package that
# writes outside the project, so it is never automatic: it is called by the user,
# or by mariner_setup_project() only when that is asked to.
# ---------------------------------------------------------------------------

# The name Windows expects a font's registry value to carry.
#
# Windows writes `<Full Font Name> (TrueType)` -- "Lora Regular (TrueType)" --
# where the full name comes from the font's own name table, NOT from its
# filename. Ours are named `Lora-Regular.ttf`, so deriving the value from the
# filename gives "Lora-Regular (TrueType)": close enough to look right in the
# registry and wrong enough to leave a duplicate entry behind when the user
# later installs the same face through Explorer.
#
# systemfonts reads the name table, so the family and style are asked for rather
# than guessed. The filename stem is the fallback for the case where the file
# cannot be read at all -- at which point the copy has already failed and this
# value will never be used.
windows_font_value_name <- function(path) {
  info <- tryCatch(
    systemfonts::font_info(path = path, index = 0),
    error = function(e) NULL
  )

  label <- if (!is.null(info) && nzchar(info$family[[1]])) {
    style <- info$style[[1]]
    if (nzchar(style)) paste(info$family[[1]], style) else info$family[[1]]
  } else {
    tools::file_path_sans_ext(basename(path))
  }

  paste0(label, " (TrueType)")
}

# Where a per-user font install goes on each platform.
user_font_dir <- function() {
  if (Sys.info()[["sysname"]] == "Darwin") {
    return(path.expand("~/Library/Fonts"))
  }
  if (.Platform$OS.type == "windows") {
    local <- Sys.getenv("LOCALAPPDATA")
    if (!nzchar(local)) return(NA_character_)
    return(file.path(local, "Microsoft", "Windows", "Fonts"))
  }
  # Linux and other unices. XDG_DATA_HOME wins when set.
  xdg <- Sys.getenv("XDG_DATA_HOME")
  base <- if (nzchar(xdg)) xdg else path.expand("~/.local/share")
  file.path(base, "fonts")
}

#' Install the bundled fonts for this user
#'
#' Copies the theme's font files into your user font directory. Atkinson
#' Hyperlegible, Lora and JetBrains Mono then reach every program on the
#' machine, the graphics devices that draw PDF figures included.
#'
#' @section Why you may want this:
#' mariner bundles its fonts and registers them with R at load time. That covers
#' PDF *body text*, which xelatex reads from the bundled files by path. It does
#' not cover PDF *figures*: `cairo_pdf()` draws those, and it reads the system
#' font configuration, where a bundled font does not appear. Until you install
#' the faces, the figures in a report fall back to the device's default typeface
#' and the text around them does not.
#'
#' `mariner_check_setup()` says whether this applies to your machine.
#'
#' @section Platform notes:
#' None of this needs administrator rights. The fonts go into your own font
#' directory, not the system one.
#'
#' * **macOS** copies to `~/Library/Fonts`. Available at once.
#' * **Linux** copies to `~/.local/share/fonts` and runs `fc-cache` if it exists.
#' * **Windows** copies to `%LOCALAPPDATA%\\Microsoft\\Windows\\Fonts` and
#'   registers each face under `HKEY_CURRENT_USER`. Windows ignores a font file
#'   the registry does not name, so a failed registry write is reported as a
#'   failure.
#'
#' **Restart R afterwards.** A graphics device reads the font configuration once
#' per session.
#'
#' @param overwrite Replace font files that are already installed.
#' @param quiet Suppress the summary.
#' @return Invisibly, the files copied. A file already in place is listed only
#'   under `overwrite = TRUE`.
#' @export
#' @examples
#' \dontrun{
#' mariner_install_fonts()
#' # then restart R
#' }
mariner_install_fonts <- function(overwrite = FALSE, quiet = FALSE) {
  src_dir <- mariner_font_dir()
  if (!nzchar(src_dir) || !dir.exists(src_dir)) {
    cli::cli_abort(c(
      "The bundled fonts could not be found.",
      i = "The install may be incomplete; try reinstalling mariner."
    ))
  }

  dest_dir <- user_font_dir()
  if (is.na(dest_dir)) {
    cli::cli_abort("Could not determine this user's font directory on this platform.")
  }
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)

  # Every .ttf, including the variable Atkinson Next files. theme_mariner() asks
  # for "Atkinson Hyperlegible Next" by name, and only the variable files carry
  # that family -- installing the static cuts alone would leave the very family
  # the theme requests unresolvable.
  fonts <- list.files(src_dir, pattern = "\\.ttf$", full.names = TRUE)

  installed <- character()
  failed <- character()
  for (f in fonts) {
    dest <- file.path(dest_dir, basename(f))
    if (file.exists(dest) && !overwrite) next
    if (isTRUE(file.copy(f, dest, overwrite = TRUE))) {
      installed <- c(installed, dest)
    } else {
      failed <- c(failed, basename(f))
    }
  }

  # On Windows a file in the user font directory does nothing until it is named
  # in the registry, so this is part of installing rather than a nicety.
  registry_failed <- character()
  if (.Platform$OS.type == "windows" && length(installed)) {
    key <- "HKCU\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts"
    for (dest in installed) {
      # type = "cmd", NOT the default. shQuote()'s default is POSIX quoting --
      # single quotes -- and cmd.exe does not strip those: reg.exe would receive
      # 'HKCU\Software\...' with the quotes as part of the key name and refuse
      # every write. system2() on Windows goes through cmd, so the quoting has
      # to be cmd's. Registry paths contain backslashes and the destination
      # contains spaces (%LOCALAPPDATA% is under C:\Users\<name>\), so dropping
      # the quoting altogether is not the alternative.
      status <- suppressWarnings(system2(
        "reg",
        c("add", shQuote(key, type = "cmd"),
          "/v", shQuote(windows_font_value_name(dest), type = "cmd"),
          "/t", "REG_SZ",
          "/d", shQuote(dest, type = "cmd"), "/f"),
        stdout = FALSE, stderr = FALSE
      ))
      if (!identical(status, 0L)) registry_failed <- c(registry_failed, basename(dest))
    }
  }

  # fontconfig caches aggressively; without this the faces are on disk and still
  # not found until the cache happens to be rebuilt.
  #
  # A bare container often has no fc-cache -- fontconfig's binaries are a
  # separate package from its library on most distributions. The install still
  # works: the files are in a directory fontconfig scans, and it rebuilds its
  # own cache when it next finds the directory newer than the cache. What it is
  # not is IMMEDIATE, so the absence is reported rather than passed over. A
  # student told "installed, restart R" who then finds the fonts still missing
  # has no way to get from there to "your image has no fontconfig tools".
  fc_cache_missing <- FALSE
  if (.Platform$OS.type == "unix" && Sys.info()[["sysname"]] != "Darwin" &&
      length(installed)) {
    if (nzchar(Sys.which("fc-cache"))) {
      suppressWarnings(system2("fc-cache", c("-f", shQuote(dest_dir)),
                               stdout = FALSE, stderr = FALSE))
    } else {
      fc_cache_missing <- TRUE
    }
  }

  if (!quiet) {
    if (length(installed)) {
      cli::cli_alert_success(
        "Installed {length(installed)} font file{?s} into {.file {dest_dir}}."
      )
      cli::cli_alert_info("Restart R for graphics devices to pick them up.")
    } else if (!length(failed)) {
      cli::cli_alert_info(
        "All {length(fonts)} bundled font{?s} {?is/are} already installed in {.file {dest_dir}}."
      )
    }
    if (length(failed)) {
      cli::cli_warn("Could not copy: {.file {failed}}")
    }
    if (fc_cache_missing) {
      cli::cli_alert_info(c(
        "{.code fc-cache} is not on this machine, so the font cache was not ",
        "rebuilt. The fonts are installed and will be picked up once ",
        "fontconfig next refreshes; install {.pkg fontconfig}'s tools to make ",
        "that happen now."
      ))
    }
    if (length(registry_failed)) {
      cli::cli_warn(c(
        "Copied but could not register {length(registry_failed)} font{?s} with Windows.",
        i = "An unregistered font file is ignored, so {?this font/these fonts} will not be available.",
        i = "Installing {.file {dest_dir}} by hand (select, right-click, Install) will finish the job."
      ))
    }
  }

  invisible(installed)
}

.onLoad <- function(libname, pkgname) {
  mariner_register_fonts(quiet = TRUE)
  invisible()
}
