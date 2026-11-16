#!/bin/sh
# Compress images for the web before committing them: WebP, longest edge
# at most MAX pixels. The original is replaced by <name>.webp.
# Usage: scripts/compress-images.sh FILE...     (or: make images FILES="...")
#        MAX=1080 Q=78 scripts/compress-images.sh img/instagram/vefnadur/*.jpg
# Pixel-exact images (pattern grids, schematics, screenshots): LOSSLESS=1.
set -eu
MAX=${MAX:-1200}
Q=${Q:-78}
command -v convert >/dev/null 2>&1 || { echo "Install ImageMagick first" >&2; exit 1; }
for f in "$@"; do
    out="${f%.*}.webp"
    if [ "${LOSSLESS:-0}" = 1 ]; then
        convert "$f" -strip -define webp:lossless=true "$out"
    else
        convert "$f" -auto-orient -resize "${MAX}x${MAX}>" -quality "$Q" -strip "$out"
    fi
    [ "$f" = "$out" ] || rm -f "$f"
    echo "$out $(wc -c < "$out") bytes"
done
