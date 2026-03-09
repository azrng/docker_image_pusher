# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Docker Images Pusher - A GitHub Actions workflow that mirrors Docker images from international registries (DockerHub, gcr.io, k8s.io, ghcr.io) to Alibaba Cloud private registries for domestic access in China.

## Project Structure

```
.
├── .github/workflows/docker.yaml    # Main GitHub Actions workflow
├── images.txt                       # List of Docker images to mirror
├── scripts/
│   └── sync-images.sh               # Image sync script
└── README.md                        # Usage documentation (Chinese)
```

## Key Components

### Scripts (`scripts/sync-images.sh`)

Shell script that handles the image synchronization logic:
- Parses `images.txt` format: `origin_name [new_name] [platform]`
- Format detection:
  - 1 field: `origin_name` → auto-generate name
  - 2 fields: if second field contains `[...]`, it's platform; otherwise it's new_name
  - 3 fields: `origin_name new_name platform`
- Naming rules:
  - Custom name: uses second field as new_name (no architecture suffix added)
  - Auto-generate: takes last segment of origin image, removes `/`
  - Architecture suffix `[xxx]` only added to auto-generated names
- Pulls, tags, pushes images
- Outputs full image path and version for each image:
  ```
  [1] 处理镜像：python:3.13-slim [arm64]
  原始镜像：python:3.13-slim
  架构：arm64
  标签：3.13-slim
  名字来源：自动生成
  完整地址：registry.cn-hangzhou.aliyuncs.com/my-namespace/python:3.13-slim-arm64
  ```
- Error handling: skips failed images and continues with next one
- Cleans up disk space after each image
- Always exits with 0 to not fail the workflow

Usage:
```bash
./scripts/sync-images.sh $ALIYUN_REGISTRY $ALIYUN_NAME_SPACE $ALIYUN_REGISTRY_USER $ALIYUN_REGISTRY_PASSWORD
```

### GitHub Actions Workflow (`.github/workflows/docker.yaml`)

The workflow triggers on:
- Push to `main` branch
- Manual dispatch (`workflow_dispatch`)

Required repository secrets:
- `ALIYUN_REGISTRY` - Alibaba Cloud registry URL (e.g., `registry.cn-hangzhou.aliyuncs.com`)
- `ALIYUN_NAME_SPACE` - Alibaba Cloud namespace
- `ALIYUN_REGISTRY_USER` - Registry username
- `ALIYUN_REGISTRY_PASSWORD` - Registry password

Key features:
- Disk space optimization using `easimon/maximize-build-space@master`
- Supports multi-architecture images via `platform` field in images.txt
- Pulls images, retags for Alibaba Cloud, pushes, then cleans up disk space

### Images Configuration (`images.txt`)

Format: `origin_name [new_name] [platform]`

| Fields | Description |
|--------|-------------|
| `origin_name` | Source image name. Supports simple names (`nginx`), namespaced names (`dotnet/aspnet`), or absolute addresses (`docker.io/library/node`, `mcr.microsoft.com/dotnet/sdk:9.0`) |
| `new_name` | Optional. Custom new image name with tag. If omitted, auto-generates from the last segment of origin_image |
| `platform` | Optional. Platform architecture **with brackets**, e.g., `[arm64]`, `[amd64]`. Defaults to x86 if omitted |

**Naming Rules:**
- Custom name: uses second field as new_name (**no architecture suffix added**)
- Auto-generate: takes last segment, removes `/`
  - `dotnet/aspnet:6.0` → `aspnet:6.0`
  - `docker.io/library/node:20-alpine` → `node:20-alpine`
  - `mcr.microsoft.com/dotnet/sdk:9.0` → `sdk:9.0`
- Architecture: **only fields containing `[...]` are recognized as platform**
- x86 architecture (default or `[amd64]`): no suffix
- Other architectures: adds `-xxx` suffix to auto-generated names only
  - `[arm64]` → `-arm64`

Examples:
```
nginx                               # -> nginx (auto, x86)
dotnet/aspnet:6.0                   # -> aspnet:6.0 (auto, x86)
docker.io/library/node:20-alpine    # -> node:20-alpine (auto, x86)
mcr.microsoft.com/dotnet/sdk:9.0    # -> sdk:9.0 (auto, x86)
node:20-alpine my-node:20           # -> my-node:20 (custom, x86)
python:3.13-slim [arm64]            # -> python:3.13-slim-arm64 (auto, arm64)
node:20-alpine my-node:20 [arm64]   # -> my-node:20 (custom, no suffix)
```

## Development Notes

- This is a **configuration-only project** - no application code to build/test
- Changes to `images.txt` on `main` branch trigger automatic image synchronization
- To test workflow changes, push to a branch and create a PR or use manual dispatch
- The workflow runs on `ubuntu-latest` and requires significant disk space (up to 40GB images)

## Common Operations

**Add a new image to mirror:**
Edit `images.txt`, add the image name (with optional tag/platform), commit to main

**Manually trigger sync:**
Use GitHub Actions UI -> "Run workflow" button

**Modify workflow logic:**
Edit `.github/workflows/docker.yaml`, test by pushing to a test branch first
