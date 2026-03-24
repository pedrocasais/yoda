.PHONY: start tools

start:
	docker compose up -d --build
	$(MAKE) tools

tools:
	dune exec tools/generator.exe
	python3 tools/schemas.py