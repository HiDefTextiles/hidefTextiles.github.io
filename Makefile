# HiDef textíll website. Requires Quarto (https://quarto.org) and git.
.PHONY: all sync render preview images clean

all: render

# Fetch the report submodule(s) and copy the approved images into img/
sync:
	git submodule update --init --recursive
	sh scripts/sync-assets.sh

# Build the site into _site/
render: sync
	quarto render

# Live preview while writing
preview: sync
	quarto preview

# Compress new images to WebP before committing: make images FILES="a.jpg b.png"
images:
	sh scripts/compress-images.sh $(FILES)

clean:
	rm -rf _site .quarto img/passap-e6000 skjol
