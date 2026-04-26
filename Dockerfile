# syntax=docker/dockerfile:1
# 最终运行镜像
FROM alpine:latest
WORKDIR /opt/alist

# 复制Actions里提前编译好的主程序
COPY alist ./
# 复制前端静态文件
COPY public ./public

# 安装运行必备依赖
RUN apk add --no-cache ca-certificates tzdata

# 暴露Alist默认端口
EXPOSE 5244

# 容器启动命令
ENTRYPOINT ["/opt/alist/alist", "server"]
