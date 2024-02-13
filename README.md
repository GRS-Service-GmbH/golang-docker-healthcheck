# Golang Docker HEALTHCHECK
### Simple HEALTHCHECK solution for Go Docker container

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/GRS-Service-GmbH/golang-docker-healthcheck/blob/master/LICENSE.md)

## The Problem
We usually add a `HEALTHCHECK` instruction to our Dockerfiles and then check their status with the `docker inspect` command.
Usually the health check performs an http request to server endpoint, and if it succeeds the server is considered in healthy condition.
In Linux-based containers we do it with the `curl` or `wget` command.
The problem is that in containers built from scratch there are no such commands.

## Solution
We decided to add a new package that contains several lines...

```go
_, err := http.Get(fmt.Sprintf("http://127.0.0.1:%s/health", os.Getenv("PORT")))
if err != nil {
	os.Exit(1)
}
```

... and then build the package as another executable, and add the `HEALTHCHECK` instruction to the `Dockerfile`

```docker
# Stage 1: Use a builder as first stage
...
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /build/server
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /build/healthcheck "github.com/GRS-Service-GmbH/golang-docker-healthcheck/healthcheck"

# Stage 2: Create release image from scratch and copy both artifacts from the builder stage
FROM scratch

COPY --from=builder /build/server ./server
COPY --from=builder /build/healthcheck ./healthcheck

ENV PORT=8000
EXPOSE $PORT

HEALTHCHECK --interval=1s --timeout=1s --start-period=2s --retries=3 CMD [ "/healthcheck" ]

ENTRYPOINT [ "/server" ]
```

So we now have two executables in the docker container: the server and the healthcheck utility.

## Conclusion
In this repository we demonstrated a health-check for a server implemented in Go, for a docker container built from scratch.
