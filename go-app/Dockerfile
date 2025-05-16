# Build stage
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go mod tidy && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o secret-watcher .

# Final stage
FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/secret-watcher .
ENV SECRET_NAMESPACE=""
ENV SECRET_NAME=""
CMD ["./secret-watcher"]
