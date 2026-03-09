#!/bin/bash

# Docker 镜像同步脚本
# 将国外镜像转存到阿里云私有仓库

ALIYUN_REGISTRY="${1}"
ALIYUN_NAME_SPACE="${2}"
ALIYUN_REGISTRY_USER="${3}"
ALIYUN_REGISTRY_PASSWORD="${4}"
IMAGES_FILE="${5:-images.txt}"

# 智能同步开关：true=启用智能检查（跳过已存在的镜像），false=全量同步（所有镜像都重新拉取）
SMART_SYNC="${SMART_SYNC:-true}"

echo "=============================================================================="
echo "Docker 镜像同步开始"
echo "=============================================================================="
echo "阿里云仓库：$ALIYUN_REGISTRY"
echo "命名空间：$ALIYUN_NAME_SPACE"
if [ "$SMART_SYNC" = "true" ]; then
    echo "同步模式：智能同步（跳过已存在的镜像）"
else
    echo "同步模式：全量同步（所有镜像都重新拉取）"
fi
echo "=============================================================================="

# 登录阿里云
docker login -u "$ALIYUN_REGISTRY_USER" -p "$ALIYUN_REGISTRY_PASSWORD" "$ALIYUN_REGISTRY"

# 重试函数
retry_command() {
    local max_retries=3
    local retry_count=0
    local delay=5
    local cmd="$1"
    local description="$2"

    while [ $retry_count -lt $max_retries ]; do
        if eval "$cmd"; then
            return 0
        fi
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            echo "[重试 $retry_count/$max_retries] $description 失败，${delay}秒后重试..."
            sleep $delay
        fi
    done
    echo "[失败] $description 在 $max_retries 次重试后仍然失败"
    return 1
}

# 统计信息
total=0
success=0
failed=0

# 失败镜像列表文件
FAILED_IMAGES_FILE="failed-images.txt"
> "$FAILED_IMAGES_FILE"  # 清空失败列表

while IFS= read -r line || [ -n "$line" ]; do
    # 忽略空行与注释
    [[ -z "$line" ]] && continue
    if echo "$line" | grep -q '^\s*#'; then
        continue
    fi

    total=$((total + 1))

    # 解析格式：origin_name [new_name] [platform]
    # 规则：只有用中括号 [] 包裹的才是架构
    # 1 个字段：原始名字
    # 2 个字段：原始名字 + (new_name 或 platform)
    #         - 如果第二个字段是 [...] 格式，则是 platform
    #         - 否则是 new_name
    # 3 个字段：原始名字 new_name platform

    field_count=$(echo "$line" | awk '{print NF}')

    platform=""
    new_name=""

    if [ "$field_count" -eq 1 ]; then
        origin_image=$(echo "$line" | awk '{print $1}')
    elif [ "$field_count" -eq 2 ]; then
        field2=$(echo "$line" | awk '{print $2}')
        # 判断第二个字段是否是中括号格式 [...]，是则为 platform
        if echo "$field2" | grep -qE '^\[.*\]$'; then
            # 是 platform (如 [arm64])
            # 验证中括号内不为空
            arch_content=$(echo "$field2" | tr -d '[]')
            if [ -n "$arch_content" ]; then
                origin_image=$(echo "$line" | awk '{print $1}')
                platform="$field2"
            else
                # 中括号为空，当作 new_name 处理
                origin_image=$(echo "$line" | awk '{print $1}')
                new_name="$field2"
            fi
        else
            # 是 new_name
            origin_image=$(echo "$line" | awk '{print $1}')
            new_name="$field2"
        fi
    else
        # 3 个字段：原始名字 new_name platform
        origin_image=$(echo "$line" | awk '{print $1}')
        new_name=$(echo "$line" | awk '{print $2}')
        platform=$(echo "$line" | awk '{print $3}')
        # 验证 platform 格式
        if [ -n "$platform" ]; then
            arch_content=$(echo "$platform" | tr -d '[]')
            if [ -z "$arch_content" ]; then
                # platform 中括号为空，清除 platform 变量
                platform=""
            fi
        fi
    fi

    echo ""
    echo "=============================================================================="
    echo "[$total] 处理镜像：$origin_image"
    echo "=============================================================================="

    # 获取镜像标签
    image_tag=$(echo "$origin_image" | awk -F':' '{if (NF>1) print $NF; else print "latest"}')

    # 生成新名字
    if [ -n "$new_name" ]; then
        # 用户自定义了新名字，直接使用 new_name
        final_name="$new_name"
        name_source="自定义"
    else
        # 自动生成名字：取原始镜像最后一段，去掉 / 符号
        image_name_tag=$(echo "$origin_image" | awk -F'/' '{print $NF}')
        # 删除@sha256 等字符
        image_name_tag="${image_name_tag%%@*}"
        final_name=$(echo "$image_name_tag" | tr -d '/')
        name_source="自动生成"
    fi

    # 处理架构
    arch_display="x86_64"
    if [ -n "$platform" ]; then
        # 从中括号中提取架构，例如 [arm64] -> arm64
        arch_suffix=$(echo "$platform" | tr -d '[]')
        if [ -n "$arch_suffix" ]; then
            # 只有自动生成的名字才添加架构后缀
            if [ -z "$new_name" ]; then
                final_name="${final_name}-${arch_suffix}"
            fi
            arch_display="$arch_suffix"
        fi
    fi

    # 完整镜像地址
    full_image="$ALIYUN_REGISTRY/$ALIYUN_NAME_SPACE/$final_name"

    echo "原始镜像：$origin_image"
    echo "架构：$arch_display"
    echo "标签：$image_tag"
    echo "名字来源：$name_source"
    echo "完整地址：$full_image"

    # 检查是否指定了版本号（通过判断 origin_image 是否包含 :）
    has_tag=false
    if echo "$origin_image" | grep -q ':'; then
        has_tag=true
    fi

    # 只有指定了版本号的镜像才检查是否存在（latest 标签需要每次拉取最新）
    # 且智能同步开关开启时才进行检查
    if [ "$has_tag" = true ] && [ "$SMART_SYNC" = "true" ]; then
        echo "检查镜像是否已存在..."
        # 使用 docker manifest inspect 只检查元数据，不拉取镜像层，更快更省流量
        if docker manifest inspect $full_image >/dev/null 2>&1; then
            echo "[跳过] 镜像已存在：$full_image"
            success=$((success + 1))
            continue
        fi
        echo "镜像不存在，开始拉取..."
    else
        if [ "$SMART_SYNC" = "false" ]; then
            echo "智能同步已关闭，直接拉取镜像..."
        else
            echo "未指定版本号（latest），每次拉取最新镜像..."
        fi
    fi

    # 拉取镜像
    if [ -z "$platform" ]; then
        pull_cmd="docker pull $origin_image"
    else
        # 提取 platform 中的架构用于 docker pull
        arch_for_pull=$(echo "$platform" | tr -d '[]')
        # 验证提取的架构不为空
        if [ -z "$arch_for_pull" ]; then
            echo "[警告] 无法解析架构参数，使用默认拉取方式"
            pull_cmd="docker pull $origin_image"
        else
            pull_cmd="docker pull --platform linux/$arch_for_pull $origin_image"
        fi
    fi

    echo "执行：$pull_cmd"

    # 执行拉取（带重试）
    if ! retry_command "$pull_cmd" "拉取镜像 $origin_image"; then
        echo "[失败] 拉取镜像失败：$origin_image，跳过此镜像"
        failed=$((failed + 1))
        echo "$origin_image -> $full_image (拉取失败)" >> "$FAILED_IMAGES_FILE"
        continue
    fi

    # 标记镜像（带重试）
    echo "docker tag $origin_image $full_image"
    if ! retry_command "docker tag $origin_image $full_image" "标记镜像"; then
        echo "[失败] 标记镜像失败：$origin_image，跳过此镜像"
        failed=$((failed + 1))
        echo "$origin_image -> $full_image (标记失败)" >> "$FAILED_IMAGES_FILE"
        continue
    fi

    # 推送镜像（带重试）
    echo "docker push $full_image"
    if ! retry_command "docker push $full_image" "推送镜像 $full_image"; then
        echo "[失败] 推送镜像失败：$full_image，跳过此镜像"
        failed=$((failed + 1))
        echo "$origin_image -> $full_image (推送失败)" >> "$FAILED_IMAGES_FILE"
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

# 输出失败镜像列表
if [ $failed -gt 0 ]; then
    echo ""
    echo "=============================================================================="
    echo "失败镜像列表："
    echo "=============================================================================="
    cat "$FAILED_IMAGES_FILE"
    echo "=============================================================================="
    echo "失败镜像已保存到：$FAILED_IMAGES_FILE"
    echo "=============================================================================="
fi

# 始终返回成功，让工作流继续
exit 0
