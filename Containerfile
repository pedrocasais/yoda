FROM ocaml/opam:debian-ocaml-5.2

# Install system dependencies
USER root
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        python3 python3-venv python3-yaml \
        m4 make gcc pkg-config libev-dev libgmp-dev libssl-dev docker-cli && \
    rm -rf /var/lib/apt/lists/*

# Add opam user to docker group
RUN groupadd -r -g 999 docker
RUN usermod -a -G docker opam

# Switch back to the opam user
USER opam
WORKDIR /home/opam/app

# Copy project files for dependency resolution
COPY --chown=opam:opam dune-project ./
COPY --chown=opam:opam *.opam ./

# Install OCaml dependencies
RUN opam update && \
    opam install -y . --deps-only

# Copy source code
COPY --chown=opam:opam . .

# Generate schemas
RUN make openapi-yaml-to-json

# Build project
RUN eval $(opam env) && dune build --profile=release

# Expose port
EXPOSE 8001

# Run application
CMD ["dune", "exec", "./src/yodab.exe"]