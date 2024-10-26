#!/bin/bash

	# Permissions verification
if [ "$EUID" -ne 0 ]; then
    echo "Please run the script as root using sudo."
    exit 1
fi

update_system()
{
	# Updating the system
echo "Updating package lists and upgrading installed packages..."
sudo apt update -y && sudo apt upgrade -y
}

install-essential()
{
	# Install programs
echo "Installing essential programs : git, vim, curl, wget, zsh, build-essential..."
sudo apt install -y git vim curl wget zsh build-essential
}

add_aliases()
{
	# Configure personnal aliases
echo "Setting up custom aliases..."
echo "#My aliases (import from autosetup project)\n" >> ~/.zshrc
echo "alias agud='sudo apt-get update'" >> ~/.zshrc
echo "alias agug='sudo apt-get upgrade'" >> ~/.zshrc
echo "alias norm='norminette -R CheckForbiddenSourceHeader'" >> ~/.zshrc
echo "alias wnorm='watch norminette -R CheckForbiddenSourceHeader'" >> ~/.zshrc
echo "alias ccf='cc -Werror -Wextra -Wall'" >> ~/.zshrc
echo "Creation of custom aliases completed ! (see them in ~/.zshrc)"
}

config_git()
{
	# Configure git
echo "Configuring Git..."
read -p "Enter your Git user name: " git_username
read -p "Enter your Git email address: " git_email
git config --global user.name "$git_username"
git config --global user.email "$git_email"
echo "Git configuration completed with username: $git_username and email: $git_email"
}

setup_ohmyzsh()
{
	# Set Zsh as default terminal
echo "Configure Zsh as default terminal..."
if [ "$SHELL" != "/bin/zsh" ]; then
	chsh -s /bin/zsh
	echo "Zsh is now the default terminal !"
fi

	# Configure terminal with Oh-My-Zsh
echo "Configure terminal with Oh-My-Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

	# Reload zsh configuration to apply changes
source ~/.zshrc
echo "Configuration changes are applied in this terminal, but you have to \
	close it and re-open it to apply changes for next times."
}

personnalize_terminal()
{
	# Configure terminal background transparency
echo "Configure terminal background transparency..."
# Get default terminal profile UUID
DEFAULT_PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d \')

# Disable use of system theme colors
dconf write /org/gnome/terminal/legacy/profiles:/:$DEFAULT_PROFILE/use-theme-colors false

# Enable background transparency
dconf write /org/gnome/terminal/legacy/profiles:/:$DEFAULT_PROFILE/use-transparent-background true

# Set transparency level
dconf write /org/gnome/terminal/legacy/profiles:/:$DEFAULT_PROFILE/background-transparency-percent 13
echo "Transparency of background terminal set to 13%."
}

install_norminette()
{
	# Add 'norminette' module
echo "Adding nominette module..."
sudo apt update
sudo apt install -y python3-setuptools pipx
pipx install norminette
pipx ensurepath
source ~/.zshrc
echo "Norminette added !"
}

install_firefox()
{
	# Install firefox in .deb version (or tranfer the snap firefox version profile
	# to .deb future installation, and install it)
	echo "Starting .deb version of Firefox installation..."
# Demander à l'utilisateur de choisir la langue de Firefox
	echo "Would you like to change the language code for Firefox installation ?"
	echo "The default language is 'en-US'."
	echo "Enter one of the language codes below, or press 'enter' to keep 'en-US'."
	echo "For example :"
	echo "	en-US	: English (US)"
	echo "	en-GB	: English (British)"
	echo "	fr	: French"
	echo "	de	: German"
	echo "	es-ES	: Spanish (Spain)"
	echo "	(Refer to README.md for the full list of language codes."
	echo "You can find it at : https://download.cdn.mozilla.net/pub/\
		firefox/releases/latest/README.txt)"
	lang_code="en-US"
	read -p "Enter the language code or 'enter' to keep default language (default : en-US): " lang_code

# Déterminer l'OS automatiquement
	if uname -m | grep -q 'x86_64'; then
		os="linux64"
	else
		os="linux"
	fi

# Construire l'URL de téléchargement de Firefox
firefox_url="https://download.mozilla.org/?product=firefox-latest&os=$os&lang=$lang_code"

# Télécharger Firefox
echo "Downloading Firefox for OS: $os and Language: $lang_code..."
wget -O firefox-latest.tar.bz2 "$firefox_url"
if [ $? -ne 0 ]; then
    echo "Error: Failed to download Firefox. Please check your internet connection or the language code."
    exit 1
fi

echo "Firefox downloaded successfully!"
# Check disk space for Firefox installation
	echo "Checking available disk space..."
	AVAILABLE_SPACE=$(df ~/ | grep -vE '^Filesystem' | awk '{print $4}')
	if [ "$AVAILABLE_SPACE" -lt 1048576 ]; then
	    echo "Not enough disk space for Firefox installation. Installation cancelled."
	    return 0
	else
	    AVAILABLE_SPACE_GB=$(echo "scale=2; $AVAILABLE_SPACE/1048576" | bc)
	    echo "Disk space available : $AVAILABLE_SPACE_GB GB"
	fi

# Check dependencies for Firefox installation
	echo "Checking dependencies for Firefox installation..."
	sudo apt-get install firefox --dry-run

# Ask for confirmation to proceed with the installation
	read -p "Do you want to proceed with the installation of Firefox ? (y/n)" -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
# Perform the actual installation of Firefox
# Verification and copy of snap firefox version profile
		echo "User profile transfer (from snap to .deb)..."
		if [ -d ~/snap/firefox/common/.mozilla/firefox/ ]; then
			mkdir -p ~/.mozilla/firefox/
			cp -a ~/snap/firefox/common/.mozilla/firefox/* ~/.mozilla/firefox/
			echo "Tranfer done !"
		else
			echo "No such snap firefox version profile finded. Let's continue !"
		fi

	# Update and install necessary dependencies
		echo "Install necessary dependencies..."
		sudo apt-get update
		sudo apt-get install -y curl wget apt-transport-https dirmngr ca-certificates
		echo "Needed dependencies installed !"

# Remove snap version of firefox, and clean up any previous .deb installations
		echo "Removing snap version of firefox, and clean up any \
			previous .deb installations..."
		sudo snap remove firefox
		sudo apt-get -y purge firefox
		echo "Snap and .deb version removed !"

# Configure the official Mozilla repository
		echo "Configuration of the official Mozilla repository..."
		sudo install -d -m 0755 /etc/apt/keyrings
		wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
		echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null
		echo "Official Mozilla repository configured !"

# Set preferences and automatic updates
		echo "Setting up preferences and automatic updates of Firefox..."
		echo '
		Package: *
		Pin: origin packages.mozilla.org
		Pin-Priority: 1000
		' | sudo tee /etc/apt/preferences.d/mozilla
	
		echo '
		Unattended-Upgrade::Allowed-Origins:: "packages.mozilla.org:${distro_codename}";
		' | sudo tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox
		echo "Firefox preferences and automatic updates configured !"

# Install Firefox from official Mozilla repository
		echo "Installation of Firefox from official Mozille repository..."
		sudo apt-get update
		sudo apt-get -y install firefox
		echo "Firefox installation done !"

	else
	        echo "Firefox installation cancelled."
		return 0
	fi

# Uncomment below to return to the snap version of firefox
#sudo rm -f /etc/apt/sources.list.d/mozilla.list
#sudo rm -f /etc/apt/preferences.d/mozilla
#sudo rm -f /etc/apt/apt.conf.d/51unattended-upgrades-firefox
#sudo apt-get update
#sudo apt-get -y purge firefox
#sudo apt-get -y install firefox
#sudo snap install firefox
#sudo snap refresh
}

install_discord()
{
	# Install the .deb version of Discord after user confirmation
	# (if storage space is sufficient and dependencies are compatible)
echo "Discord installation..."

# Check available disk space
echo "Checking available disk space..."
AVAILABLE_SPACE=$(df ~/ | grep -vE '^Filesystem' | awk '{print $4}')
if [ "$AVAILABLE_SPACE" -lt 1048576 ]; then # Minimum 1GB in KB
    echo "Not enough disk space for discord installation. Installation cancelled."
    rm ~/discord.deb
    return 0
else
    AVAILABLE_SPACE_GB=$(echo "scale=2; $AVAILABLE_SPACE/1048576" | bc)
    echo "Disk space available : $AVAILABLE_SPACE_GB GB"
fi

# Download the Discord .deb file
echo "Downloading Discord .deb file..."
wget -O ~/discord.deb "https://discord.com/api/download?platform=linux&format=deb"
echo "Discord .deb file downloaded !"

# Download the checksum file
echo "Downloading Discord checksum file..."
wget -O ~/discord.deb.sha256 "https://discord.com/api/download?platform=linux&format=sha256"

# Verify checksum
echo "Verifying file integrity..."
sha256sum -c ~/discord.deb.sha256
if [ $? -ne 0 ]; then
	echo "Checksum verification failed. Installation aborted."
	rm ~/discord.deb ~/discord.deb.sha256
	return 0
else
	echo "Checksum verification is valid. Let's continue !"
	rm ~/discord.deb.sha256
fi

# Check dependencies with a dry-run installation
echo "Checking required dependencies (see the result of virtual installation \
	below, before validating installation)..."
sudo apt install ~/discord.deb --dry-run

# Ask for confirmation to proceed with the installation
read -p "Do you want to proceed with the installation of Discord? (y/n)" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
# Perform the actual installation of Discord
	echo "Discord will be installed..."
	sudo apt install -y ~/discord.deb
# Remove the downloaded .deb file
	rm ~/discord.deb
	echo "Discord installation completed successfully."
else
	echo "Installation cancelled."
	rm ~/discord.deb
fi
}

echo "Configuration changes are applied in this terminal. Please close \
	and re-open the terminal to apply changes for future sessions."

