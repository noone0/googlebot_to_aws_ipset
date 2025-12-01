# AWS WAF IP Synchronization Scripts

This project provides a collection of Bash scripts to automate the synchronization of official IP address ranges from major service providers (Google, AWS CloudFront, and Cloudflare) into AWS WAFv2 IP Sets. This is particularly useful for managing allowlists or blocklists within an AWS WAF Web ACL associated with CloudFront distributions.

## Prerequisites

### General
*   **AWS CLI v2**: Installed and configured with credentials that have permissions to manage WAFv2 IP Sets (`wafv2:ListIPSets`, `wafv2:CreateIPSet`, `wafv2:GetIPSet`, `wafv2:UpdateIPSet`).
*   **Bash**: Standard shell environment.
*   **curl**: For fetching IP lists.

### Linux (Ubuntu/Debian)
```bash
# Install jq and curl
sudo apt update
sudo apt install jq curl -y

# Install AWS CLI v2 (if not already installed)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### macOS
```bash
# Install jq
brew install jq

# Install AWS CLI v2
brew install awscli
```

## Usage

Run the desired script directly. Each script will fetch the latest IP ranges from its respective provider, create the necessary IP Sets in AWS WAFv2 if they don't already exist, and update them. All IP Sets are created with the `CLOUDFRONT` scope, which requires the `us-east-1` AWS region for API calls.

```bash
# Sync Googlebot and Google services IPs
./update_google_waf.sh

# Sync AWS CloudFront Global and Regional Edge IPs
./update_cloudfront_waf.sh

# Sync Cloudflare IPs
./update_cloudflare_waf.sh
```

### Configuration (Environment Variables)

You can override the AWS region, though `us-east-1` is typically required for CloudFront-scoped WAF resources.

| Variable | Default | Description |
| :--- | :--- | :--- |
| `AWS_REGION` | `us-east-1` | The AWS region where your WAF IP Sets are managed. |

## How it Works (General)

Each script follows a similar pattern:
1.  **Fetch**: Downloads the latest official IPv4 and IPv6 address ranges from the respective provider.
2.  **Process**: Extracts and deduplicates the IP prefixes. For JSON sources, `jq` is used; for plain text, `curl` downloads directly to a file.
3.  **Manage IP Sets**:
    *   Checks for the existence of two AWS WAFv2 IP Sets (one for IPv4 and one for IPv6) specific to the provider.
    *   If an IP Set does not exist, it is created.
    *   The existing or newly created IP Sets are then updated with the latest fetched IP addresses.
    *   Lock tokens are managed automatically for safe updates.
4.  **Cleanup**: Temporary files are removed.

## Scripts Overview

| Script Name | Purpose | IPv4 IP Set Name | IPv6 IP Set Name |
| :---------- | :------ | :--------------- | :--------------- |
| `update_google_waf.sh` | Syncs Googlebot and Google service IP ranges. | `GoogleBotIPS-v4` | `GoogleBotIPS-v6` |
| `update_cloudfront_waf.sh` | Syncs AWS CloudFront Global and Regional Edge IP ranges. | `CloudFrontManagedIPS-v4` | `CloudFrontManagedIPS-v6` |
| `update_cloudflare_waf.sh` | Syncs Cloudflare IP ranges. | `CloudflareManagedIPS-v4` | `CloudflareManagedIPS-v6` |