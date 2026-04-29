# 构建阶段：使用与go.mod匹配的Go 1.25版本，解决版本兼容问题
FROM golang:1.25-alpine AS builder
WORKDIR /app

# 安装编译依赖，启用国内镜像加速，避免apk拉取失败
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    && apk add --no-cache git build-base ca-certificates tzdata

# 配置Go模块代理，解决国内环境依赖拉取失败问题，自动匹配go.mod要求的工具链
ENV GOPROXY=https://goproxy.cn,direct
ENV GOTOOLCHAIN=auto

# 复制源码并更新依赖
COPY . .
RUN go mod tidy

# 编译Alist，启用CGO，关闭调试信息减小体积，兼容多架构
RUN CGO_ENABLED=1 go build -ldflags "-s -w -X main.version=custom-halalcloud" -o alist main.go

# 运行阶段
FROM alpine:latest
WORKDIR /opt/alist

# 配置国内镜像，安装运行依赖
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    && apk add --no-cache ca-certificates tzdata

# 设置时区
ENV TZ=Asia/Shanghai
# 关闭Alist自动更新，避免覆盖自定义镜像
ENV ALIST_DISABLE_AUTO_UPDATE=true

# 从构建阶段复制编译好的二进制文件
COPY --from=builder /app/alist /opt/alist/alist
# 复制前端静态资源（你的仓库已包含public目录，避免前端缺失）
COPY --from=builder /app/public /opt/alist/public

# 暴露端口
EXPOSE 5244
# 数据卷持久化
VOLUME /opt/alist/data

# 启动命令
ENTRYPOINT ["/opt/alist/alist", "server"]
