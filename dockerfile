# 构建 beancount
FROM python:3.7.16-alpine as beancount_builder

ARG BEANCOUNT_VERSION=2.3.6

WORKDIR /build

RUN apk add --no-cache gcc musl-dev python3-dev libffi-dev openssl-dev && \
    python3 -m venv /app && \
    wget https://github.com/beancount/beancount/archive/refs/tags/${BEANCOUNT_VERSION}.tar.gz && \
    tar -zxvf ${BEANCOUNT_VERSION}.tar.gz && \
    python3 -m pip install ./beancount-${BEANCOUNT_VERSION} && \
    find /app -name __pycache__ -exec rm -rf {} +

# 构建 beancount-gs
FROM golang:1.17.3-alpine AS go_builder

ENV GO111MODULE=on \
    GIN_MODE=release \
    CGO_ENABLED=0 \
    PORT=80

WORKDIR /build
COPY . .
COPY public/icons ./public/default_icons
RUN go build .

# 镜像
FROM python:3.7.16-alpine

COPY --from=beancount_builder /app /app

WORKDIR /app
COPY --from=go_builder /build/beancount-gs ./
COPY --from=go_builder /build/template ./template
COPY --from=go_builder /build/config ./config
COPY --from=go_builder /build/public ./public
COPY --from=go_builder /build/logs ./logs

ENV PATH "/app/bin:$PATH"

EXPOSE 80