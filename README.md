# SQS Lambda Golang Example

## Pre-requisites

`docker version 17+` See how to download and install in [Docker site.](https://docs.docker.com/install/linux/docker-ce/ubuntu/)

`docker-compose version 1.20+` See how to download and install in [Docker site.](https://docs.docker.com/compose/install/#install-compose)

`golang version 1.11+`  See how to download and install in [Golang site.](https://golang.org/doc/install)

`awscli-local` See how to download and install in [Aws cli github](https://github.com/localstack/awscli-local)

---

## Development

Start development container:

```bash
make start
```

To send a message to SQS, type:
```
awslocal sqs send-message --queue-url http://localhost:4576/queue/example --message-body '{"ID": "1","EMAIL": "example@example.com"}'
```

Update lambda code:
```bash
make update-lambda
```

Run lint:
```bash
make lint
```

---

## Tests

Run Unit tests:

```bash
make unit-tests
```

Genarate coverage:

```bash
make coverage
```
---
