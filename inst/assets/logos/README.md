# Bundled logos

| File | Pixels | Aspect | Brand slot | Used by |
|---|---|---|---|---|
| `BU_BrandMark_Horz_Green.png` | 949×169 | 5.62:1 | `medium` | revealjs corner, pdf title page, html header, typst corner |
| `BU_BrandMark_Stacked_Green.png` | 742×336 | 2.21:1 | `large` | title slides and covers, opt-in |
| `BU_Green.png` | 288×324 | 0.89:1 | `small` | available; nothing wires it by default |

All three are the official marks in Baylor green with transparent backgrounds.
The filenames are typed once, in `inst/brand/baylor/_brand.yml` under `logo:`,
and every placement reads them from there.

## Placement is by height, not by width

Widths are **derived**, never typed. `R/logos.R` reads each PNG's dimensions
from its IHDR header and computes a width from a target height, so the three
marks sit at matching visual weight despite ranging from 0.89:1 to 5.62:1.

The previous version of this theme hardcoded a width per file — `1.3in` for the
wordmark, `0.7in` for a square mark — which is exactly the arrangement that
cannot survive a new logo being added. Adding a fourth mark here now requires
naming it in `_brand.yml`; it needs no number anywhere.

## The resolution cap is lifted

The mark this set replaces was 214×40. At the ~47px corner height a 1600×900
slide calls for, that was already a 1.2× upscale, and ~2.4× on a hidpi
projector — visibly soft. The old theme therefore capped the corner logo at
~2rem (32px) and left a note that the cap should stand "until a vector wordmark
is obtained from Baylor's brand site."

`BU_BrandMark_Horz_Green.png` is 169px tall, 4.2× the old source. At a 47px
corner it is a 0.28× *downscale*, which stays sharp at any device pixel ratio a
projector or laptop will produce. **The cap no longer applies** and the corner
logo is sized from the slide geometry like every other piece of deck furniture.

## Licensing

These are Baylor University trademarks, included for the author's private use
as a Baylor affiliate. They are not covered by the package's MIT licence.

If mariner is ever distributed beyond that use, the files come out of the
package and `mariner_setup_project()` takes a user-supplied path instead.

## Dropped

`bscc_logo.png` and `bscc_logo_stacked.png` (Baylor Statistical Consulting
Center) are **not** bundled. They mark consulting-engagement work specifically,
rather than Baylor affiliation generally, so they do not belong in a general
theme. A consulting deck can still set `logo:` explicitly in its own YAML.
