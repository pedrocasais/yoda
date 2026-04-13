.PHONY: start tools

start:
	docker compose up -d --build
	

tools:
	dune exec tools/generator.exe
	python3 tools/schemas.py