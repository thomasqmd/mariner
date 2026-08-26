# Bundled fonts

One type system, shared by the page and the figures drawn onto it.

| Role | Family | Files | Used by |
|---|---|---|---|
| Figure text | Atkinson Hyperlegible Next | 2 variable (upright + italic, `[wght]`) | `theme_mariner()`, through systemfonts |
| Titles and headings | Atkinson Hyperlegible **v1** | 4 static | the PDF, through fontspec |
| Long-form body copy | Lora | 4 static | the PDF |
| Code | JetBrains Mono | 4 static | both |

All three families are SIL Open Font License 1.1; each ships its licence as
`<Family>-OFL.txt`. Fonts are bundled rather than fetched at render time so a
PDF can embed them and a render works offline. The package installs from GitHub
only, so the ~2 MB is not a concern.

Downloaded from `github.com/google/fonts/ofl/<family>` on 2026-08-19; Lora and
JetBrains Mono were copied from `Website/fonts/`, where they were already
vendored for the site's PDF format.

## Why this pairing

Sans display over serif body is the conventional report pairing, and here each
side does something the other cannot. The evidence is committed:
`data-raw/font-specimen.png` and `data-raw/atkinson-hierarchy.png`.

**Atkinson carries the structure.** Designed by the Braille Institute for
low-vision legibility, it disambiguates the pairs that collapse at distance and
at small sizes — I/l/1, 0/O, rn/m. Measured against seven alternatives in the
specimen, it is the only one where all three confusable sets resolve:
crossbarred `I`, tailed `l`, slashed `0`. Its name table advertises seven
instances (ExtraLight–ExtraBold), which is what makes hierarchy-by-weight
workable without a second family, and it has a true italic, so `.term` /
`.emph` need no substitute.

**Lora keeps the body.** The hierarchy specimen sets the same paragraph in both
at 9.5pt: Atkinson runs materially wider, costing column width in dense tables,
and over many pages Lora's serifs carry the eye along the line more comfortably.
Slides are exempt — a bullet is a short line, and a slide bullet long enough for
this to matter is a content problem, not a typography one.

## Static vs variable, and why both Atkinsons are here

The graphics devices behind `theme_mariner()` reach fonts through systemfonts,
which resolves a variable TTF's named instances: one file covers every weight,
and a 350-weight axis position is a real interpolated instance. Hence Atkinson
**Next** in its variable cut, which is the family the ggplot2 layer asks for.

XeLaTeX is the opposite case. `fontspec` can load a variable TTF but reaches
only its **default instance**, so bold and italic come out synthesised. Hence
Atkinson Hyperlegible **v1**: where the PDF needs a real bold and a real italic
from this design, v1 supplies four genuine cuts where Next supplies an
interpolation XeLaTeX cannot address. The two are the same design; v1 is the
earlier release, and at heading sizes the difference is not visible.

## Outfit was dropped

It was the Baylor decks' face in `airrosti-3` and `PPP`, and it is not here.

Outfit ships **no italic cut at any weight**, upstream — Google Fonts serves
`Outfit[wght].ttf` and nothing else — and its variable default instance is
*Thin*. Under XeLaTeX that combination means body copy would carry a faked bold
*and* a faked italic on every emphasised word.

The geometric families that do have real italics (Urbanist, Jost, Figtree,
Poppins) were rendered against it and all fail the `Il1` and `0O` tests, because
minimal circular letterforms are exactly what removes the distinguishing
detail — the legibility cost is inherent to the category, not to any one
family. Lexend fails for the same reason as Outfit: no italic.

Nothing in the source material established Outfit as a Baylor *print* face in
any case; every Baylor source is revealjs.

Baylor's brand guide does name official typefaces, which this does not follow.
The trade is made on legibility grounds and for private use.
