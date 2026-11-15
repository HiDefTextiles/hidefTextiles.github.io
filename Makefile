# HiDef textíll website. Requires Quarto (https://quarto.org) and git.
.PHONY: all sync render preview clean

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

clean:
	rm -rf _site .quarto img/passap-e6000 skjol
