# Yoda
## Compile and evaluate programs in OCaml


![OCaml](https://img.shields.io/badge/OCaml-3C873A?logo=ocaml\&logoColor=white)
![WebAssembly](https://img.shields.io/badge/WebAssembly-654FF0?logo=webassembly\&logoColor=white)
[![Build and Push Container](https://github.com/pedrocasais/yoda/actions/workflows/build.yml/badge.svg)](https://github.com/pedrocasais/yoda/actions/workflows/build.yml)
[![Build and Push Sandbox Container](https://github.com/pedrocasais/yoda/actions/workflows/build-sandbox.yml/badge.svg)](https://github.com/pedrocasais/yoda/actions/workflows/build-sandbox.yml)



## 📝 Description
This project is composed of YodaB and YodaC

### YodaB 
Module responsible of api and aims to reduce feedback time, improve consistency in grading, provide analytical data on students’ individual and collective performance, and create a secure and scalable foundation for future integrations with academic systems or online learning platforms.

### YodaC 
Module responsible for compiling and executing program code in a controlled manner, ensuring security and resource limitations. The system will integrate compilers and interpreters for different programming languages and execute the code in an isolated environment (sandbox), preventing unauthorized access to the host system.

## 🏗️ Architecture

```mermaid
graph TB
  subgraph Client
    U[User / Browser]
  end

  subgraph YodaB ["YodaB — REST API (OCaml / Dream) :8001"]
    R[Router]
    AUTH[Auth Module]
    CONT[Contests Module]
    PROB[Problems Module]
    SUB[Submissions Module]
    USR[Users Module]
    JDG[Judge Endpoints]
    R --> AUTH & CONT & PROB & SUB & USR & JDG
  end

  subgraph Store ["Valkey (Redis-compatible) :6379"]
    DB[(Key-Value Store)]
  end

  subgraph YodaC ["YodaC — Sandbox (OCaml / Wasm) :8081"]
    POLL[Judge Worker]
    EXEC[Isolated Container]
    POLL --> EXEC
  end

  U -- "HTTP requests" --> R
  YodaB -- "read / write" --> DB
  POLL -- "GET /judge/next" --> JDG
  EXEC -- "POST /judge/:id/result" --> JDG
```

## 🔧 How It Works

**Workflow Overview:**

```mermaid
flowchart TD
  A[Client Request] -->| POST | B[Send to Yoda API]
  B --> C[YodaC]
  C --> D[Build Docker Container]
  D --> E[Execute and Evaluate Code]
  E --> |Client Response| A
```

## 📦 Container Images

Pre-built images are published to the GitHub Container Registry on every push to `main` and on each release.

| Image | Description |
|-------|-------------|
| `ghcr.io/pedrocasais/yoda` | YodaB — REST API server |
| `ghcr.io/pedrocasais/yoda-sandbox` | YodaC — Compiler & judge sandbox |

**Pull the latest images:**

```bash
docker pull ghcr.io/pedrocasais/yoda:main
docker pull ghcr.io/pedrocasais/yoda-sandbox:main
```

**Pull a specific release:**

```bash
docker pull ghcr.io/pedrocasais/yoda:1.0.0
docker pull ghcr.io/pedrocasais/yoda-sandbox:1.0.0
```
