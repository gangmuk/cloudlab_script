KEY_PATH="/users/gangmuk/.ssh/id_rsa"

# Check if the SSH key already exists
if [ -f "$KEY_PATH" ]; then
    # If it exists, remove it to avoid the overwrite prompt
    rm "$KEY_PATH"
fi

# Now, generate the key without fear of the overwrite prompt
ssh-keygen -q -t rsa -b 2048 -N "" -f "$KEY_PATH"