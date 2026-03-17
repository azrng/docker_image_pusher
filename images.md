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


# nginx
nginx
nginx:alpine3.20
nginx:1.27.1
nginx:1.18-alpine
nginx:1.18-alpine [arm64]


# node
node:14.20
node:14.20 [arm64]
node:22-slim
node:20-alpine
node:20-bullseye
node:20-bullseye-slim

# dotnet

## x86
mcr.microsoft.com/dotnet/aspnet:6.0 dotnetaspnet:6.0
mcr.microsoft.com/dotnet/aspnet:10.0 dotnetaspnet:10.0
mcr.microsoft.com/dotnet/sdk:6.0 dotnetsdk:6.0
mcr.microsoft.com/dotnet/sdk:10.0 dotnetsdk:10.0

## arm64
mcr.microsoft.com/dotnet/aspnet:6.0 dotnetaspnet:6.0 [arm64]
mcr.microsoft.com/dotnet/aspnet:10.0 dotnetaspnet:10.0 [arm64]
mcr.microsoft.com/dotnet/sdk:6.0 dotnetsdk:6.0 [arm64]
mcr.microsoft.com/dotnet/sdk:10.0 dotnetsdk:10.0 [arm64]

# python
python:3.13-slim
python:3.13-slim [arm64]
