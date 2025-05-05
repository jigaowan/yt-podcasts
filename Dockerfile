# Use a containing Python lightweight Linux distribution as base
FROM python:3.11-slim-bookworm

# Set working directory
WORKDIR /app

# Install necessary dependencies: yt-dlp, ffmpeg, cron, tzdata
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    cron \
    tzdata \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install latest yt-dlp using pip
RUN pip install --no-cache-dir -U yt-dlp

# Create download directory
RUN mkdir /downloads

# Copy scripts and list file
COPY download_playlists.sh .
COPY list.txt .
COPY entrypoint.sh .

# Grant execution permissions
RUN chmod +x download_playlists.sh
RUN chmod +x entrypoint.sh

# RUN crontab /etc/cron.d/yt-dlp-cron
# Create cron log file (moved to entrypoint, but keeping here doesn't hurt)
RUN touch /var/log/cron.log

# Define mount point for persistent downloads
VOLUME /downloads

# Set the entrypoint script
ENTRYPOINT ["/app/entrypoint.sh"]

# Default command: Start cron service in foreground and tail the log
# This command is passed to the entrypoint script via "$@"
CMD ["cron", "&&", "tail", "-f", "/var/log/cron.log"]
