#!/bin/bash

user_name="gangmuk"
ssh_path="/users/${user_name}/.ssh"
auth_key_path="authorized_keys"
ip_file="servers.txt"

python inventory.py &&

echo "read servers.txt file"
while IFS= read -r line; do
    lines+=("$line")
    done < ${ip_file}

for line in "${lines[@]}"; do
    echo "$line"
done

# gangmuk_mac="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDD22pZUmVXMchSMS4vPeJGOzaOupIn0kj9AcjcxiDvjramy7XCPbUsv2cxgC/oU/W67hCIABNfGA4yap9uyZPbFWz69mkeexqa+i/AUOCrUnmOJKmbL7KmyxzNN4virR67xGtX4B+DYPcCkTwFsqAxwbvBXAcP13kxUw7d2edfGE7fowFjUVOB27TqlJc98HxcFBau5KS6gXrwmmjbD7VCgoLk/5uLbVtunViwCJ+jxmNqgMr11ta/IZmXjZbTsyLaRXkbUNrbfjussCeIRLRYFcPx6qr0jz2ybfBgqPKWBDmyeM1wACd8YN+UOiR3vr174jRszElZqmHaPieEwLvrrHjxM1+40Ou1p8bVryWaZNAYfs2ERwvxXF6ti4K0FD5Res+TY2+2u7cP9lhqnZzgk3vxzPMnZSDEh81/k5co1QTVV+1C3tkXb7N7KuefE1FVEEtLTVK/yLDrGnSj78DdijdYKi15xif/KPcLpksCSBZunOgDG80rp4ywTg16aLc= gangmuk2@cs-gangmuk2-m01"

aditya_nvidia="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDd9SCJkPi3m1KPf6l13d7qzMxqFHKrQEZL4uynuV3SfZoq7Bh1tYZsDAaWqhjVBDoxQasdHBYN/HbYgzlcxM9DYlD2bwc1mfczj8DOh4GmSXqeGnFcQO7/S+84N/HsUBLu/zvcjqkcMhFokq/b8B/sUoTY0XZuGSF2HitIqHzaiuGVNPzziGDrrhPLQzR/VqCWt6kJaF5tudOhu295NwkKDAA9UvFxRC58VpEtodsfkDUraxtJfzd0o43SBY8R6Q/bqNGJMLHgx3G8wfbOh+YSJGXpHmzi6gByu2/PpmA8+krB/MGquzHdlRUOqYTxEM0xv7a9fmWaWrewoZKvytDHF9AP58YRPJ0bxf6ZWKklnoK3DYG27atcCbQIa0qCMwvdDS4lLxe9prfp3+p0JI5QX+TXNXuQvYrS3tkaAHlOU8Rme2zJI1du6hclfipMJ4gL+Wh5PutRg6y8nMcPlKKCgyScLBTNsxmacKFnCjFrcMwE74dY+SdjlnP5Vsgo2Qk= aprerepa@nvidia.com"

aditya_personal="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQChQf/Fx+dBK8WI7Mk7VaXP34jA3pu3WCHI42rrgypMOJ8IuofJR8ryaVJDlGJ7DL34M084f+uAcJBIzYsxhVZRVjNIf88+XWLDj4pYvmkNmF+Ne7De4A7M6jLw6XI4Rkowx37S7dPhQivvWcWnf1Ft/Td98wDRN+DmD2KZSmy0tiRfgY37TZrzWI8lPQ/1Z5oixcGiq3wwDqqYcKQ0NYkrrteU1dj/K+isdcKTCLQ6y3kMzkZQNINtivLipnKaFdLBbnAMqcdf65o5CpePd72qCXeKqZD4Ucr28bMi4VQpj+QaCvlKKpv1XkJP41k9kdhFsV8Sgl/mvYM0OSxEeDfTkPJT6SCW6hC14TEfRxENXTc3tqSLJnGyc5fjoU7FePRuVvaxkXC0TjqIst9Ghazb3556xkqHD/kXq4W/gym/s2l+sowguGDuk7roz/sFbP4ro8r2cXSU2M4iImB033DliX43B9DOAIDZKkKPKZOFcbLcdGDt7zF14s1WaWs+bIk= adiprerepa@gmail.com"

bandal="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB4rggj4mSj8CNKGODxa/LyUEhB6ZMzUxG/IRb679czH adityabandal007@gmail.com"

# all_keys=("${gangmuk_mac}" "${aditya_nvidia}" "${aditya_personal}")
all_keys=("${aditya_nvidia}" "${aditya_personal}")
# all_keys=("${bandal}")

for line in "${lines[@]}"; do
    for key in "${all_keys[@]}"; do
        ssh ${line} "grep -qxF '${key}' ${ssh_path}/${auth_key_path} || echo '${key}' >> ${ssh_path}/${auth_key_path}"
    done
done