# 格式：origin_name [new_name] [platform]
#
# 字段说明：
# 1 个字段：原始名字（自动生成新名字）
# 2 个字段：原始名字 + (new_name 或 platform)
#         - 如果第二个字段是 [...] 格式，则是 platform
#         - 否则是 new_name
# 3 个字段：原始名字 new_name platform
#
# 命名规则：
# - 自定义 new_name：直接使用 new_name
# - 自动生成：取原始镜像最后一段，去掉 / 符号
# - 架构：只有用中括号 [] 包裹的才是架构，例如 [arm64]、[amd64]
# - 架构后缀规则：
#   * x86/amd64 架构：不加后缀
#   * 其他架构（如 arm64）：所有镜像都添加 -xxx 后缀
#   * 这样可以避免不同架构的镜像互相覆盖

# ============================================
# 示例 1：简单名字，自动生成新名字（x86）
# ============================================
# nginx                              # -> nginx
# dotnet/aspnet:6.0                  # -> dotnetaspnet:6.0

# ============================================
# 示例 2：绝对地址，自动生成新名字（x86）
# ============================================
# docker.io/library/node:20-alpine   # -> node:20-alpine

# ============================================
# 示例 3：自定义新名字（第二个字段不是 [...] 格式）
# ============================================
# node:20-alpine my-node:20          # -> my-node:20

# ============================================
# 示例 4：自动生成 + 架构（第二个字段是 [...] 格式）
# ============================================
# python:3.13-slim [arm64]            # -> python:3.13-slim-arm64
# dotnet/aspnet:6.0 [arm64]          # -> aspnet:6.0-arm64

# ============================================
# 示例 5：自定义名字 + 架构（3 个字段，添加架构后缀）
# ============================================
# node:20-alpine my-node:20 [arm64]  # -> my-node:20-arm64

# ============================================
# 实际配置
# ============================================

# 默认 x86 架构（自动生成）
amir20/dozzle

# alpine
alpine:3.8
alpine:3.8 [arm64]

# nginx
nginx
nginx:alpine3.20
nginx:1.18-alpine
nginx:1.18-alpine [arm64]
nginx:1.26-alpine
nginx:1.26-alpine [arm64]
nginx:1.27.1
nginx:1.28-alpine
nginx:1.28-alpine [arm64]
nginx:1.30.2-alpine
nginx:1.30.2-alpine [arm64]


# node
node:14.20
node:14.20 [arm64]
node:22-slim
node:22-slim [arm64]
node:20-alpine
node:20-bullseye
node:20-bullseye-slim
node:22.15-alpine3.20
node:22.15-alpine3.20 [arm64]
node:26.5-alpine3.24
node:26.5-alpine3.24 [arm64]

# pgsql
pgvector/pgvector:0.8.6-pg18-trixie pgvector:0.8.6-pg18-trixie
pgvector/pgvector:0.8.6-pg18-trixie pgvector:0.8.6-pg18-trixie [arm64]

# ch
clickhouse:25.12
clickhouse:25.12 [arm64]

# dotnet

## runtime
mcr.microsoft.com/dotnet/runtime:6.0 dotnetruntime:6.0
mcr.microsoft.com/dotnet/runtime:8.0 dotnetruntime:8.0
mcr.microsoft.com/dotnet/runtime:8.0-alpine3.18 dotnetruntime:8.0-alpine3.18
mcr.microsoft.com/dotnet/runtime:9.0 dotnetruntime:9.0
mcr.microsoft.com/dotnet/runtime:9.0-alpine3.22 dotnetruntime:9.0-alpine3.22-arm64v8 [arm64]
mcr.microsoft.com/dotnet/runtime:10.0 dotnetruntime:10.0
mcr.microsoft.com/dotnet/runtime:10.0 dotnetruntime:10.0 [arm64]
mcr.microsoft.com/dotnet/runtime:10.0-alpine3.22 dotnetruntime:10.0-alpine3.22
mcr.microsoft.com/dotnet/runtime:10.0-alpine3.22 dotnetruntime:10.0-alpine3.22 [arm64]


## aspnet
mcr.microsoft.com/dotnet/aspnet:6.0 dotnetaspnet:6.0
mcr.microsoft.com/dotnet/aspnet:6.0 dotnetaspnet:6.0 [arm64]
mcr.microsoft.com/dotnet/aspnet:8.0-alpine3.18 dotnetaspnet:8.0-alpine3.18
mcr.microsoft.com/dotnet/aspnet:8.0 dotnetaspnet:8.0
mcr.microsoft.com/dotnet/aspnet:9.0 dotnetaspnet:9.0
mcr.microsoft.com/dotnet/aspnet:9.0-alpine3.20 dotnetaspnet:9.0-alpine3.20
mcr.microsoft.com/dotnet/aspnet:9.0-alpine3.22-arm64v8 dotnetaspnet:9.0-alpine3.22-arm64v8 [arm64]
mcr.microsoft.com/dotnet/aspnet:9.0 dotnetaspnet:9.0
mcr.microsoft.com/dotnet/aspnet:10.0 dotnetaspnet:10.0
mcr.microsoft.com/dotnet/aspnet:10.0-alpine3.22 dotnetaspnet:10.0-alpine3.22
mcr.microsoft.com/dotnet/aspnet:10.0 dotnetaspnet:10.0 [arm64]
mcr.microsoft.com/dotnet/aspnet:10.0-alpine3.22-arm64v8 dotnetaspnet:10.0-alpine3.22-arm64v8 [arm64]


## sdk
mcr.microsoft.com/dotnet/sdk:6.0 dotnetsdk:6.0
mcr.microsoft.com/dotnet/sdk:6.0 dotnetsdk:6.0 [arm64]
mcr.microsoft.com/dotnet/sdk:8.0 dotnetsdk:8.0
mcr.microsoft.com/dotnet/sdk:8.0-alpine3.18 dotnetsdk:8.0-alpine3.18
mcr.microsoft.com/dotnet/sdk:9.0 dotnetsdk:9.0
mcr.microsoft.com/dotnet/sdk:9.0-alpine3.20 dotnetsdk:9.0-alpine3.20
mcr.microsoft.com/dotnet/sdk:9.0-alpine3.22-arm64v8 dotnetsdk:9.0-alpine3.22-arm64v8  [arm64]
mcr.microsoft.com/dotnet/sdk:10.0 dotnetsdk:10.0
mcr.microsoft.com/dotnet/sdk:10.0 dotnetsdk:10.0 [arm64]


# python
python:3.13-slim
python:3.13-slim [arm64]
python:3.14-slim
python:3.14-slim [arm64]


# langfuse
langfuse/langfuse:4.16 langfuse:4.16
langfuse/langfuse:4.16 langfuse:4.16 [arm64]

langfuse/langfuse-worker:4.16 langfuse-worker:4.16
langfuse/langfuse-worker:4.16 langfuse-worker:4.16 [arm64]