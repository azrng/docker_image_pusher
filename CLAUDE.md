# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Docker Images Pusher - A GitHub Actions workflow that mirrors Docker images from international registries (DockerHub, gcr.io, k8s.io, ghcr.io) to Alibaba Cloud private registries for domestic access in China.

## Project Structure

```
.
├── .github/workflows/docker.yaml    # Main GitHub Actions workflow
├── images.txt                       # List of Docker images to mirror
└── README.md                        # Usage documentation (Chinese)
```

## Key Components

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

Format: `origin_name [platform]`

| Fields | Description |
|--------|-------------|
| `origin_name` | Source image name. Can be simple name (`nginx`) or with namespace (`dotnet/aspnet`) |
| `platform` | Optional. Platform architecture (e.g., `linux/arm64`, `linux/amd64`). Defaults to x86 if omitted |

**Naming Rules:**
- `/` is automatically removed: `dotnet/aspnet` → `dotnetaspnet`
- x86 architecture (default or `linux/amd64`): no suffix
- Other architectures: add suffix, e.g., `linux/arm64` → `-arm64`

Examples:
```
nginx                              # -> nginx (x86)
dotnet/aspnet:6.0                  # -> dotnetaspnet:6.0 (x86)
python:3.13-slim linux/arm64       # -> python:3.13-slim-arm64 (arm64)
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
