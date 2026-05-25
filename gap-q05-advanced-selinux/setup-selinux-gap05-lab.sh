#!/usr/bin/env bash
set -euo pipefail

echo "== RHCSA SELinux Gap Lab Setup =="

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root."
  exit 1
fi

echo "== Installing packages =="
dnf install -y vsftpd firewalld policycoreutils-python-utils lftp selinux-policy-doc

echo "== Enabling SELinux enforcing mode =="
setenforce 1 || true
if [[ -f /etc/selinux/config ]]; then
  sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
fi

echo "== Creating custom FTP directory structure =="
mkdir -p /srv/company-drop/pub
mkdir -p /srv/company-drop/incoming

echo "RHCSA SELinux gap lab download test" > /srv/company-drop/pub/readme.txt

chmod 755 /srv/company-drop
chmod 755 /srv/company-drop/pub
chmod 733 /srv/company-drop/incoming

echo "== Writing vsftpd configuration =="
cp -a /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.bak.$(date +%s)

cat > /etc/vsftpd/vsftpd.conf <<'EOF'
anonymous_enable=YES
local_enable=NO
write_enable=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES

anon_root=/srv/company-drop

listen=YES
listen_ipv6=NO

pasv_enable=YES
pasv_min_port=30000
pasv_max_port=30010
EOF

echo "== Enabling firewall rules =="
systemctl enable --now firewalld

firewall-cmd --permanent --add-service=ftp
firewall-cmd --permanent --add-port=30000-30010/tcp
firewall-cmd --reload

echo "== Enabling vsftpd =="
systemctl enable vsftpd
systemctl restart vsftpd || true

echo
echo "Lab setup complete."
echo
echo "Your task:"
echo "  Make anonymous FTP download and upload work from /srv/company-drop"
echo "  while keeping SELinux Enforcing."
echo
echo "Rules:"
echo "  - Do not disable SELinux"
echo "  - Do not set SELinux to permissive"
echo "  - Do not move the files under /var/ftp"
echo "  - Do not use chmod 777"
echo "  - Make the solution persistent"
echo
echo "Suggested first checks:"
echo "  getenforce"
echo "  systemctl status vsftpd --no-pager"
echo "  ls -Zd /srv/company-drop /srv/company-drop/pub /srv/company-drop/incoming"
echo "  ausearch -m AVC -ts recent"
