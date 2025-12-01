#!/bin/bash

# --- Configuration ---
# Set these variables or export them before running
AWS_REGION="${AWS_REGION:-us-east-1}"
SCOPE="CLOUDFRONT" # Hardcode to CLOUDFRONT as requested

# For CloudFront scope, the region MUST be us-east-1
if [ "$SCOPE" == "CLOUDFRONT" ]; then
    AWS_REGION="us-east-1"
fi

# Names for the IP Sets we will create/update
IPV4_SET_NAME="CloudflareManagedIPS-v4"
IPV6_SET_NAME="CloudflareManagedIPS-v6"

# Temporary files
TMP_V4="cloudflare_v4.txt"
TMP_V6="cloudflare_v6.txt"

# --- Functions ---

log() {
    echo "[$(date +'%T')] $1"
}

error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

# Check dependencies
command -v jq >/dev/null 2>&1 || error_exit "jq is required but not installed."
command -v aws >/dev/null 2>&1 || error_exit "aws cli is required but not installed."

# 1. Fetch IPs
log "Fetching Cloudflare IPs..."

# Cloudflare publishes raw text lists, so we can download them directly
curl -s "https://www.cloudflare.com/ips-v4" > "$TMP_V4"
curl -s "https://www.cloudflare.com/ips-v6" > "$TMP_V6"

# Validate that we actually got content
if [ ! -s "$TMP_V4" ] || [ ! -s "$TMP_V6" ]; then
    error_exit "Failed to download IP lists or lists are empty."
fi

V4_COUNT=$(wc -l < "$TMP_V4" | tr -d ' ')
V6_COUNT=$(wc -l < "$TMP_V6" | tr -d ' ')

log "Found $V4_COUNT IPv4 prefixes and $V6_COUNT IPv6 prefixes."

# 2. Get or Create IP Sets
# Function to get ID by name, or create if missing
get_or_create_ipset() {
    local NAME=$1
    local VERSION=$2 # IPV4 or IPV6
    local ID=""

    # Check if exists
    ID=$(aws wafv2 list-ip-sets --scope "$SCOPE" --region "$AWS_REGION" \
        --query "IPSets[?Name=='$NAME'].Id" --output text)

    if [ "$ID" == "None" ] || [ -z "$ID" ]; then
        log "Creating IP Set: $NAME ($VERSION)..." >&2
        ID=$(aws wafv2 create-ip-set \
            --name "$NAME" \
            --scope "$SCOPE" \
            --ip-address-version "$VERSION" \
            --addresses "[]" \
            --region "$AWS_REGION" \
            --query "Summary.Id" --output text)
        log "Created $NAME with ID: $ID" >&2
    else
        log "Found existing IP Set $NAME with ID: $ID" >&2
    fi
    echo "$ID"
}

V4_SET_ID=$(get_or_create_ipset "$IPV4_SET_NAME" "IPV4")
V6_SET_ID=$(get_or_create_ipset "$IPV6_SET_NAME" "IPV6")

# 3. Update IP Sets
update_ipset() {
    local NAME=$1
    local ID=$2
    local FILE=$3
    
    log "Updating $NAME ($ID)..."

    # Get LockToken
    local TOKEN=$(aws wafv2 get-ip-set \
        --name "$NAME" \
        --scope "$SCOPE" \
        --id "$ID" \
        --region "$AWS_REGION" \
        --query "LockToken" --output text)

    # Read file into JSON array format for CLI
    # We use jq to read the file of lines and turn it into a JSON array
    local ADDRESSES=$(jq -R -s 'split("\n")[:-1]' < "$FILE")

    # Update
    aws wafv2 update-ip-set \
        --name "$NAME" \
        --scope "$SCOPE" \
        --id "$ID" \
        --addresses "$ADDRESSES" \
        --lock-token "$TOKEN" \
        --region "$AWS_REGION" > /dev/null

    log "Successfully updated $NAME"
}

update_ipset "$IPV4_SET_NAME" "$V4_SET_ID" "$TMP_V4"
update_ipset "$IPV6_SET_NAME" "$V6_SET_ID" "$TMP_V6"

# Cleanup
rm "$TMP_V4" "$TMP_V6" 2>/dev/null

log "Done."
