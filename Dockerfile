# Build stage
FROM golang:1.26-alpine AS builder

WORKDIR /app

# Copy dependencies first for Docker layer caching
COPY go.mod go.sum* ./
RUN go mod download

# Copy application source
COPY . .

# Build a statically linked binary
RUN CGO_ENABLED=0 GOOS=linux go build \
    -tags lambda.norpc \
    -trimpath \
    -ldflags="-s -w" \
    -o /app/server .

# Runtime stage
FROM gcr.io/distroless/static-debian12:nonroot

WORKDIR /app

# Copy compiled binary
COPY --from=builder /app/server /app/server

# Run application
ENTRYPOINT ["/app/server"]
