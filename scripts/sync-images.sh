#!/bin/bash

# Docker 镜像同步脚本
# 将国外镜像转存到阿里云私有仓库

ALIYUN_REGISTRY="${1}"
ALIYUN_NAME_SPACE="${2}"
ALIYUN_REGISTRY_USER="${3}"
ALIYUN_REGISTRY_PASSWORD="${4}"
IMAGES_FILE="${5:-images.txt}"

echo "=============================================================================="
echo "Docker 镜像同步开始"
echo "=============================================================================="
echo "阿里云仓库：$ALIYUN_REGISTRY"
echo "命名空间：$ALIYUN_NAME_SPACE"
echo "=============================================================================="

# 登录阿里云
docker login -u "$ALIYUN_REGISTRY_USER" -p "$ALIYUN_REGISTRY_PASSWORD" "$ALIYUN_REGISTRY"

# 统计信息
total=0
success=0
failed=0

while IFS= read -r line || [ -n "$line" ]; do
    # 忽略空行与注释
    [[ -z "$line" ]] && continue
    if echo "$line" | grep -q '^\s*#'; then
        continue
    fi

    total=$((total + 1))

    # 解析格式：origin_name [platform]
    field_count=$(echo "$line" | awk '{print NF}')

    if [ "$field_count" -eq 1 ]; then
        origin_image=$(echo "$line" | awk '{print $1}')
        platform=""
    else
        origin_image=$(echo "$line" | awk '{print $1}')
        platform=$(echo "$line" | awk '{print $2}')
    fi

    echo ""
    echo "=============================================================================="
    echo "[$total] 处理镜像：$origin_image"
    echo "=============================================================================="

    # 获取镜像标签
    image_tag=$(echo "$origin_image" | awk -F':' '{if (NF>1) print $NF; else print "latest"}')

    # 获取镜像名（不带路径）
    image_name_tag=$(echo "$origin_image" | awk -F'/' '{print $NF}')
    # 删除@sha256 等字符
    image_name_tag="${image_name_tag%%@*}"

    # 生成基础名字：去掉 / 符号
    base_name=$(echo "$image_name_tag" | tr -d '/')

    # 根据平台添加后缀
    if [ -z "$platform" ] || [ "$platform" = "linux/amd64" ]; then
        new_name="$base_name"
        arch_display="x86_64"
    else
        # 提取架构后缀，例如 linux/arm64 -> arm64
        arch_suffix=$(echo "$platform" | sed 's/linux\///' | tr -d '/')
        new_name="${base_name}-${arch_suffix}"
        arch_display="$arch_suffix"
    fi

    # 完整镜像地址
    full_image="$ALIYUN_REGISTRY/$ALIYUN_NAME_SPACE/$new_name"

    echo "原始镜像：$origin_image"
    echo "架构：$arch_display"
    echo "标签：$image_tag"
    echo "完整地址：$full_image"

    # 拉取镜像
    if [ -z "$platform" ]; then
        pull_cmd="docker pull $origin_image"
    else
        pull_cmd="docker pull --platform $platform $origin_image"
    fi

    echo "执行：$pull_cmd"

    # 执行拉取，如果失败则跳过此镜像
    if ! $pull_cmd; then
        echo "[失败] 拉取镜像失败：$origin_image，跳过此镜像"
        failed=$((failed + 1))
        continue
    fi

    # 标记镜像
    echo "docker tag $origin_image $full_image"
    if ! docker tag $origin_image $full_image; then
        echo "[失败] 标记镜像失败：$origin_image，跳过此镜像"
        failed=$((failed + 1))
        continue
    fi

    # 推送镜像
    echo "docker push $full_image"
    if ! docker push $full_image; then
        echo "[失败] 推送镜像失败：$full_image，跳过此镜像"
        failed=$((failed + 1))
        continue
    fi

    echo "[成功] 推送成功：$full_image"
    success=$((success + 1))

    # 清理磁盘空间
    echo "清理磁盘空间..."
    docker rmi $origin_image 2>/dev/null || true
    docker rmi $full_image 2>/dev/null || true

done < "$IMAGES_FILE"

echo ""
echo "=============================================================================="
echo "镜像同步完成"
echo "总数：$total | 成功：$success | 失败：$failed"
echo "=============================================================================="

# 始终返回成功，让工作流继续
exit 0
