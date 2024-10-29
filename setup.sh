#!/bin/bash

sudo_execute()
{
	# Permissions verification
	if [ "$EUID" -ne 0 ]; then
	    echo "Please run the script as root using sudo."
	    exit 1
	fi
}

import_config_files()
{
	# Import config files into '~/'
# Set script directory
	echo "Import some customs config files into '~/'
	"
	SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Check existence of source directory
	if [ ! -d "$SCRIPT_DIR/dotfiles" ]; then
		echo "Error: Directory $SCRIPT_DIR/dotfiles does not exist."
		return 1
	fi

# Retrieve initial user's home directory (not root)
	USER_HOME=$(eval echo "~$SUDO_USER")
	echo "USER_HOME is set to: $USER_HOME"

# Copy configuration files to user's home directory
	echo "Importing configuration files into user's home directory..."

# Copy each file and check success
	cp "$SCRIPT_DIR/dotfiles/.bashrc" "$USER_HOME/"
	[ $? -eq 0 ] && echo ".bashrc copied successfully" || echo "Failed to copy .bashrc"

	cp "$SCRIPT_DIR/dotfiles/.bash_aliases" "$USER_HOME/"
	[ $? -eq 0 ] && echo ".bash_aliases copied successfully" || echo "Failed to copy .bash_aliases"

	cp "/home/humaan/autosetup_linux/dotfiles/.vimrc" "$USER_HOME/"
	[ $? -eq 0 ] && echo ".vimrc copied successfully" || echo "Failed to copy .vimrc"

	cp "$SCRIPT_DIR/dotfiles/.zshrc" "$USER_HOME/"
	[ $? -eq 0 ] && echo ".zshrc copied successfully" || echo "Failed to copy .zshrc"

	echo "Configuration files successfully copied to your home directory !

	"
}

ask_confirmation()
{
# Request user confirmation with error handling
	while true; do
		read -p "$1 (y/n): " -n 1 -r
		echo
		if [[ $REPLY =~ ^[YyNn]$ ]]; then
			break
		else
			echo "Invalid input. Please enter 'y' for Yes or 'n' for No.
			
			"
		fi
	done
}

update_system()
{
	# Updating the system
	echo "Updating package lists and upgrading installed packages...
	
	"
	sudo apt update -y && sudo apt upgrade -y
	echo "


	"
}

install_essential()
{
	# Install essential programs
	echo "Installing essential programs : bat, tree, git, vim, curl, wget, zsh, build-essential...
	
	"
	sudo apt install -y bat tree git vim curl wget zsh build-essential
	echo "


	"
}

add_aliases()
{
	read -p "Do you want to use some of my custom aliases (choice possible for each alias) ? (y/n) " -n 1 -r
        ask_confirmation "
Please confirm"
        if [[ $REPLY =~ ^[Yy]$ ]]; then
	# Configure personnal aliases
		echo "Setting up custom aliases...
		"
		echo "#My aliases (import from autosetup project)\n" >> ~/.zshrc
		read -p "Do you want to use 'bat' for 'batcat' ? (y/n) " -n 1 -r
		ask_confirmation "
Please confirm"
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			echo "alias bat='batcat'" >> ~/.zshrc
		fi
		read -p "Do you want to use 'agud' for 'sudo apt-get update' ? (y/n) " -n 1 -r
                ask_confirmation "
Please confirm"
                if [[ $REPLY =~ ^[Yy]$ ]]; then
			echo "alias agud='sudo apt-get update'" >> ~/.zshrc
		fi
		read -p "Do you want to use 'agug' for 'sudo apt-get upgrade' ? (y/n) " -n 1 -r
                ask_confirmation "
Please confirm"
                if [[ $REPLY =~ ^[Yy]$ ]]; then
			echo "alias agug='sudo apt-get upgrade'" >> ~/.zshrc
		fi
		read -p "Do you want to use 'norm' for 'norminette -R CheckForbiddenSourceHeader' ? (y/n) " -n 1 -r
                ask_confirmation "
Please confirm"
                if [[ $REPLY =~ ^[Yy]$ ]]; then
			echo "alias norm='norminette -R CheckForbiddenSourceHeader'" >> ~/.zshrc
		fi
		read -p "Do you want to use 'wnorm' for 'watch norminette -R CheckForbiddenSourceHeader' ? (y/n) " -n 1 -r
                ask_confirmation "
Please confirm"
                if [[ $REPLY =~ ^[Yy]$ ]]; then
			echo "alias wnorm='watch norminette -R CheckForbiddenSourceHeader'" >> ~/.zshrc
		fi
		read -p "Do you want to use 'ccf' for 'cc -Werror -Wextra -Wall' ? (y/n) " -n 1 -r
                ask_confirmation "
Please confirm"
                if [[ $REPLY =~ ^[Yy]$ ]]; then
			echo "alias ccf='cc -Werror -Wextra -Wall'" >> ~/.zshrc
		fi
		echo "Creation of custom aliases completed ! (see them in ~/.zshrc)
		
		
		"
	else
		echo "No alias added.
		
		
		"
		return 0
	fi
}

config_git()
{
	read -p "Do you want to configure git ? (y/n) " -n 1 -r
	ask_confirmation "
Please confirm"
	if [[ $REPLY =~ ^[Yy]$ ]]; then
	# Configure git
		echo "Configuring Git...
		
		"
		read -p "Enter your Git user name: " git_username
		read -p "Enter your Git email address: " git_email
		git config --global user.name "$git_username"
		git config --global user.email "$git_email"
		echo "Git configuration completed with username: '$git_username' and email: '$git_email'


		"
	else
		echo "Git has not been configured with your information. (You can do it later with 'git config --global user.name' and 'git config --global user.email')


		"
		return 0
	fi
}

setup_ohmyzsh()
{
	echo "Setting up OhMyZsh
	
	"
	read -p "Do you want to use (and setup) OhMyZsh ? (y/n) " -n 1 -r
	ask_confirmation "
Please confirm"
	if [[ $REPLY =~ ^[Yy]$ ]]; then
	# Set Zsh as default terminal
		echo "Configure Zsh as default terminal...
		
		"
		if [ "$SHELL" != "/bin/zsh" ]; then
			chsh -s /bin/zsh
			echo "Zsh is now the default terminal !
			
			"
	
		fi

	# Configure terminal with Oh-My-Zsh
		echo "Configure terminal with Oh-My-Zsh...
		
		"
		if [ ! -d "$HOME/.oh-my-zsh" ]; then
			sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
		fi

	# Reload zsh configuration to apply changes
	source ~/.zshrc
	echo "Configuration changes are applied in this terminal, but you have to 
close it and reopen it to apply changes for next times.
		
	
	"
	else
		echo "OhMyZsh installation and configuration cancelled.
	

		"
		return 0
	fi
}

personnalize_terminal()
{
	read -p "Do you want to use my personal terminal profile ? (background transparency) (y/n) " -n 1 -r
	ask_confirmation "
Please confirm"
	if [[ $REPLY =~ ^[Yy]$ ]]; then
	# Configure terminal background transparency
		echo "Configure terminal background transparency...
		"
# Get default terminal profile UUID
		DEFAULT_PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d \')

# Disable use of system theme colors
		dconf write /org/gnome/terminal/legacy/profiles:/:$DEFAULT_PROFILE/use-theme-colors false

# Enable background transparency
		dconf write /org/gnome/terminal/legacy/profiles:/:$DEFAULT_PROFILE/use-transparent-background true

# Set transparency level
		dconf write /org/gnome/terminal/legacy/profiles:/:$DEFAULT_PROFILE/background-transparency-percent 13
		echo "Transparency of background terminal set to 13%.
		
		
		"
	else
		echo "Terminal personalization cancelled.
		
		
		"
		return 0
	fi
}

install_norminette()
{
	read -p "Do you want to install the holy norminette ? (y/n) " -n 1 -r
	ask_confirmation "
Please confirm"
	if [[ $REPLY =~ ^[Yy]$ ]]; then
	# Add 'norminette' module
		echo "Adding norminette module...
		"
		sudo apt update
		sudo apt install -y python3-setuptools pipx
		pipx install norminette
		pipx ensurepath
		source ~/.zshrc
		echo "Norminette added !
		
		
		"
	else
		echo "The norminette module will not be installed. May the force be with you !
		
		
		"
		return 0
	fi
}

install_firefox()
{
	read -p "Do you want to install Firefox in .deb version ? (y/n) " -n 1 -r
	ask_confirmation "
Please confirm"
	if [[ $REPLY =~ ^[Yy]$ ]]; then
	# Install firefox in .deb version (or tranfer the snap firefox version profile
	# to .deb future installation, and install it)
		echo "Starting Firefox .deb installation...
		"
# Check disk space for Firefox installation
		echo "Checking available disk space...
		"
		AVAILABLE_SPACE=$(df ~/ | grep -vE '^Filesystem' | awk '{print $4}')
		if [ "$AVAILABLE_SPACE" -lt 1048576 ]; then
		    echo "Not enough disk space for Firefox installation. Installation cancelled.
		    
		    "
		    return 0
		else
			AVAILABLE_SPACE_GB=$(echo "scale=2; $AVAILABLE_SPACE/1048576" | bc)
			echo "Disk space available : $AVAILABLE_SPACE_GB GB
			
			"
		fi

# Check dependencies for Firefox installation
		echo "Checking dependencies for Firefox installation...
		
		"
		sudo apt-get install firefox --dry-run

# Ask for confirmation to proceed with the installation
		read -p "Do you want to proceed with the installation of Firefox ? (y/n) " -n 1 -r
		ask_confirmation "
Please confirm"
		if [[ $REPLY =~ ^[Yy]$ ]]; then
# Perform the actual installation of Firefox
			echo "Proceeding with the installation of Firefox...
			
			"
# Verification and copy of snap firefox version profile
			echo "User profile transfer (from snap to .deb)...
			"
			if [ -d ~/snap/firefox/common/.mozilla/firefox/ ]; then
				mkdir -p ~/.mozilla/firefox/
				cp -a ~/snap/firefox/common/.mozilla/firefox/* ~/.mozilla/firefox/
				echo "Transfer done !
				
				"
			else
				echo "No such snap firefox version profile finded. Let's continue !
			
				"
			fi

# Update and install necessary dependencies
			echo "Install necessary dependencies...
			
			"
			sudo apt-get update
			sudo apt-get install -y curl wget apt-transport-https dirmngr ca-certificates
			echo "Needed dependencies are now installed !
			
			"

# Remove snap version of firefox, and clean up any previous .deb installations
			echo "Removing snap version of firefox, and clean up any
previous .deb installations...
			
			"
			sudo snap remove firefox
			sudo apt-get -y purge firefox
			echo "Snap and .deb version removed !
			
			"

# Configure the official Mozilla repository
			echo "Configuration of the official Mozilla repository...
			
			"
			sudo install -d -m 0755 /etc/apt/keyrings
			wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
			echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null
			echo "Official Mozilla repository configured !
			
			"

# Set preferences and automatic updates
			echo "Setting up preferences and automatic updates of Firefox...
			
			"
			echo '
			Package: *
			Pin: origin packages.mozilla.org
			Pin-Priority: 1000
			' | sudo tee /etc/apt/preferences.d/mozilla

			echo '
			Unattended-Upgrade::Allowed-Origins:: "packages.mozilla.org:${distro_codename}";
			' | sudo tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox
			echo "Firefox preferences and automatic updates configured !
			
			"

# Install Firefox from official Mozilla repository
			echo "Installation of Firefox from official Mozilla repository...
			
			"
			sudo apt-get update
			sudo apt-get -y install firefox
			echo "Firefox installation done !
			
			
			"
		else
		        echo "Firefox installation cancelled.
			
			
			"
			return 0
		fi
	else
		echo "Firefox .deb installation cancelled.
		
		
		"
		return 0
	fi

	# Execute these commands below to return to the snap version of firefox
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
	read -p "Do you want to install Discord in .deb version ? (y/n) " -n 1 -r
        ask_confirmation "
Please confirm"
        if [[ $REPLY =~ ^[Yy]$ ]]; then
	# Install the .deb version of Discord after user confirmation
	# (if storage space is sufficient and dependencies are compatible)
		echo "Discord installation...
		
		"

# Check available disk space
		echo "Checking available disk space...
		
		"
AVAILABLE_SPACE=$(df ~/ | grep -vE '^Filesystem' | awk '{print $4}')
		if [ "$AVAILABLE_SPACE" -lt 1048576 ]; then # Minimum 1GB in KB
			echo "Not enough disk space for discord installation. Installation cancelled.
			
"
			rm ~/discord.deb
			return 0
		else
			AVAILABLE_SPACE_GB=$(echo "scale=2; $AVAILABLE_SPACE/1048576" | bc)
			echo "Disk space available : $AVAILABLE_SPACE_GB GB
			
"
		fi

# Download the Discord .deb file
		echo "Downloading Discord .deb file...
		
		"
		wget -O ~/discord.deb "https://discord.com/api/download?platform=linux&format=deb"
		echo "Discord .deb file downloaded !
		
		"

# Download the checksum file
		echo "Downloading Discord checksum file...
		
		"
		wget -O ~/discord.deb.sha256 "https://discord.com/api/download?platform=linux&format=sha256"

# Verify checksum
		echo "Verifying file integrity...
		
		"
		sha256sum -c ~/discord.deb.sha256
		if [ $? -ne 0 ]; then
			echo "Checksum verification failed. Installation aborted.
			
			
			"
			rm ~/discord.deb ~/discord.deb.sha256
			return 0
		else
			echo "Checksum verification is valid. Let's continue !
			
			"
			rm ~/discord.deb.sha256
		fi

# Check dependencies with a dry-run installation
		echo "Checking required dependencies (see the result of virtual installation 
below, before validating installation)...
		
		"
		sudo apt install ~/discord.deb --dry-run

# Ask for confirmation to proceed with the installation
		read -p "Do you want to proceed with the installation of Discord? (y/n) " -n 1 -r
		ask_confirmation "
Please confirm"
		if [[ $REPLY =~ ^[Yy]$ ]]; then
# Perform the actual installation of Discord
			echo "Discord will be installed...
			
			"
			sudo apt install -y ~/discord.deb
# Remove the downloaded .deb file
			rm ~/discord.deb
			echo "Discord installation completed successfully.
			
			
			"
		else
			echo "Installation cancelled.
			
			
			"
			rm ~/discord.deb
			return 0
		fi
	else
		echo "Discord installation cancelled.
		
		
		"
		return 0
	fi
}

sudo_execute
echo "Calling import_config_files function..."
import_config_files
update_system
install_essential
config_git
setup_ohmyzsh
personnalize_terminal
install_norminette
install_firefox
install_discord
add_aliases

echo "Configuration changes are applied in this terminal. Please close 
and re-open the terminal to apply changes for future sessions."

