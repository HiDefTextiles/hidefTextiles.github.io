#!/bin/sh
# Copy the report images that are approved for the public site from the
# project submodules into img/. Only files listed here are published.
# Usage: scripts/sync-assets.sh   (run from the repository root, or via `make sync`)
set -eu

SRC=NSN-2024
DST=img/passap-e6000
MAX=1200   # longest edge in pixels for photos
Q=78       # WebP quality for photos

if [ ! -f "$SRC/main.tex" ]; then
    echo "Submodule $SRC is empty. Run: git submodule update --init" >&2
    exit 1
fi

mkdir -p "$DST" skjol

# All images are published as WebP. GitHub's runner may lack ImageMagick,
# so install it there; locally, install it yourself (apt/brew/winget).
if ! command -v convert >/dev/null 2>&1 && [ "${CI:-}" = true ]; then
    sudo apt-get -qq update && sudo apt-get -qq install -y imagemagick >/dev/null
fi
if ! command -v convert >/dev/null 2>&1; then
    echo "warning: ImageMagick not found, images are copied uncompressed" >&2
fi

# webp SRC DST OPTIONS...: convert to WebP, or copy as-is without ImageMagick
# (browsers sniff the real format, so the page still works).
webp() {
    in="$SRC/myndir/$1"; out="$DST/$2"; shift 2
    if command -v convert >/dev/null 2>&1; then
        convert "$in" "$@" -strip "$out"
    else
        cp "$in" "$out"
    fi
}

# Photos: resized and lossy.
photo() { webp "$1" "$2" -auto-orient -resize "${MAX}x${MAX}>" -quality "$Q"; }

# Pixel-exact files (pattern grids, circuit boards, screenshots): lossless.
plain() { webp "$1" "$2" -define webp:lossless=true; }

photo workshop.jpg                 vinnustofa.webp
photo peacock.jpg                  prjon-pafugl.webp
photo flower.jpg                   prjon-blom.webp
photo repeat.jpg                   prjon-endurtekning.webp
photo gisa/ragga-lowres.JPG        prjon-ragnheidur-50.webp
photo gisa/ragga-hires.JPG         prjon-ragnheidur-120.webp
photo gisa/hallgrimskirkja.JPG     prjon-hallgrimskirkja.webp
photo gisa/collection.JPG          fatnadur.webp

# Photos from Morgunblaðið (mbl.is), shown with credit and a link to the article.
photo elli/e6000.jpg               mbl-passap-e6000.webp
photo elli/electra4600.jpg         mbl-arduino-din6.webp
photo elli/elli.jpg                mbl-vid-velina.webp

plain PASSAPCONTROL.png            rafras-din6.webp
plain PASSAPMOTOR.png              rafras-motor.webp
plain passapiscreen.png            skjar-passapi.webp
plain passapnextscreen.png         skjar-passapnext.webp
plain standup.png                 standup.webp
plain thjms5898_246_0.png          sjonabok-pafugl.webp
plain thjms5898_210.png            sjonabok-blom.webp
plain thjms5898_268.png            sjonabok-endurtekning.webp
plain snaeja/sjonabok_before.png   sjonabok-fyrir.webp
plain snaeja/sjonabok_after.png    sjonabok-eftir.webp
plain snaeja/bordi.png             mynstur-bordi.webp
plain "snaeja/raggajóns.png"       mynstur-ragnheidur.webp
plain snaeja/hallo_heimur.png      mynstur-hallo-heimur.webp
plain snaeja/wfc.png               mynstur-wfc.webp

# The final report and its signed version as downloads.
cp "$SRC/NSN-report.pdf" skjol/NSN-2024-lokaskyrsla.pdf
cp "$SRC/NSN-signed.pdf" skjol/NSN-2024-lokaskyrsla-undirritud.pdf

echo "Synced $(ls "$DST" | wc -l) images to $DST and the report to skjol/"
