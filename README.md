# Google IPs to AWS WAF Sync

This project automates the synchronization of Google's official IP ranges (Googlebot and Google services) to AWS WAFv2 IP Sets. It uses a pure Shell script implementation with the AWS CLI.

## Prerequisites

*   **AWS CLI v2**: Installed and configured (`aws configure`).
*   **jq**: JSON processor (install via `brew install jq`, `apt install jq`, etc.).
*   **Bash**: Standard shell environment.

## Usage

Run the script directly. It will fetch the latest IPs, create the IP Sets if they don't exist, and update them for **CloudFront (Global) scope**.

```bash
./update_waf.sh
```

### Configuration (Environment Variables)

You can override the AWS region:

| Variable | Default | Description |
| :--- | :--- | :--- |
| `AWS_REGION` | `us-east-1` | The AWS region where your WAF is located. (CloudFront IP Sets are global but still require a region for API calls). |

### Example

```bash
# Update CloudFront IP Sets (default behavior)
./update_waf.sh
```

## How it Works

1.  **Fetch**: Downloads `googlebot.json` and `goog.json` from Google.
2.  **Process**: Extracts IPv4 and IPv6 prefixes using `jq` and deduplicates them.
3.  **Create**: Checks if AWS WAF IP Sets named `GoogleBotIPS-v4` and `GoogleBotIPS-v6` exist. Creates them if missing.
4.  **Update**: Updates the IP Sets with the processed list of addresses.

## Files

*   `update_waf.sh`: The main logic script.
