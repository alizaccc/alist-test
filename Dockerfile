# syntax=docker/dockerfile:1
# 1. 构建后端Go程序
FROM --platform=$BUILDPLATFORM golang:1.22-alpine AS builder
WORKDIR /app
# 复制依赖
COPY go.mod go.sum ./
RUN go mod download
# 复制全部代码
COPY . .
# 编译主程序
RUN CGO_ENABLED=0 go build -o alist main.go

# 2. 打包最终运行镜像
FROM alpine:latest
WORKDIR /opt/alist
# 复制主程序
COPY --from=builder /app/alist ./
# 复制前端静态文件
COPY --from=builder /app/public ./public
# 安装运行依赖
RUN apk add --no-cache ca-certificates tzdata
# 暴露端口
EXPOSE 5244
# 启动命令
ENTRYPOINT ["/opt/alist/alist", "server"]
