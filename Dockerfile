FROM golang:latest as builder
WORKDIR /go/src/github.com/aaronnbrock/hello-graphql/
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

FROM alpine:latest
WORKDIR /root/
COPY --from=builder /go/src/github.com/aaronnbrock/hello-graphql/app .
ENTRYPOINT [ "./app" ]