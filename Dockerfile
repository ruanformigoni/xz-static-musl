FROM alpine:latest

RUN apk add --no-cache bash curl upx xz build-base git

COPY . /build

WORKDIR build

RUN ./build.sh
