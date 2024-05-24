# Proxmox Config Backup-PCB v1.0

## Description

Privia Security, Proxmox Config Backup-PCB v1.0 is a script designed to back up the configuration files from the `/etc/pve/` and `/etc/corosync/` directories on a Proxmox server and send these backups as an email via a specified SMTP server. The service is configured to run every night at 23:59. It logs the success or failure of email sending to the `/var/log/pcb/` directory.

## Installation

1. `wget https://raw.githubusercontent.com/mindspoof/PCB/main/setup_pcb_service.sh -O /tmp/setup_pcb_service.sh`
2. Make the `chmod +x  /tmp/setup_pcb_service.sh` file executable:
3. sudo `./tmp/setup.sh`
4. When the script runs, it will prompt you for the following information:
   + `SMTP Server`
   + `SMTP Port`
   + `SMTP User`
   + `SMTP Password (hidden input)`
   + `Sender Address`
   + `Recipient Address (TO)`
## Usage

After installation, the script will run every night at 23:59, backing up the specified directories and sending the backups as an email. Success and failure logs of the backup and email sending process will be saved in /var/log/pcb/backup.log.

## File Structure
   + setup.sh: The installation and configuration script.
   + send_pve_files.py: The backup script.
   + pcb-backup.service: The systemd service file.
   + pcb-backup.timer: The systemd timer file.

## Service Management
You can manage the service and timer using the following commands:

### Enable the timer:
<code>sudo systemctl enable pcb-backup.timer</code>

### Start the service:
<code>sudo systemctl start pcb-backup.service</code>

### Disable the timer:
<code>sudo systemctl disable pcb-backup.timer</code>

### Log Files
Logs related to the email sending and backup processes will be saved in /var/log/pcb/backup.log. This log file will contain detailed information about errors and successful operations.
