start:
	docker compose up -d --build
	dune exec tools/generator.exe