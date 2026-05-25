# RHCSA gap lab 05: SELinux

## Goal

A server is running `vsftpd`.

Anonymous FTP users must be able to:

```text
download from: /srv/company-drop/pub
upload to:   /srv/company-drop/incoming
```

Rules:

```text
SELinux must stay Enforcing.
Do not disable SELinux.
Do not set SELinux to permissive.
Do not use chmod 777.
Do not move the files to /var/ftp.
The solution must survive reboot.
```

---

## 1. First test the requirement with `lftp`

Before fixing anything, reproduce the problem.

Test listing and download:

```bash
lftp -u anonymous,anonymous localhost -e 'ls; ls pub; cat pub/readme.txt; bye'
```

Test upload:

```bash
echo "upload test" > /tmp/upload-test.txt
lftp -u anonymous,anonymous localhost -e 'cd incoming; put /tmp/upload-test.txt; bye'
```

Expected problem:

```text
The upload will probably fail.
You may see errors like:
Access failed
Permission denied
Could not create file
```

Why we do this:

```text
If we do not test first, we do not know what is broken.
A good RHCSA troubleshooting answer starts by reproducing the failure.
```

---

## 2. Check that the FTP service is running

```bash
systemctl status vsftpd --no-pager
```

Look for:

```text
active (running)
```

If it is not running:

```bash
systemctl restart vsftpd
systemctl status vsftpd --no-pager
```

Also check if the service is enabled:

```bash
systemctl is-enabled vsftpd
```

If needed:

```bash
systemctl enable --now vsftpd
```

Why:

```text
If the service is not running, SELinux is not the first problem.
```

---

## 3. Check that FTP is listening on port 21

```bash
ss -tulpen | grep :21
```

Expected: a line showing `vsftpd` listening on TCP port 21.

Example:

```text
LISTEN ... 0.0.0.0:21 ... users:(("vsftpd",pid=1234,fd=3))
```

Why:

```text
If nothing is listening on port 21, clients cannot connect.
That would be a service/configuration problem before it is an SELinux problem.
```

---

## 4. Check the FTP configuration and firewall

Check the important `vsftpd` settings:

```bash
grep -E '^(anon_root|local_root|pasv_min_port|pasv_max_port)' /etc/vsftpd/vsftpd.conf
```

Expected for this lab:

```text
anon_root=/srv/company-drop
pasv_min_port=30000
pasv_max_port=30010
```

This means:

```text
Server path /srv/company-drop appears as / to the anonymous FTP user.
Server path /srv/company-drop/pub appears as /pub.
Server path /srv/company-drop/incoming appears as /incoming.
```

Check the firewall:

```bash
firewall-cmd --list-all
```

Look for:

```text
services: ftp
ports: 30000-30010/tcp
```

If missing, add them persistently:

```bash
firewall-cmd --permanent --add-service=ftp
firewall-cmd --permanent --add-port=30000-30010/tcp
firewall-cmd --reload
```

Why:

```text
FTP uses port 21 for the control connection.
This lab also uses passive ports 30000-30010.
Firewall problems and SELinux problems are separate layers.
```

---

## 5. Check normal Linux permissions

```bash
ls -ld /srv/company-drop
ls -ld /srv/company-drop/pub
ls -ld /srv/company-drop/incoming
```

For this lab, the permissions should allow reading from `pub` and writing to `incoming`.

Typical example:

```text
drwxr-xr-x /srv/company-drop
drwxr-xr-x /srv/company-drop/pub
drwx-wx-wx /srv/company-drop/incoming
```

Why:

```text
If normal Unix permissions are wrong, do not blame SELinux first.
SELinux is an additional layer, not a replacement for chmod/chown.
```

Do not use:

```bash
chmod 777
```

That is not a clean exam fix.

---

## 6. Check SELinux mode

```bash
getenforce
```

Expected:

```text
Enforcing
```

Optional detailed check:

```bash
sestatus
```

Important values:

```text
SELinux status: enabled
Current mode: enforcing
Policy type: targeted
```

Why:

```text
The task says SELinux must stay Enforcing.
Do not use setenforce 0.
Do not edit the system to make SELinux permissive.
```

---

## 7. Check SELinux audit denials (forgot in the video, sorry!)

After the failed `lftp` test, check recent AVC denials:

```bash
ausearch -m AVC -ts recent
```

If there is too much output:

```bash
ausearch -m AVC -ts recent | grep -i ftp
```

You may see something like:

```text
avc: denied { read } for comm="vsftpd" name="readme.txt"
scontext=system_u:system_r:ftpd_t:s0
tcontext=unconfined_u:object_r:var_t:s0
tclass=file
```

How to read it:

```text
comm="vsftpd" means the FTP daemon tried the action.
scontext contains ftpd_t, the SELinux type of the FTP process.
tcontext contains the file label, for example var_t or default_t.
denied { read } or denied { write } tells you what SELinux blocked.
```

Why:

```text
AVC logs give proof.
We do not guess random SELinux commands.
```

---

## 8. Check process and file labels

Check the process label:

```bash
ps -eZ | grep vsftpd
```

Expected process type:

```text
ftpd_t
```

Check the file labels:

```bash
ls -Zd /srv/company-drop
ls -Zd /srv/company-drop/pub
ls -Z  /srv/company-drop/pub/readme.txt
ls -Zd /srv/company-drop/incoming
```

Bad or suspicious types for this lab:

```text
default_t
var_t
```

Expected final types after the fix:

```text
/srv/company-drop              public_content_t
/srv/company-drop/pub          public_content_t
/srv/company-drop/pub/readme.txt public_content_t
/srv/company-drop/incoming     public_content_rw_t
```

Why:

```text
SELinux decisions compare the process label with the file label.
Here the FTP daemon runs as ftpd_t.
The content must have a type that ftpd_t is allowed to use.
```

---

## 9. Use the local SELinux documentation

This is the important part.

Do not memorize random SELinux labels. Find the service-specific SELinux documentation.

Install the documentation package if needed (it's installed by the script in this lab!):

```bash
dnf install -y selinux-policy-doc
```

Find FTP-related SELinux man pages:

```bash
man -k _selinux | grep -i ftp
```

Open the FTP SELinux man page:

```bash
man ftpd_selinux
```

Inside the man page, search with `/`:

```text
/public_content_t
/public_content_rw_t
/ftpd_anon_write
/BOOLEANS
/FILE_CONTEXTS
```

What this teaches you:

```text
public_content_t is used for public readable content.
public_content_rw_t is used for public readable/writable content.
ftpd_anon_write controls whether anonymous FTP users may write.
```

You can also list FTP booleans directly:

```bash
getsebool -a | grep -i ftp
```

And inspect known file-context rules:

```bash
semanage fcontext -l | grep -E 'public_content|ftp|ftpd'
```

Why:

```text
In the exam, the system often contains the documentation you need.
The man page tells you the correct SELinux types and booleans.
```

---

## 10. Fix the readable FTP content

First, make the FTP root and download area public readable content.

Use absolute paths, not relative paths.

Correct:

```bash
semanage fcontext -a -t public_content_t '/srv/company-drop(/.*)?'
restorecon -Rv /srv/company-drop
```

Do not do this:

```bash
semanage fcontext -a -t public_content_t pub
```

Why not:

```text
A relative rule like pub is not a good rule for /srv/company-drop/pub.
Use the full path regex.
```

Important:

```text
semanage fcontext creates the persistent rule.
restorecon applies the rule to the files now.
restorecon has no --permanent option.
```

Check the result:

```bash
semanage fcontext -l | grep company-drop
ls -Zd /srv/company-drop
ls -Zd /srv/company-drop/pub
ls -Z /srv/company-drop/pub/readme.txt
```

Expected type:

```text
public_content_t
```

---

## 11. Fix the upload directory

The upload directory needs a writable public-content label.

```bash
semanage fcontext -a -t public_content_rw_t '/srv/company-drop/incoming(/.*)?'
restorecon -Rv /srv/company-drop/incoming
```

Check it:

```bash
ls -Zd /srv/company-drop/incoming
semanage fcontext -l | grep company-drop
```

Expected type:

```text
public_content_rw_t
```

Why only `incoming`:

```text
Only incoming should be writable.
The pub directory only needs download access.
Do not make the whole FTP tree writable.
```

---

## 12. Enable anonymous FTP writing

Check the boolean:

```bash
getsebool ftpd_anon_write
```

If it is off, enable it persistently:

```bash
setsebool -P ftpd_anon_write on
```

Verify:

```bash
getsebool ftpd_anon_write
```

Expected:

```text
ftpd_anon_write --> on
```

Why:

```text
For anonymous FTP upload, the writable label is not enough.
SELinux also requires the ftpd_anon_write boolean.
Use -P so the change survives reboot.
```

---

## 13. Retest with `lftp`

Restart the service:

```bash
systemctl restart vsftpd
```

Test download:

```bash
lftp -u anonymous,anonymous localhost -e 'ls; ls pub; cat pub/readme.txt; bye'
```

Test upload:

```bash
echo "upload test from SELinux lab" > /tmp/upload-test.txt
lftp -u anonymous,anonymous localhost -e 'cd incoming; put /tmp/upload-test.txt; ls; bye'
```

Check on the server:

```bash
ls -l /srv/company-drop/incoming
ls -Z /srv/company-drop/incoming
```

Expected:

```text
Download works.
Upload works.
Uploaded files appear in /srv/company-drop/incoming.
```

---

## 14. Final verification

Check SELinux is still enforcing:

```bash
getenforce
```

Check service state:

```bash
systemctl is-active vsftpd
systemctl is-enabled vsftpd
```

Check firewall:

```bash
firewall-cmd --list-all
firewall-cmd --permanent --list-all
```

Check persistent SELinux file-context rules:

```bash
semanage fcontext -l | grep company-drop
```

Check current labels:

```bash
ls -Zd /srv/company-drop
ls -Zd /srv/company-drop/pub
ls -Z  /srv/company-drop/pub/readme.txt
ls -Zd /srv/company-drop/incoming
```

Check the boolean:

```bash
getsebool ftpd_anon_write
```

Check for fresh denials:

```bash
ausearch -m AVC -ts recent | grep -i ftp
```

---

## Final command summary

```bash
# Test first
lftp -u anonymous,anonymous localhost -e 'ls; ls pub; cat pub/readme.txt; bye'
echo "upload test" > /tmp/upload-test.txt
lftp -u anonymous,anonymous localhost -e 'cd incoming; put /tmp/upload-test.txt; bye'

# Basic service checks
systemctl status vsftpd --no-pager
ss -tulpen | grep :21
firewall-cmd --list-all

# SELinux investigation
getenforce
ausearch -m AVC -ts recent
ps -eZ | grep vsftpd
ls -Zd /srv/company-drop /srv/company-drop/pub /srv/company-drop/incoming
getsebool -a | grep -i ftp

# Documentation
dnf install -y selinux-policy-doc
man ftpd_selinux

# Fix labels
semanage fcontext -a -t public_content_t '/srv/company-drop(/.*)?'
restorecon -Rv /srv/company-drop

semanage fcontext -a -t public_content_rw_t '/srv/company-drop/incoming(/.*)?'
restorecon -Rv /srv/company-drop/incoming

# Fix anonymous FTP upload boolean
setsebool -P ftpd_anon_write on

# Retest
systemctl restart vsftpd
lftp -u anonymous,anonymous localhost -e 'ls; ls pub; cat pub/readme.txt; cd incoming; put /tmp/upload-test.txt; ls; bye'
```

---

## What to remember

```text
Test the service first.
Check normal service/network/firewall layers.
Use audit logs for SELinux proof.
Use ps -Z and ls -Z to compare process and file labels.
Use man ftpd_selinux to find the correct types and booleans.
Use semanage fcontext for persistent file-label rules.
Use restorecon to apply those rules now.
Use setsebool -P for persistent SELinux boolean changes.
Retest with the same lftp commands.
```
