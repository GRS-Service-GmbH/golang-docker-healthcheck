# Stage 1: Use a builder as first stage to build the application
FROM golang:1.22 AS builder

RUN adduser application
USER application

COPY --chown=application ./ /build
WORKDIR /build

RUN mkdir out

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /build/out/server
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /build/out/healthcheck ./healthcheck/healthcheck.go
# Alternatively, if you want to build the healthcheck from github dirctly, you can use the following command instead:
# RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /build/healthcheck "github.com/GRS-Service-GmbH/golang-docker-healthcheck/healthcheck"


# Stage 2: Create release image from scratch and copy both artifacts from the builder stage
FROM scratch

COPY --from=builder /build/out/server ./server
COPY --from=builder /build/out/healthcheck ./healthcheck

HEALTHCHECK --interval=1s --timeout=1s --start-period=2s --retries=3 CMD [ "/healthcheck" ]

ENV PORT=8080
EXPOSE $PORT

ENTRYPOINT [ "/server" ]
