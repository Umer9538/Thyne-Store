# Thyne Jewels - Server API Configuration Guide

This guide explains how to add or update API keys on your production server.

---

## Server Details

- **Server IP:** `13.203.247.178`
- **SSH Key File:** `thyne-jewels-key.pem`
- **Username:** `ec2-user`
- **Config File Location:** `/home/ec2-user/thyne-jewels/backend/.env`

---

## Step 1: Connect to Server

### On Mac/Linux:
Open Terminal and run:
```bash
ssh -i /path/to/thyne-jewels-key.pem ec2-user@13.203.247.178
```

### On Windows:
Use PuTTY or Windows Terminal:
```bash
ssh -i C:\path\to\thyne-jewels-key.pem ec2-user@13.203.247.178
```

> **Note:** Replace `/path/to/` with the actual location of your `.pem` key file.

---

## Step 2: Edit Configuration File

Once connected, run:
```bash
nano /home/ec2-user/thyne-jewels/backend/.env
```

This opens the configuration file in a text editor.

---

## Step 3: Add/Update API Keys

Find or add the relevant section and update the values:

### Mtalkz SMS/WhatsApp (for OTP)
```env
MTALKZ_API_KEY=your_mtalkz_api_key
MTALKZ_BASE_URL=https://api.mtalkz.com
MTALKZ_SENDER_ID=THYNEJ
```

### Cashfree Payments
```env
CASHFREE_APP_ID=your_cashfree_app_id
CASHFREE_SECRET_KEY=your_cashfree_secret_key
CASHFREE_ENVIRONMENT=PRODUCTION
```

### AWS S3 (Image Storage)
```env
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_REGION=ap-south-1
AWS_S3_BUCKET=thyne-jewels-images
```

### Email/SMTP
```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_app_password
SMTP_FROM_NAME=Thyne Jewels
```

### AI Services (Optional)
```env
GEMINI_API_KEY=your_gemini_api_key
OPENAI_API_KEY=your_openai_api_key
```

---

## Step 4: Save the File

After editing:
1. Press `Ctrl + X` to exit
2. Press `Y` to confirm save
3. Press `Enter` to confirm filename

---

## Step 5: Restart the Server

Run this command to apply changes:
```bash
sudo systemctl restart thyne-jewels.service
```

---

## Step 6: Verify Server is Running

Check server status:
```bash
sudo systemctl status thyne-jewels.service
```

You should see `Active: active (running)` in green.

---

## Quick Reference Commands

| Action | Command |
|--------|---------|
| Connect to server | `ssh -i thyne-jewels-key.pem ec2-user@13.203.247.178` |
| Edit config | `nano /home/ec2-user/thyne-jewels/backend/.env` |
| Restart server | `sudo systemctl restart thyne-jewels.service` |
| Check server status | `sudo systemctl status thyne-jewels.service` |
| View server logs | `sudo journalctl -u thyne-jewels.service -f` |
| Exit server | `exit` |

---

## Where to Get API Keys

### Mtalkz (SMS/WhatsApp OTP)
1. Go to [developers.mtalkz.com](https://developers.mtalkz.com)
2. Login to your account
3. Navigate to API Settings
4. Copy your API Key

### Cashfree (Payments)
1. Go to [merchant.cashfree.com](https://merchant.cashfree.com)
2. Login to your account
3. Go to Developers > API Keys
4. Copy App ID and Secret Key

### AWS S3 (Image Storage)
1. Go to [console.aws.amazon.com](https://console.aws.amazon.com)
2. Navigate to IAM > Users
3. Create or select a user with S3 access
4. Generate Access Keys

---

## Troubleshooting

### Server won't start after changes
Check for syntax errors in .env file:
```bash
cat /home/ec2-user/thyne-jewels/backend/.env
```
Make sure each line is in format: `KEY=value` (no spaces around `=`)

### Permission denied when connecting
Make sure your .pem file has correct permissions:
```bash
chmod 400 /path/to/thyne-jewels-key.pem
```

### View error logs
```bash
sudo journalctl -u thyne-jewels.service --since "5 minutes ago"
```

---

## Need Help?

If you encounter issues, contact your development team with:
1. The error message you see
2. Which API you were trying to configure
3. The output of: `sudo journalctl -u thyne-jewels.service --since "5 minutes ago"`

---

*Last Updated: December 2024*
