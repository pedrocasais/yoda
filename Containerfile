FROM ocaml/opam:debian-ocaml-5.2

# Install system dependencies
USER root
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        m4 make gcc pkg-config libev-dev libgmp-dev libssl-dev docker-cli && \
    rm -rf /var/lib/apt/lists/*

# Add opam user to docker group (999) to allow socket access
RUN groupadd -r -g 999 docker
RUN usermod -a -G docker opam

# Switch back to the opam user for package installation
USER opam
WORKDIR /home/opam/app

# Copy only the project files needed for dependency resolution first
COPY --chown=opam:opam dune-project ./
COPY --chown=opam:opam *.opam ./

# Install OCaml dependencies (cached if no .opam files change)
RUN opam update && \
    opam install -y . --deps-only

# Copy the rest of the source code
COPY --chown=opam:opam . .

# Build the project
RUN eval $(opam env) && dune build

# Expose your app (if it listens on a port)
EXPOSE 8080

# Run the application
CMD ["dune", "exec", "./server.exe"]
