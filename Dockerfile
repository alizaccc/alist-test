# 构建阶段
FROM golang:1.22-alpine AS builder
WORKDIR /app
# 安装编译依赖
RUN apk add --no-cache git build-base
# 复制源码
COPY . .
# 编译Alist，启用CGO，关闭调试信息减小体积
RUN CGO_ENABLED=1 go build -ldflags "-s -w" -o alist main.go

# 运行阶段
FROM alpine:latest
WORKDIR /opt/alist
# 安装运行依赖
RUN apk add --no-cache ca-certificates tzdata
# 设置时区
ENV TZ=Asia/Shanghai
# 从构建阶段复制编译好的二进制文件
COPY --from=builder /app/alist /opt/alist/alist
# 暴露端口
EXPOSE 5244
# 数据卷持久化
VOLUME /opt/alist/data
# 启动命令
ENTRYPOINT ["/opt/alist/alist", "server"]
