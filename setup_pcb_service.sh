#!/bin/bash

cat << "EOF"

██████╗  ██████╗██████╗     ██╗   ██╗ ██╗    ██████╗ 
██╔══██╗██╔════╝██╔══██╗    ██║   ██║███║   ██╔═████╗
██████╔╝██║     ██████╔╝    ██║   ██║╚██║   ██║██╔██║
██╔═══╝ ██║     ██╔══██╗    ╚██╗ ██╔╝ ██║   ████╔╝██║
██║     ╚██████╗██████╔╝     ╚████╔╝  ██║██╗╚██████╔╝
╚═╝      ╚═════╝╚═════╝       ╚═══╝   ╚═╝╚═╝ ╚═════╝ 

EOF

echo -e "\033[1mProxmox Config Backup v1.0\033[0m"
echo -e "\033[1mPrivia Security\033[0m"

read -p "SMTP Server: " SMTP_SERVER
read -p "SMTP Port: " SMTP_PORT
read -p "SMTP User: " SMTP_USER
read -s -p "SMTP Password: " SMTP_PASS
echo ""
read -p "Sender Address: " EMAIL_FROM
read -p "TO: " EMAIL_TO

echo $SMTP_PASS > /usr/local/bin/pcb_smtp.bin
chmod 600 /usr/local/bin/pcb_smtp.bin

HOSTNAME=$(hostname)

cat << EOF > /usr/local/bin/send_pve_files.py
import os
import smtplib
import ssl
import tarfile
import datetime
import traceback
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders

# SMTP Config
SMTP_SERVER = '$SMTP_SERVER'
SMTP_PORT = $SMTP_PORT
SMTP_USER = '$SMTP_USER'
EMAIL_FROM = '$EMAIL_FROM'
EMAIL_TO = '$EMAIL_TO'
EMAIL_SUBJECT = '${HOSTNAME}-Proxmox-Config-Backup'

LOG_DIR = '/var/log/pcb/'
if not os.path.exists(LOG_DIR):
    os.makedirs(LOG_DIR)
LOG_FILE = os.path.join(LOG_DIR, 'pcb.log')

def log_message(message):
    with open(LOG_FILE, 'a') as log_file:
        log_file.write(f"{datetime.datetime.now()} - {message}\n")

with open('/usr/local/bin/pcb_smtp.bin', 'r') as pass_file:
    SMTP_PASS = pass_file.read().strip()

def send_email(subject, body, attachment_path=None):
    msg = MIMEMultipart()
    msg['From'] = EMAIL_FROM
    msg['To'] = EMAIL_TO
    msg['Subject'] = subject

    msg.attach(MIMEText(body, 'plain'))

    if attachment_path:
        part = MIMEBase('application', 'octet-stream')
        part.set_payload(open(attachment_path, 'rb').read())
        encoders.encode_base64(part)
        part.add_header('Content-Disposition', 'attachment; filename="%s"' % os.path.basename(attachment_path))
        msg.attach(part)

    context = ssl.create_default_context()
    try:
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls(context=context)
            server.login(SMTP_USER, SMTP_PASS)
            server.sendmail(EMAIL_FROM, EMAIL_TO, msg.as_string())
        log_message("Email sent successfully.")
    except Exception as e:
        log_message(f"Failed to send email: {str(e)}")

try:
    backup_dir = '/tmp/proxmox_backup'
    if not os.path.exists(backup_dir):
        os.makedirs(backup_dir)

    timestamp = datetime.datetime.now().strftime('%Y%m%d%H%M%S')
    backup_file = os.path.join(backup_dir, f'{EMAIL_SUBJECT}_backup_{timestamp}.tar.gz')

    with tarfile.open(backup_file, 'w:gz') as tar:
        tar.add('/etc/pve', arcname=os.path.basename('/etc/pve'))
        tar.add('/etc/corosync', arcname=os.path.basename('/etc/corosync'))

    send_email(EMAIL_SUBJECT, 'Attached are the backup files.', backup_file)
    log_message("Backup completed successfully.")
except Exception as e:
    error_message = f"Backup failed: {str(e)}"
    log_message(error_message)
    log_message(traceback.format_exc())
    print(f"\\033[91m✘ {error_message}\\033[0m")
    raise
EOF

cat << EOF > /etc/systemd/system/pcb-backup.service
[Unit]
Description=Proxmox Config Backup Service (PCB)

[Service]
ExecStart=/usr/bin/python3 /usr/local/bin/send_pve_files.py

[Install]
WantedBy=multi-user.target
EOF

cat << EOF > /etc/systemd/system/pcb-backup.timer
[Unit]
Description=Runs Proxmox Config Backup Service every night at 23:59

[Timer]
OnCalendar=*-*-* 23:59:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl start pcb-backup.service
systemctl start pcb-backup.timer

if systemctl enable pcb-backup.service && systemctl enable --now pcb-backup.timer; then
    echo -e "\033[92m✔ Privia Proxmox Config Backup (PCB) v1.0 service setup completed.\033[0m"
else
    echo -e "\033[91m✘ Privia Proxmox Config Backup (PCB) v1.0 service setup failed.\033[0m"
fi
