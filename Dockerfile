# 第一阶段：编译 Go 后端
FROM --platform=$BUILDPLATFORM golang:1.25-alpine AS builder
WORKDIR /app

# 安装必要的工具
RUN apk add --no-cache git curl build-base

# 自动下载 Alist 官方的最新前端文件（无需手动打包前端）
RUN mkdir -p public/dist && \
    curl -L https://github.com/alist-org/web-dist/archive/refs/heads/main.tar.gz -o web-dist.tar.gz && \
    tar -xzf web-dist.tar.gz && \
    mv web-dist-main/dist/* public/dist/ && \
    rm -rf web-dist-main web-dist.tar.gz

# 拷贝全部代码并下载依赖
COPY . .
RUN go mod tidy

# 获取目标系统架构并构建（支持多架构编译），禁用 CGO 以确保纯静态编译
ARG TARGETOS
ARG TARGETARCH
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -ldflags="-w -s" -tags=jsoniter -o alist main.go

# 第二阶段：构建最终镜像
FROM alpine:latest
LABEL maintainer="zsy823"

# 安装时区及基础证书
RUN apk add --no-cache ca-certificates tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

WORKDIR /opt/alist/

# 从编译阶段拷贝编译好的二进制文件
COPY --from=builder /app/alist ./

VOLUME /opt/alist/data
EXPOSE 5244

CMD ["./alist", "server"]
