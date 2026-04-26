# syntax=docker/dockerfile:1
FROM alpine:latest
WORKDIR /opt/alist

# 安装Alist运行必须的全量依赖，避免缺失系统库导致静默崩溃
RUN apk add --no-cache ca-certificates tzdata libc6-compat su-exec

# 复制编译好的主程序，设置可执行权限
COPY alist /opt/alist/alist
RUN chmod 755 /opt/alist/alist

# 核心修复：完整复制前端静态资源public目录（Alist启动必须依赖，缺失会直接静默退出）
COPY public /opt/alist/public
RUN chmod -R 755 /opt/alist/public

# 创建数据目录，开放读写权限，避免数据库写入失败崩溃
RUN mkdir -p /opt/alist/data && chmod -R 777 /opt/alist/data

# 暴露Alist默认端口
EXPOSE 5244

# 健康检查，自动检测服务是否正常运行
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD wget -qO- http://localhost:5244/ || exit 1

# 容器启动命令，指定数据目录，确保启动路径正确
ENTRYPOINT ["/opt/alist/alist", "server", "--data", "/opt/alist/data"]
