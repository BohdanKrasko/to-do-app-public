FROM golang:alpine AS builder

WORKDIR /app

COPY . .

RUN apk add --no-cache git
RUN go build -v -o todo-app .

FROM alpine:latest

WORKDIR /root

RUN apk --no-cache add ca-certificates

COPY --from=builder /app/todo-app .
COPY --from=builder /app/.env .


ENTRYPOINT ./todo-app


