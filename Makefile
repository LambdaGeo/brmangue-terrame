# Runs BR-MANGUE headless in the TerraME Docker image and writes the golden CSVs
# (uso, solo, alt of every cell, initial state first) used by brmangue-dissmodel.
#
#   make data                          download the Maranhão Island cells (once)
#   make golden TAXA=0.05 FINAL=19     baseline scenario  -> golden/step_01.csv ...
#   make golden TAXA=0.5  FINAL=11 OUT=golden_flood     flooding scenario
#
# Requires Docker. Pin the image for reproducible results, e.g.
#   make golden IMAGE=profsergiocosta/terrame-luccme:0.4.2
IMAGE ?= profsergiocosta/terrame-luccme
TAXA  ?= 0.05
FINAL ?= 19
MARE  ?= 6
OUT   ?= golden
DATA_URL ?= https://raw.githubusercontent.com/DisSModel/brmangue-dissmodel/v0.3.0/examples/data/input/elevacao_pol.zip

.PHONY: data golden clean
data: data/ilha/elevacao_pol.shp

data/ilha/elevacao_pol.shp:
	mkdir -p data/ilha
	curl -fsSL "$(DATA_URL)" -o data/ilha/elevacao_pol.zip
	cd data/ilha && unzip -oq elevacao_pol.zip && rm elevacao_pol.zip

golden: data
	mkdir -p $(OUT)
	docker run --rm --user "$$(id -u):$$(id -g)" -v "$$PWD":/work \
	  -e TAXA=$(TAXA) -e FINAL=$(FINAL) -e MARE=$(MARE) -e OUT=$(OUT) \
	  $(IMAGE) golden.lua
	@ls $(OUT) | wc -l | xargs echo "files in $(OUT)/"

clean:
	rm -rf golden golden_flood recorte.qgs data/ilha
