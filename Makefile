start:
	docker compose up -d --build
	dune exec tools/generator.exe
	python3 tools/schemas.py