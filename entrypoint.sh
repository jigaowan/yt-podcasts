#!/bin/bash

# Default cron schedule (e.g., daily at 3 AM) if not provided
DEFAULT_CRON_SCHEDULE="0 3 * * *"
CRON_SCHEDULE=${CRON_SCHEDULE:-$DEFAULT_CRON_SCHEDULE} # Use provided or default

# Path to the cron job definition file
CRON_FILE="/etc/cron.d/yt-dlp-cron"

echo "Setting up cron schedule: ${CRON_SCHEDULE}"

# Create the cron file with the specified schedule
# Note: Crontab file needs a newline at the end
echo "PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" >> ${CRON_FILE}
echo "${CRON_SCHEDULE} /app/download_playlists.sh >> /var/log/cron.log 2>&1" >> ${CRON_FILE}
echo "" >> ${CRON_FILE} # Add trailing newline

# Give correct permissions to the cron file
chmod 0644 ${CRON_FILE}
crontab ${CRON_FILE}
# Apply the crontab (optional, placing in cron.d should be enough for most cron implementations)
# crontab ${CRON_FILE} # Uncomment if placing the file in /etc/cron.d doesn't automatically activate it

# Ensure the log file exists so tail doesn't fail
touch /var/log/cron.log

echo "Cron schedule set. Starting cron daemon and tailing log..."

# Execute the command passed to the entrypoint (the original CMD from Dockerfile)
# This will start cron and tail the log file
exec "$@"
