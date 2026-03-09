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
├── images.txt                       # 镜像列表配置
├── scripts/
│   └── sync-images.sh              # 镜像同步脚本
└── README.md                        # 使用文档
```

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

打开 `images.txt` 文件，添加你想要的镜像。

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
- 自定义名字：使用第二个字段作为新名字，**不添加架构后缀**
- 自动生成：取原始镜像的最后一段，去掉 `/` 符号
  - `dotnet/aspnet:6.0` → `aspnet:6.0`
  - `docker.io/library/node:20-alpine` → `node:20-alpine`
  - `mcr.microsoft.com/dotnet/sdk:9.0` → `sdk:9.0`
- 架构识别：**只有用 `[]` 包裹的才是架构**
- x86 架构（无 platform 或 `[amd64]`）：不加后缀
- 其他架构：自动生成的名字添加 `-xxx` 后缀，例如 `[arm64]` → `-arm64`

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

在 `images.txt` 中通过指定 `platform` 参数（使用中括号包裹）来拉取不同架构的镜像：

```
# x86 架构（默认，无后缀）
python:3.13-slim                      # -> python:3.13-slim

# arm64 架构（自动生成名字添加 -arm64 后缀）
python:3.13-slim [arm64]              # -> python:3.13-slim-arm64

# 自定义名字 + 架构（自定义名字不添加架构后缀）
node:20-alpine my-node:20 [arm64]     # -> my-node:20
```
![](doc/多架构.png)

### 定时执行
修改 `/.github/workflows/docker.yaml` 文件
添加 schedule 即可定时执行 (此处 cron 使用 UTC 时区)
![](doc/定时执行.png)
