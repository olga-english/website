#!/bin/bash

# FTP Upload Script for olga-english.ru
# Uploads all files except this script to the FTP server

# FTP Configuration
FTP_HOST="olga-english.ru"
FTP_USER="u3255936"
FTP_DIR="/www/olga-english.ru/"
SCRIPT_NAME="upload.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting FTP upload to olga-english.ru...${NC}"

# Check if lftp is installed
if ! command -v lftp &> /dev/null; then
    echo -e "${RED}Error: lftp is not installed. Please install it first:${NC}"
    echo "  macOS: brew install lftp"
    echo "  Ubuntu/Debian: sudo apt-get install lftp"
    echo "  CentOS/RHEL: sudo yum install lftp"
    exit 1
fi

# Password cache file
PASSWORD_FILE=".ftp_password"

# Get password (check cache first)
if [ -f "$PASSWORD_FILE" ]; then
    echo -e "${GREEN}Using cached password...${NC}"
    FTP_PASS=$(cat "$PASSWORD_FILE")
else
    echo -n "Enter FTP password for $FTP_USER: "
    read -s FTP_PASS
    echo
    echo "$FTP_PASS" > "$PASSWORD_FILE"
    chmod 600 "$PASSWORD_FILE"
    echo -e "${GREEN}Password cached for future use${NC}"
fi

# Create temporary lftp script
LFTP_SCRIPT=$(mktemp)
cat > "$LFTP_SCRIPT" << EOF
set ftp:ssl-allow no
set ftp:ssl-protect-data no
set ftp:ssl-protect-list no
open ftp://$FTP_USER:$FTP_PASS@$FTP_HOST
cd $FTP_DIR
EOF

# Add upload commands for each file (except this script)
for file in *; do
    if [ -f "$file" ] && [ "$file" != "$SCRIPT_NAME" ]; then
        echo "put $file" >> "$LFTP_SCRIPT"
        echo -e "${GREEN}Added $file to upload queue${NC}"
    fi
done

# Upload images directory if it exists
if [ -d "images" ]; then
    echo -e "${YELLOW}Found images directory, adding to upload queue...${NC}"
    echo "mirror -R images images" >> "$LFTP_SCRIPT"
    echo -e "${GREEN}Added images/ directory to upload queue${NC}"
fi

# Add quit command
echo "quit" >> "$LFTP_SCRIPT"

# Execute lftp script
echo -e "${YELLOW}Uploading files...${NC}"
if lftp -f "$LFTP_SCRIPT"; then
    echo -e "${GREEN}✅ Upload completed successfully!${NC}"
else
    echo -e "${RED}❌ Upload failed!${NC}"
    rm -f "$LFTP_SCRIPT"
    exit 1
fi

# Clean up
rm -f "$LFTP_SCRIPT"

echo -e "${GREEN}All files uploaded to https://olga-english.ru${NC}"
