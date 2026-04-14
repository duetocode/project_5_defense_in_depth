# PostgreSQL Security Demo

## Prerequisite

A Docker engine installation, such as Docker Desktop or OrbStack.

## How to start the project

1. Enter the project directory.
2. Build the hardened PostgreSQL image and start the cluster:

```bash
docker compose up -d --build
```

The PostgreSQL service now builds from [postgres_hardened/Dockerfile](postgres_hardened/Dockerfile), and the CIS hardening playbook is executed during image build only.

If host port 5432 is already in use on your machine, start the stack with a different exposed PgBouncer port:

```bash
PGBOUNCER_HOST_PORT=15432 docker compose up -d --build
```

## Runtime CIS audit

The runtime audit is intentionally separate from image build so it verifies the final live system. After the cluster is healthy, run:

```bash
docker compose --profile audit run --rm audit
```

This starts a one-off audit container on the backend network and runs [postgres_hardened/hardening/audit.yml](postgres_hardened/hardening/audit.yml) against the running `postgres` service.
The root audit playbook executes all implemented controls and reports any failure in a single run.

## Access the database with the legit client

You can access the database via the `client` container:

1. Access the bash shell of the container:

```bash
docker compose exec client bash
```

2. Connect to the database:

```bash
psql "host=database port=5432 dbname=mydb user=finance sslmode=verify-full sslcert=/certs/client.crt sslkey=/certs/client.key sslrootcert=/certs/ca.crt"
```

The password of the client's secret key is `xipXig-xohryq-hebno6`.

## Implementation notes

- Build-time hardening is orchestrated by [postgres_hardened/hardening/playbook.yml](postgres_hardened/hardening/playbook.yml).
- CIS 3.1.20 is applied by editing PostgreSQL sample configuration files in the image filesystem, so newly initialized clusters inherit `log_connections = 'on'` without live SQL changes.
- The control stored under [postgres_hardened/hardening/controls/cis_4_3_admin_privileges](postgres_hardened/hardening/controls/cis_4_3_admin_privileges) implements CIS benchmark section 4.5 by revoking excessive function execute privileges from `PUBLIC` during cluster initialization and auditing the live database for privileged user-defined functions.
- The runtime audit targets `postgres` directly on the backend network rather than the `database` PgBouncer service, because the control applies to PostgreSQL itself.

---

## Rules for the attacker

### Setup

1. You will be provided with a `docker-compose.yml` file inside the `with_proxy` directory. Run it to start the environment. It will spin up a client, a proxy, and a database container, each already configured with certificates.
2. To simulate a legitimate user, enter the client container, connect to the database, and interact with it as an approved user.

### Attacker rules

3. You are not allowed to use any Docker commands (`docker exec`, `docker inspect`, `docker logs`, and similar). Everything must be discovered manually.
4. You must work from your laptop terminal only, with no direct container shell access.
5. You start with zero knowledge. You do not know any IP addresses, usernames, passwords, port numbers, or service names. Everything must be discovered by yourself.
6. You have access to the `frontend` network only, which is the same network as the client. The database and other infrastructure servers are deployed inside an isolated `backend` network, which is not directly accessible to you.
7. You are not allowed to modify the `docker-compose.yml` file or any configuration files.
8. You are not allowed to stop or restart any containers.

### Goal

9. Your goal is to gain access to the database and retrieve the data from it by any means available within these rules.

### Hint

10. Start by discovering what is on the network.
