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
origin_name [platform]
```

| 字段 | 说明 |
|------|------|
| `origin_name` | 原始镜像名称。可以是简单名称（如 `nginx`），也可以带命名空间（如 `dotnet/aspnet`） |
| `platform` | 可选。镜像架构平台，如 `linux/arm64`、`linux/amd64`。如果省略，默认为 x86 架构 |

**命名规则：**
- 自动去掉 `/` 符号，例如 `dotnet/aspnet` → `dotnetaspnet`
- x86 架构（`linux/amd64` 或无平台）：不加后缀
- 其他架构：添加架构后缀，例如 `linux/arm64` → `-arm64`

**配置示例：**
```
# x86 架构（默认）
nginx                        # -> nginx
dotnet/aspnet:6.0            # -> dotnetaspnet:6.0

# arm64 架构
python:3.13-slim linux/arm64 # -> python:3.13-slim-arm64
```

**说明：**
- 可以加 tag，也可以不用 (默认 latest)<br>
- 可使用 `#` 开头作为注释<br>
- 文件提交后，自动进入 Github Action 构建

![](doc/images.png)

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
在 `images.txt` 中通过第二个字段指定 `platform` 参数，会自动在镜像名后添加架构后缀：
```
# x86 架构（默认，无后缀）
python:3.13-slim

# arm64 架构（添加-arm64 后缀）
python:3.13-slim linux/arm64   # -> python:3.13-slim-arm64
```
![](doc/多架构.png)

### 定时执行
修改 `/.github/workflows/docker.yaml` 文件
添加 schedule 即可定时执行 (此处 cron 使用 UTC 时区)
![](doc/定时执行.png)
