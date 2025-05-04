# 使用一个包含 Python 的轻量级 Linux 发行版作为基础镜像
FROM python:3.11-slim-bookworm

# 设置工作目录
WORKDIR /app

# 安装必要的依赖: yt-dlp, ffmpeg (用于合并音视频), cron (任务调度)
# tzdata 用于正确设置时区，避免 cron 时间问题
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    cron \
    tzdata \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 使用 pip 安装最新版本的 yt-dlp
RUN pip install --no-cache-dir -U yt-dlp

# 创建下载目录
RUN mkdir /downloads

# 复制脚本和列表文件到容器中
COPY download_playlists.sh .
# COPY list.txt .
COPY yt-dlp-cron /etc/cron.d/yt-dlp-cron

# 赋予脚本执行权限
RUN chmod +x download_playlists.sh

# 赋予 crontab 文件正确的权限和所有权
RUN chmod 0644 /etc/cron.d/yt-dlp-cron && \
    crontab /etc/cron.d/yt-dlp-cron

# 创建 cron 日志文件，以便调试
RUN touch /var/log/cron.log

# 定义挂载点，用于持久化存储下载的文件
VOLUME /downloads

# 容器启动时运行 cron 服务，并在前台运行以保持容器活动
# 同时输出 cron 日志到 stdout/stderr
CMD cron && tail -f /var/log/cron.log
