📌 Preparation:
Before beginning, ensure you have completed the prerequisite steps in `GAP_Q02_prep.md`. This sets up a background timer that creates files in `/tmp` every minute at `:00`.

📌 Question:
A background process is currently populating `/tmp` with practice files at the start of every minute. Your task is to automate their removal.
1. Create a systemd service and timer named `cleanup` that runs the script `/usr/local/bin/clean.sh`.
2. The cleanup should happen exactly 30 seconds after the files are created (i.e., at the 30-second mark of every minute).
3. The timer must be enabled and start automatically on boot.
4. Verify the operation: Files should appear at `:00` and disappear at `:30`.


✅ Solution outline:

1. Create the Service file (`/etc/systemd/system/cleanup.service`):
```ini
[Unit]
Description=Run cleanup script

[Service]
ExecStart=/usr/local/bin/clean.sh
```

2. Create the Timer file (`/etc/systemd/system/cleanup.timer`):
```ini
[Unit]
Description=Run cleanup script 30 seconds after population

[Timer]
OnCalendar=*:*:30
AccuracySec=1s
Persistent=true

[Install]
WantedBy=timers.target
```

3. Enable and Start:
```bash
systemctl daemon-reload
systemctl enable --now cleanup.timer
```

4. Verify:
```bash
systemctl list-timers --all
# Watch the magic happen (files appear at :00, disappear at :30)
watch -n 1 ls /tmp/practice_*
```
