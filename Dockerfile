# 第一阶段：构建前端
FROM node:18-alpine AS frontend
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

# 第二阶段：编译 Go 后端
FROM golang:1.22-alpine AS builder
RUN apk add --no-cache gcc musl-dev
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
COPY --from=frontend /app/public/dist ./public/dist
RUN go build -ldflags="-s -w" -o alist .

# 第三阶段：运行镜像
FROM alpine:3.19
RUN apk add --no-cache tzdata ca-certificates
COPY --from=builder /app/alist /usr/local/bin/alist
EXPOSE 5244
VOLUME /opt/alist/data
WORKDIR /opt/alist
ENTRYPOINT ["alist"]
# 暴露端口
EXPOSE 5244
# 数据卷持久化
VOLUME /opt/alist/data

# 启动命令
ENTRYPOINT ["/opt/alist/alist", "server"]
