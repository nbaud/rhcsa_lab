We have a server running vsftpd (use the shell script here to prepare the setup on Rocky Linux 9 or 10, or even RHEL 9 or 10).

The goal is simple:

Anonymous users (!) must be able to download files from /srv/company-drop/pub
and upload files into /srv/company-drop/incoming.

###### But SELinux must stay Enforcing.

So we are not allowed to use setenforce 0.
We are not allowed to disable SELinux.
We are not allowed to move the files into /var/ftp.
And we are not allowed to use chmod 777.

This is the whole point of the lab:
not guessing commands, but diagnosing which SELinux rule is blocking us.

Test downloads with:

`lftp -u anonymous,anonymous localhost -e 'ls; ls pub; cat pub/readme.txt; bye'`

Test uploads with:

`echo "upload test" > /tmp/upload-test.txt`
`lftp -u anonymous,anonymous localhost -e 'cd incoming; put /tmp/upload-test.txt; bye'`
