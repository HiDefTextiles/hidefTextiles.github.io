# HiDef textíll – vefur

Public website of **HiDef textíll**, a research project at Háskóli Íslands led by
Helga Ingimundardóttir, lektor í iðnaðarverkfræði. The site is a set of how-to guides
for textile projects, written in Icelandic. The first project is the Passap E6000
knitting machine, based on the report in the `NSN-2024` submodule.

Built with [Quarto](https://quarto.org) and the HÍ look from
[HI-IDN/quarto-hi](https://github.com/HI-IDN/quarto-hi) (MIT).

## Quickstart

```bash
git clone --recurse-submodules https://github.com/HiDefTextiles/hidefTextiles.github.io.git
cd hidefTextiles.github.io
make preview    # live preview
make render     # build into _site/
make clean
```

Requires Quarto 1.5+. ImageMagick is optional (photos are resized when it is installed).

## Layout

| Path | Purpose |
|---|---|
| `_quarto.yml` | Site config, navigation |
| `index.qmd`, `um.qmd`, `samband.qmd`, `hugbunadur.qmd`, `nam.qmd`, `ordalisti.qmd`, `heimildir.qmd` | Top-level pages |
| `prjonavel/`, `sjonabok/`, `mynsturgerd/` | Topics, each with a landing page and book-like chapters |
| `verkefnid/` | The NSN 2024 project story (all report chapters) |
| `heimildir.bib` | Bibliography; every page cites its source |
| `NSN-2024/` | Submodule: the report the Passap pages are based on |
| `scripts/sync-assets.sh` | Copies the approved report images and PDF into the site |
| `styles/` | `hi-site.scss`, `hi-watermark.css` (from quarto-hi) and `hidef.scss` |
| `_includes/eu-translator.html` | EU WEB-T translator for the header (needs Hub URL and Client-ID) |

## Content rules

- Nothing is invented. All content comes from the project reports and repositories.
- Every page ends with a `.heimild` box naming the report sections or repository it is based on.
- New topics follow `nytt-vidfangsefni.qmd`.

## Deploy

Pushing to `main` runs `.github/workflows/deploy.yml`, which checks out the submodule,
renders with Quarto and deploys to GitHub Pages.
