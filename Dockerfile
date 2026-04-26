# syntax=docker/dockerfile:1
# 1. 构建后端Go程序（匹配源码要求的Go 1.25版本）
FROM --platform=$BUILDPLATFORM golang:1.25-alpine AS builder
WORKDIR /app

# 先安装必须的工具：git + 编译依赖
RUN apk add --no-cache git build-base ca-certificates tzdata

# 配置Go代理，解决GitHub Actions下载依赖超时问题
ENV GOPROXY=https://goproxy.io,direct
ENV CGO_ENABLED=0

# 分步拉取依赖，优化构建缓存
COPY go.mod go.sum ./
RUN go mod download

# 复制全部代码并编译主程序
COPY . .
RUN go build -ldflags "-s -w" -o alist main.go

# 2. 打包最终轻量化运行镜像
FROM alpine:latest
WORKDIR /opt/alist

# 复制主程序和前端静态文件
COPY --from=builder /app/alist ./
COPY --from=builder /app/public ./public

# 安装运行必备依赖
RUN apk add --no-cache ca-certificates tzdata

# 暴露Alist默认端口
EXPOSE 5244

# 容器启动命令
ENTRYPOINT ["/opt/alist/alist", "server"]
