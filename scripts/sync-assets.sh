#!/bin/sh
# Copy the report images that are approved for the public site from the
# project submodules into img/. Only files listed here are published.
# Usage: scripts/sync-assets.sh   (run from the repository root, or via `make sync`)
set -eu

SRC=NSN-2024
DST=img/passap-e6000
MAX=1600   # longest edge in pixels for photos

if [ ! -f "$SRC/main.tex" ]; then
    echo "Submodule $SRC is empty. Run: git submodule update --init" >&2
    exit 1
fi

mkdir -p "$DST" skjol

# Photos: resized when ImageMagick is available, copied as-is otherwise.
photo() {
    if command -v convert >/dev/null 2>&1; then
        convert "$SRC/myndir/$1" -auto-orient -resize "${MAX}x${MAX}>" -strip -quality 82 "$DST/$2"
    else
        cp "$SRC/myndir/$1" "$DST/$2"
    fi
}

# Pixel-exact files (pattern grids, circuit boards, screenshots): plain copy.
plain() {
    cp "$SRC/myndir/$1" "$DST/$2"
}

photo workshop.jpg                 vinnustofa.jpg
photo peacock.jpg                  prjon-pafugl.jpg
photo flower.jpg                   prjon-blom.jpg
photo repeat.jpg                   prjon-endurtekning.jpg
photo gisa/ragga-lowres.JPG        prjon-ragnheidur-50.jpg
photo gisa/ragga-hires.JPG         prjon-ragnheidur-120.jpg
photo gisa/hallgrimskirkja.JPG     prjon-hallgrimskirkja.jpg
photo gisa/collection.JPG          fatnadur.jpg

# Photos from Morgunblaðið (mbl.is), shown with credit and a link to the article.
photo elli/e6000.jpg               mbl-passap-e6000.jpg
photo elli/electra4600.jpg         mbl-arduino-din6.jpg
photo elli/elli.jpg                mbl-vid-velina.jpg

plain PASSAPCONTROL.png            rafras-din6.png
plain PASSAPMOTOR.png              rafras-motor.png
plain passapiscreen.png            skjar-passapi.png
plain passapnextscreen.png         skjar-passapnext.png
plain standup.png                 standup.png
plain thjms5898_246_0.png          sjonabok-pafugl.png
plain thjms5898_210.png            sjonabok-blom.png
plain thjms5898_268.png            sjonabok-endurtekning.png
plain snaeja/sjonabok_before.png   sjonabok-fyrir.png
plain snaeja/sjonabok_after.png    sjonabok-eftir.png
plain snaeja/bordi.png             mynstur-bordi.png
plain "snaeja/raggajóns.png"       mynstur-ragnheidur.png
plain snaeja/hallo_heimur.png      mynstur-hallo-heimur.png
plain snaeja/wfc.png               mynstur-wfc.png

# The final report and its signed version as downloads.
cp "$SRC/NSN-report.pdf" skjol/NSN-2024-lokaskyrsla.pdf
cp "$SRC/NSN-signed.pdf" skjol/NSN-2024-lokaskyrsla-undirritud.pdf

echo "Synced $(ls "$DST" | wc -l) images to $DST and the report to skjol/"
