FROM golang:1.25-alpine AS build
WORKDIR /src
COPY go.mod main.go ./
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /relay .

FROM alpine:3.20
RUN apk add --no-cache ca-certificates
COPY --from=build /relay /relay
USER 65534
ENTRYPOINT ["/relay"]
