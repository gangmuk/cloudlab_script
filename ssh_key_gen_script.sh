#!/bin/bash

KEY_PATH="/users/gangmuk/.ssh/id_rsa"

# Keep an existing key, so re-running doesn't break ssh between nodes that already trust it
if [ ! -f "$KEY_PATH" ]; then
    ssh-keygen -q -t rsa -b 2048 -N "" -f "$KEY_PATH"
elif [ ! -f "$KEY_PATH.pub" ]; then
    ssh-keygen -y -f "$KEY_PATH" > "$KEY_PATH.pub"
fi
