sudo apt-get install pip -y

pip install -r requirements.txt

directory_to_add="/users/gangmuk/.local/bin"
# Check if the directory exists
if [ -d "$directory_to_add" ]; then
    # Add the directory to the PATH in ~/.bashrc
    echo "export PATH=\$PATH:$directory_to_add" >> ~/.bashrc
    echo "Directory added to PATH. Restart your terminal or run 'source ~/.bashrc'."
else
    echo "Error: Directory does not exist."
fi
