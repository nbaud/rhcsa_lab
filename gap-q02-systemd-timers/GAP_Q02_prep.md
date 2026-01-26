//////////////////////////////////////////////////////////////////
RHCSA Bonus Gap Q02 Preparation: Systemd Timers
//////////////////////////////////////////////////////////////////

In this preparation step, you must create the scripts and a background timer that will populate files for your lab.

1. Create the script `/usr/local/bin/clean.sh` (this is the script your lab will manage):
```bash
#!/bin/bash
# Simple cleanup script for practice
echo "Cleaning up temporary files..."
rm -rf /tmp/practice_*
echo "Cleanup completed at $(date)" >> /var/log/cleanup_script.log
```

2. Create the script `/usr/local/bin/populate.sh` and make both executable:
```bash
#!/bin/bash
# Automatically create files for cleanup practice
echo "Creating temporary files..."
touch /tmp/practice_{1..5}
echo "Population completed at $(date)" >> /var/log/populate_script.log

chmod +x /usr/local/bin/clean.sh /usr/local/bin/populate.sh
```

3. Create and start a background population timer (so files keep appearing):
```bash
# Service
cat << 'EOF' > /etc/systemd/system/populate.service
[Unit]
Description=Background population for lab practice

[Service]
ExecStart=/usr/local/bin/populate.sh
EOF

# Timer (runs at the top of every minute)
cat << 'EOF' > /etc/systemd/system/populate.timer
[Unit]
Description=Populate files every minute

[Timer]
OnCalendar=*:*:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now populate.timer
```
