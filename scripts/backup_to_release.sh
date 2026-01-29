#!/bin/bash
# 备份容器到 GitHub Release
# 功能：压缩 + 加密 + 分卷 + 上传

set -e  # 遇到错误立即退出

# ==================== 加载公共函数 ====================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common_functions.sh"

# ==================== 配置 ====================
ENCRYPTION_KEY="${CONTAINER_ENCRYPTION_KEY}"
SPLIT_SIZE="1900m"  # 每个分卷大小（GitHub Release 限制 2GB）
COMPRESSION_LEVEL="0"  # 压缩级别 0-9，0=不压缩（最快）
SNAPSHOT_PREFIX="snapshot"

# ==================== 检查依赖 ====================
check_dependencies() {
    log_info "检查依赖..."
    
    # 检查 7z
    check_command 7z "sudo apt update > /dev/null 2>&1 && sudo apt install -y p7zip-full > /dev/null 2>&1"
    
    # 检查 gh (GitHub CLI)
    check_command gh "sudo apt update > /dev/null 2>&1 && sudo apt install -y gh > /dev/null 2>&1"
    
    log_success "依赖检查完成"
}

# ==================== 检查加密密码 ====================
check_encryption_key() {
    log_info "检查加密密码..."
    
    if [ -z "$ENCRYPTION_KEY" ]; then
        log_error "未配置加密密码！"
        log_error "请在 GitHub Secrets 中添加 CONTAINER_ENCRYPTION_KEY"
        log_error "路径：Settings → Secrets and variables → Actions → New repository secret"
        exit 1
    fi
    
    log_success "加密密码已配置"
}

# ==================== 检查必需文件 ====================
check_required_files() {
    log_info "检查必需文件..."
    
    if [ ! -f "ark.tar" ]; then
        log_error "未找到 ark.tar 文件"
        exit 1
    fi
    
    if [ ! -f "data.tar" ]; then
        log_error "未找到 data.tar 文件"
        exit 1
    fi
    
    # 显示文件大小
    ARK_SIZE=$(du -h ark.tar | cut -f1)
    DATA_SIZE=$(du -h data.tar | cut -f1)
    log_info "ark.tar: $ARK_SIZE"
    log_info "data.tar: $DATA_SIZE"
    
    log_success "文件检查完成"
}

# ==================== 压缩 + 加密 + 分卷 ====================
compress_and_encrypt() {
    log_info "开始压缩、加密和分卷..."
    
    # 清理旧的分卷文件
    rm -f container.7z.* 2>/dev/null || true
    
    # 使用 7z 进行压缩、加密和分卷
    # -p: 密码
    # -v: 分卷大小
    # -mhe=on: 加密文件头（连文件名都加密）
    # -mx: 压缩级别 (0=不压缩, 9=最大压缩)
    # -mmt: 多线程
    log_info "压缩参数：级别=$COMPRESSION_LEVEL, 分卷大小=$SPLIT_SIZE"
    
    7z a -p"$ENCRYPTION_KEY" \
        -v"$SPLIT_SIZE" \
        -mhe=on \
        -mx="$COMPRESSION_LEVEL" \
        -mmt=on \
        container.7z \
        ark.tar data.tar
    
    # 检查是否生成了分卷文件
    if [ ! -f "container.7z.001" ]; then
        log_error "压缩失败，未生成分卷文件"
        exit 1
    fi
    
    # 统计分卷数量和总大小
    PART_COUNT=$(ls container.7z.* 2>/dev/null | wc -l)
    TOTAL_SIZE=$(du -ch container.7z.* | tail -1 | cut -f1)
    
    log_success "压缩完成：生成 $PART_COUNT 个分卷，总大小 $TOTAL_SIZE"
    
    # 列出所有分卷
    log_info "分卷列表："
    ls -lh container.7z.* | awk '{print "  - " $9 " (" $5 ")"}'
}

# ==================== 生成 Release 标签 ====================
generate_release_tag() {
    # 格式：snapshot-YYYYMMDD-HHMM
    RELEASE_TAG="${SNAPSHOT_PREFIX}-$(date -u +%Y%m%d-%H%M)"
    echo "$RELEASE_TAG"
}

# ==================== 上传到 GitHub Release ====================
upload_to_release() {
    log_info "准备上传到 GitHub Release..."
    
    RELEASE_TAG=$(generate_release_tag)
    log_info "Release 标签：$RELEASE_TAG"
    
    # 检查 Release 是否已存在
    if gh release view "$RELEASE_TAG" &>/dev/null; then
        log_warning "Release $RELEASE_TAG 已存在，将删除后重新创建"
        gh release delete "$RELEASE_TAG" -y
    fi
    
    # 创建 Release 并上传文件
    log_info "创建 Release 并上传文件..."
    gh release create "$RELEASE_TAG" \
        container.7z.* \
        --title "Container Snapshot $(date -u +%Y-%m-%d\ %H:%M) UTC" \
        --notes "Automated container backup
        
📦 Files: $(ls container.7z.* | wc -l) parts
💾 Total size: $(du -ch container.7z.* | tail -1 | cut -f1)
🔒 Encrypted: Yes
⏰ Created: $(date -u +%Y-%m-%d\ %H:%M:%S) UTC"
    
    log_success "上传完成：$RELEASE_TAG"
}

# ==================== 清理临时文件 ====================
cleanup_temp_files() {
    log_info "清理临时文件..."
    
    rm -f container.7z.* 2>/dev/null || true
    
    log_success "清理完成"
}

# ==================== 清理旧版本 ====================
cleanup_old_releases() {
    log_info "清理旧版本（保留最近 2 个）..."
    
    # 使用公共函数获取所有 Release
    set +e
    RELEASES=$(list_snapshot_releases "$SNAPSHOT_PREFIX" false)
    local exit_code=$?
    set -e
    
    if [ $exit_code -ne 0 ]; then
        log_info "没有需要清理的 Release"
        return
    fi
    
    TOTAL_COUNT=$(echo "$RELEASES" | wc -l)
    KEEP_COUNT=2
    
    log_info "找到 $TOTAL_COUNT 个 snapshot Release"
    
    # 如果总数小于等于保留数量，不需要清理
    if [ "$TOTAL_COUNT" -le "$KEEP_COUNT" ]; then
        log_info "当前只有 $TOTAL_COUNT 个 Release，无需清理"
        return
    fi
    
    # 计算需要删除的数量
    DELETE_COUNT=$((TOTAL_COUNT - KEEP_COUNT))
    log_warning "将删除 $DELETE_COUNT 个旧版本"
    
    # 获取需要删除的旧版本（跳过最新的 KEEP_COUNT 个）
    OLD_RELEASES=$(echo "$RELEASES" | tail -n +"$((KEEP_COUNT + 1))")
    
    # 删除旧版本
    echo "$OLD_RELEASES" | while read -r tag; do
        [ -n "$tag" ] && {
            log_info "删除旧版本：$tag"
            gh release delete "$tag" -y --cleanup-tag
        }
    done
    
    log_success "旧版本清理完成"
}

# ==================== 主函数 ====================
main() {
    echo ""
    log_info "=========================================="
    log_info "  备份容器到 GitHub Release"
    log_info "=========================================="
    echo ""
    
    # 1. 检查依赖
    check_dependencies
    
    # 2. 检查加密密码
    check_encryption_key
    
    # 3. 检查必需文件
    check_required_files
    
    # 4. 压缩 + 加密 + 分卷
    compress_and_encrypt
    
    # 5. 上传到 Release
    upload_to_release
    
    # 6. 清理临时文件
    cleanup_temp_files
    
    # 7. 清理旧版本
    cleanup_old_releases
    
    echo ""
    log_success "=========================================="
    log_success "  备份完成！"
    log_success "=========================================="
    echo ""
}

# 执行主函数
main
