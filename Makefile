.PHONY: start atd-to-dream openapi-yaml-to-json openapi-json-to-atd openapi-all

start:
	docker compose up -d --build

build:
	dune build --profile=release @doc @install

atd-to-ml:
	cd ./src && atdml ./../schemas/atd/openapi.atd

atd-to-dream:
	dune build tools/atd2dream/generator.exe
	dune exec -- tools/atd2dream/generator.exe "./schemas/openapi.yaml"

openapi-yaml-to-json:
	./tools/convert-openapi/run.sh

openapi-json-to-atd:
	mkdir -p ./schemas/atd
	jsonschema2atd --format openapi ./schemas/json/openapi.json > ./schemas/atd/openapi.atd

openapi-all: openapi-yaml-to-json openapi-json-to-atd

all: openapi-all atd-to-dream atd-to-ml build

clean:
	dune clean
	rm -rf _build