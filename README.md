# Docker Images Pusher

使用 Github Action 将国外的 Docker 镜像转存到阿里云私有仓库，供国内服务器使用，免费易用<br>
- 支持 DockerHub, gcr.io, k8s.io, ghcr.io 等任意仓库<br>
- 支持最大 40GB 的大型镜像<br>
- 使用阿里云的官方线路，速度快<br>

原作者：**[技术爬爬虾](https://github.com/tech-shrimp/me)**<br>

## 项目结构

```
.
├── .github/workflows/docker.yaml    # GitHub Actions 工作流
├── images.md                        # 镜像列表配置
├── scripts/
│   └── sync-images.sh              # 镜像同步脚本
└── README.md                        # 使用文档
```

## 最近更新

✨ **新增功能优化（2026-03）**

1. **智能路径过滤**：只有修改镜像列表或脚本时才触发同步，避免无效运行
2. **Manifest 检查**：使用 `docker manifest inspect` 替代 `docker pull` 检查，速度提升 5-10 倍
3. **重试机制**：拉取、标记、推送失败时自动重试（最多 3 次），提高成功率
4. **失败记录**：自动记录失败镜像到 `failed-images.txt`，方便排查问题
5. **可视化报告**：GitHub Actions Summary 显示同步报告和失败列表

## 使用方式


### 配置阿里云
登录阿里云容器镜像服务<br>
https://cr.console.aliyun.com/<br>
启用个人实例，创建一个命名空间（**ALIYUN_NAME_SPACE**）
![](/doc/命名空间.png)

访问凭证–>获取环境变量<br>
用户名（**ALIYUN_REGISTRY_USER**)<br>
密码（**ALIYUN_REGISTRY_PASSWORD**)<br>
仓库地址（**ALIYUN_REGISTRY**）<br>

![](doc/用户名密码.png)


### Fork 本项目
Fork 本项目<br>
#### 启动 Action
进入您自己的项目，点击 Action，启用 Github Action 功能<br>
#### 配置环境变量
进入 Settings->Secret and variables->Actions->New Repository secret
![](doc/配置环境变量.png)
将上一步的**四个值**<br>
ALIYUN_NAME_SPACE,ALIYUN_REGISTRY_USER，ALIYUN_REGISTRY_PASSWORD，ALIYUN_REGISTRY<br>
配置成环境变量

### 添加镜像

打开 `images.md` 文件，添加你想要的镜像。

**文件格式：**
```
origin_name [new_name] [platform]
```

| 字段 | 说明 |
|------|------|
| `origin_name` | 原始镜像名称。支持简单名称（如 `nginx`）、带命名空间（如 `dotnet/aspnet`）、绝对地址（如 `docker.io/library/node` 或 `mcr.microsoft.com/dotnet/sdk:9.0`） |
| `new_name` | 可选。自定义新镜像名字（带版本号）。如果省略，则自动取原始镜像的最后一段作为名字 |
| `platform` | 可选。镜像架构平台，**使用中括号包裹**，如 `[arm64]`、`[amd64]`。如果省略，默认为 x86 架构 |

**命名规则：**
- 自定义名字：使用第二个字段作为新名字
- 自动生成：取原始镜像的最后一段，去掉 `/` 符号
  - `dotnet/aspnet:6.0` → `aspnet:6.0`
  - `docker.io/library/node:20-alpine` → `node:20-alpine`
  - `mcr.microsoft.com/dotnet/sdk:9.0` → `sdk:9.0`
- 架构识别：**只有用 `[]` 包裹的才是架构**
- **架构后缀规则**：
  - x86/amd64 架构（无 platform 或 `[amd64]`）：**不加后缀**
  - 其他架构（如 `[arm64]`）：**所有镜像都添加** `-xxx` 后缀
  - 这样可以避免不同架构的镜像互相覆盖

**配置示例：**
```
# 简单名字，自动生成（x86）
nginx                              # -> nginx
dotnet/aspnet:6.0                  # -> aspnet:6.0

# 绝对地址，自动生成（x86）
docker.io/library/node:20-alpine   # -> node:20-alpine
mcr.microsoft.com/dotnet/sdk:9.0   # -> sdk:9.0

# 自定义名字（x86）
node:20-alpine my-node:20          # -> my-node:20

# 自动生成 + 架构
python:3.13-slim [arm64]         # -> python:3.13-slim-arm64

# 自定义名字 + 架构（自定义名字不加架构后缀）
node:20-alpine my-node:20 [arm64]  # -> my-node:20
```

**说明：**
- 可以加 tag，也可以不用 (默认 latest)<br>
- 可使用 `#` 开头作为注释<br>
- 文件提交后，自动进入 Github Action 构建
- 如果某个镜像拉取失败，会自动跳过并继续处理下一个镜像

![](doc/images.png)

### 输出日志

每个镜像处理时会输出完整信息：
```
==============================================================================
[1] 处理镜像：python:3.13-slim [arm64]
==============================================================================
原始镜像：python:3.13-slim
架构：arm64
标签：3.13-slim
名字来源：自动生成
完整地址：registry.cn-hangzhou.aliyuncs.com/my-namespace/python:3.13-slim-arm64
```

### 智能同步策略

脚本支持两种同步模式，通过环境变量 `SMART_SYNC` 控制：

**🧠 智能同步模式（默认启用）**
- 环境变量：`SMART_SYNC=true`
- 指定版本号的镜像（如 `nginx:1.24`、`python:3.13-slim`）：
  - ✅ 使用 `docker manifest inspect` 检查阿里云是否已存在
  - ✅ 只检查元数据，不拉取镜像层，更快更省流量
  - ✅ 存在则跳过，输出 `[跳过] 镜像已存在`
  - ✅ 不存在则正常拉取并推送
- 未指定版本号的镜像（如 `nginx`，默认 latest）：
  - ⏭️ 每次都拉取最新镜像，不检查是否存在
  - ⏭️ 确保 latest 标签始终同步到最新版本

**🔄 全量同步模式**
- 环境变量：`SMART_SYNC=false`
- 所有镜像都重新拉取并推送，不检查是否存在
- 适用于需要强制更新所有镜像的场景

**控制方式：**
1. **自动触发（Push）**：默认启用智能同步
2. **手动触发**：在 GitHub Actions 界面选择是否启用智能同步

**输出示例：**
```
[1] 处理镜像：python:3.13-slim
检查镜像是否已存在...
[跳过] 镜像已存在：registry.cn-hangzhou.aliyuncs.com/my-namespace/python:3.13-slim-arm64

[2] 处理镜像：nginx
未指定版本号（latest），每次拉取最新镜像...
执行：docker pull nginx
[重试 1/3] 拉取镜像 nginx 失败，5秒后重试...
```

**失败镜像记录：**
- 所有失败的镜像会自动记录到 `failed-images.txt` 文件
- 同步完成后会输出失败列表，方便排查问题
- 支持 GitHub Actions Summary 可视化报告

这种策略既节省了固定版本镜像的重复拉取时间，又确保了 latest 标签的时效性，同时通过重试机制提高了成功率。

### 使用镜像
回到阿里云，镜像仓库，点击任意镜像，可查看镜像状态。(可以改成公开，拉取镜像免登录)
![](doc/开始使用.png)

在国内服务器 pull 镜像，例如：<br>
```
docker pull registry.cn-hangzhou.aliyuncs.com/shrimp-images/alpine

docker pull registry.cn-hangzhou.aliyuncs.com/zrng/nginx:[镜像版本号]
```
registry.cn-hangzhou.aliyuncs.com 即 ALIYUN_REGISTRY(阿里云仓库地址)<br>
shrimp-images 即 ALIYUN_NAME_SPACE(阿里云命名空间)<br>
alpine 即 阿里云中显示的镜像名<br>

### 多架构

在 `images.md` 中通过指定 `platform` 参数（使用中括号包裹）来拉取不同架构的镜像：

```
# x86 架构（默认，无后缀）
python:3.13-slim                      # -> python:3.13-slim

# arm64 架构（自动生成名字添加 -arm64 后缀）
python:3.13-slim [arm64]              # -> python:3.13-slim-arm64

# 自定义名字 + 架构（添加架构后缀，避免不同架构镜像覆盖）
node:20-alpine my-node:20 [arm64]     # -> my-node:20-arm64
```
![](doc/多架构.png)

### 工作流触发方式

**自动触发：**
- 修改 `images.md` 文件并推送到 `main` 分支
- 修改 `.github/workflows/docker.yaml` 工作流文件
- 修改 `scripts/sync-images.sh` 脚本文件

> 💡 **提示**：修改 README.md 等 markdown 文档不会触发同步，避免不必要的运行

**手动触发：**
1. 进入 GitHub 仓库的 Actions 页面
2. 选择 "Docker" 工作流
3. 点击 "Run workflow" 按钮
4. 选择分支
5. 选择同步模式：
   - `true`：智能同步（跳过已存在的镜像，推荐）
   - `false`：全量同步（所有镜像都重新拉取）
6. 点击运行

**执行报告：**
- 每次运行后会生成 GitHub Actions Summary 报告
- 报告包含：执行信息、失败镜像列表（如有）、使用提示
- 可在 Actions 运行页面直接查看可视化报告

### 定时执行
修改 `/.github/workflows/docker.yaml` 文件
添加 schedule 即可定时执行 (此处 cron 使用 UTC 时区)
![](doc/定时执行.png)
