# -------------------------
# Build stage
# -------------------------
FROM ocaml/opam:debian-ocaml-5.2 AS builder

USER root

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        python3 python3-venv python3-yaml \
        m4 make gcc pkg-config \
        libev-dev libgmp-dev libssl-dev \
        libffi-dev libargon2-dev \
    && rm -rf /var/lib/apt/lists/*

USER opam
WORKDIR /home/opam/app

COPY --chown=opam:opam dune-project ./
COPY --chown=opam:opam *.opam ./

RUN opam update && \
    opam install -y . --deps-only

COPY --chown=opam:opam . .

RUN make openapi-yaml-to-json

RUN eval $(opam env) && \
    dune build --profile=release

# -------------------------
# Runtime stage
# -------------------------
FROM debian:trixie-slim AS runtime

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        libev4 \
        libgmp10 \
        libssl3 \
        libffi8 \
        libargon2-1 \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash app

USER app
WORKDIR /home/app

COPY --from=builder --chown=app:app \
    /home/opam/app/_build/default/src/yodab.exe \
    ./yodab.exe

COPY --from=builder --chown=app:app \
    /home/opam/app/_build/default/src/yodac.exe \
    ./yodac.exe

COPY --from=builder --chown=app:app \
    /home/opam/app/languages.yaml \
    ./languages.yaml

EXPOSE 8001

CMD ["./yodab.exe"]