#!/bin/bash

# 定义文件和目录路径
LIST_FILE="/app/list.txt"
DOWNLOAD_DIR="/downloads"
LOG_FILE="/var/log/cron.log" # 与 Dockerfile CMD 中的 tail 对应

echo "----------------------------------------"
echo "运行 yt-dlp 下载脚本于: $(date)"
echo "----------------------------------------"

# 确保存档目录存在
# 使用 mkdir -p，如果目录已存在，则不会报错；如果不存在，则会创建它及其父目录
mkdir -p "$DOWNLOAD_DIR/archives"
if [ $? -ne 0 ]; then
    echo "错误: 无法创建存档目录 $DOWNLOAD_DIR/archives !" >> "$LOG_FILE" 2>&1
    exit 1
fi

# 检查列表文件是否存在
if [ ! -f "$LIST_FILE" ]; then
    echo "错误: 播放列表文件 $LIST_FILE 未找到!"
    exit 1
fi

# 逐行读取列表文件
while IFS= read -r playlist_url || [[ -n "$playlist_url" ]]; do
    # 跳过空行和注释行
    if [[ -z "$playlist_url" || "$playlist_url" =~ ^# ]]; then
        continue
    fi

    echo "正在处理播放列表: $playlist_url"

    # 使用 yt-dlp 下载播放列表
    # 参数说明:
    # -i, --ignore-errors: 遇到下载错误时继续处理播放列表中的其他视频
    # --download-archive FILE: 记录已下载视频的ID，避免重复下载。每个播放列表使用独立的存档文件。
    # -o TEMPLATE: 输出文件名模板。按播放列表名称创建子目录。
    # --format: 选择最佳视频和音频流 (需要 ffmpeg 合并)
    # --add-metadata: 写入元数据到文件
    # --write-thumbnail: 下载视频缩略图
    # --no-overwrites: 不覆盖已存在的文件 (虽然 archive 通常能处理好，但多一层保险)
    # --playlist-items 1-5: (可选) 限制下载数量，用于测试
    yt-dlp \
        -q \
        --download-archive "$DOWNLOAD_DIR/archives/$(basename "$playlist_url" | sed 's/[^a-zA-Z0-9_-]/_/g').txt" \
        -o "$DOWNLOAD_DIR/%(playlist)s/%(title)s.%(ext)s" \
        -x \
        --audio-format mp3 \
        --audio-quality 0 \
        --format 'bestaudio/best' \
        --add-metadata \
        "$playlist_url"

    # 检查 yt-dlp 的退出状态
    if [ $? -ne 0 ]; then
        echo "警告: 处理播放列表 $playlist_url 时发生错误。"
    else
        echo "完成处理播放列表: $playlist_url"
    fi
    echo "--------------------"

done < "$LIST_FILE"

echo "所有播放列表处理完毕: $(date)"
echo "========================================"

# 脚本执行完毕，cron 会继续运行
exit 0
