#! /bin/bash
cat>~/.wgetrc<<EOF
#You can set the default proxies for Wget to use for http, https, and ftp.
# They will override the value in the environment.
https_proxy = http://192.168.62.1:7890
http_proxy = http://192.168.62.1:7890

# If you do not want to use proxy at all, set this to off.
use_proxy = on
EOF
