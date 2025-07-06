# Backup System Installer

Simple installer script for downloading private backup system repositories.

## Usage

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/backup-system-installer/main/get-backup.sh | bash
```

## What it does

1. Prompts for your private repository URL (first time only)
2. Prompts for your GitHub Personal Access Token (first time only)
3. Downloads backup scripts to `~/backup-jobs`
4. Sets executable permissions
5. Saves configuration for future downloads

## Requirements

- GitHub Personal Access Token with `repo` scope
- Private repository containing backup scripts with `setup-backup.sh`

## First Time Setup

The script will prompt you for:
- **Repository URL**: `github.com/username/your-backup-repo.git`
- **GitHub PAT**: Get from [GitHub Settings → Tokens](https://github.com/settings/tokens)

Configuration is saved to `~/.backup-config` for future downloads.

## After Download

```bash
cd ~/backup-jobs
./setup-backup.sh
```