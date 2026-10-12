#!/bin/bash
github_account=$1

if [ -z "${github_account}" ]; then
    echo "Error: invalid argument"
	echo "github_account must be given as an argument"
	echo "usage: ./gitconfig.sh <github_account>"
	echo "github_account: gangmuk@gmail.com"
    echo "exit..."
	exit
fi

# Set Git global configurations

# Set core editor to vim
git config --global core.editor "vim"

# Set pull to rebase
git config --global pull.rebase true

# Set user name (replace with your actual name)
git config --global user.name "${github_account}"

# Set user email (replace with your actual email)
git config --global user.email "${github_account}"

echo "Git global configurations have been set."
echo "pull.rebase true"
echo "git user.name: ${github_account}"
echo "git user.email: ${github_account}"

git config --global --list
