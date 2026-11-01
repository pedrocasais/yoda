# Infrastructure architecture

This diagram shows the reference deployment of Yoda: how traffic enters the platform, which services run on the server, and where data, logs, and backups live.

```mermaid
flowchart LR
  subgraph FE ["FRONTEND"]
    CLIENT["Browser / client"]
  end

  subgraph SRV ["Servidor / backend"]
    direction LR

    subgraph EDGE ["Ingestion"]
      TRAEFIK["Traefik<br/>- Encapsulate data from HTTPS<br/>- Let's Encrypt certificates"]
    end

    subgraph YODAB ["Yoda (critical)"]
      YODA["Yoda - brain of Yoda<br/>- Implements a REST API<br/>- Authentication using bcrypt or argon2<br/>- Permissions (sessions)<br/>- Submissions and code management (files or plain text)<br/>- Admin panel (WebAuthn, maximum permission)<br/>- Privileged users (two-step / 2FA)<br/>- Users: show results"]
    end

    subgraph YODAC ["YodaC - Compiling (critical)"]
      YC["YodaC<br/>- Sandboxing and compiling code"]
    end

    subgraph ENGINE ["Docker"]
      DOCKER["Docker<br/>Manage images"]
    end

    subgraph STORE ["Valkey (critical)"]
      VALKEY["Valkey<br/>- Persistent data, with RDB or AOF<br/>- Data grouping for efficient search"]
      VOL[("local<br/>/var/lib/docker/volumes")]
    end

    subgraph BACKUP ["Backups"]
      BORG["Borg<br/>- Backups of data<br/>- Docker volume shared between Valkey and dump.rdb"]
    end

    subgraph AUDIT ["Audit and Logs"]
      LOGS["Audit and Logs<br/>- Logs of executed operations<br/>- Monitor Yoda and YodaC"]
    end
  end

  CLIENT -->|"HTTPS"| TRAEFIK
  TRAEFIK -->|"http :8080"| YODA
  YODA <-->|"RESP TCP :6379"| VALKEY
  YC <-->|"RESP TCP :6379"| VALKEY
  YC -->|"Socket"| DOCKER
  VALKEY --- VOL
  VOL -->|"Backup"| BORG
  VALKEY -->|"RESP TCP :6379"| LOGS
```

## Components

| Component | Role |
|-----------|------|
| **Traefik** | Entry point. Receives requests from the client, encapsulates the data in HTTPS using Let's Encrypt certificates, and forwards them to Yoda. |
| **Yoda** | The REST API. Handles authentication (bcrypt or Argon2), permissions through sessions, submissions and code management, the admin panel, and results. |
| **YodaC** | Compiles and runs submissions in a sandbox. It uses Valkey for its queue and data, and the Docker socket to start and manage containers and images. |
| **Valkey** | Persistent data store, using RDB or AOF, with data grouped for efficient search. Its data lives in a local Docker volume. |
| **Docker** | Container engine used by YodaC, reached through its socket. |
| **Borg** | Backs up the Valkey data volume, shared between Valkey and `dump.rdb`. |
| **Audit and Logs** | Records the operations that were executed and lets you monitor Yoda and YodaC. |

Yoda, Valkey, and YodaC are marked as critical in the original diagram.

## Notes

- This is the reference architecture. The repository's `docker-compose.yaml` starts a smaller development stack, with the web frontend proxying `/api` to YodaB instead of Traefik, and without Borg backups or the audit and log service.
- YodaB listens on port `8001` in the current code, while the original diagram labels the Traefik-to-Yoda link as port `8080`. Confirm the port when you configure the proxy.
