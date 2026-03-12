start:
	docker compose up -d --build
	dune exec tools/parser.exe