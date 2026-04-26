# syntax=docker/dockerfile:1
# 1. 构建前端
FROM --platform=$BUILDPLATFORM node:20-alpine AS frontend
WORKDIR /app
COPY web/ ./
RUN npm install
RUN npm run build

# 2. 构建后端Go程序
FROM --platform=$BUILDPLATFORM golang:1.22-alpine AS backend
WORKDIR /app
# 把前端构建产物复制进来
COPY --from=frontend /app/dist ./public/dist
# 构建后端
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o alist main.go

# 3. 打包最终运行镜像
FROM alpine:latest
WORKDIR /opt/alist
# 复制主程序和静态资源
COPY --from=backend /app/alist ./
COPY --from=backend /app/public ./public
# 安装依赖
RUN apk add --no-cache ca-certificates tzdata
# 暴露端口
EXPOSE 5244
# 启动命令
ENTRYPOINT ["/opt/alist/alist", "server"]
RUN /entrypoint.sh version

ENV PUID=0 PGID=0 UMASK=022 RUN_ARIA2=${INSTALL_ARIA2}
VOLUME /opt/alist/data/
EXPOSE 5244 5245
CMD [ "/entrypoint.sh" ]
