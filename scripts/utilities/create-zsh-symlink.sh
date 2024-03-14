# Create a symlink for .zshrc
zshrc_path="/home/bsarkar/Documents/badal/my-config/config/zsh/.zshrc"
symlink_path="$HOME/.zshrc"  # Replace with your desired symlink path

# Create the symlink
cd
ln -sf "$zshrc_path" .
echo "Symlink for .zshrc created."
