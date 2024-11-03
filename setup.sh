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
	echo "Configuration of custom config files use"
	echo
	echo
	# Import config files into '~/'
	if ask "Do you want to import my custom configuration files ? (y/n) "; then
# Set script and user's directories
		echo "Importing custom config files into the user's home directory..."
		echo
		echo
		SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
		USER_HOME=$(eval echo "~$SUDO_USER")

# Check existence of source directory
		if [ ! -d "$SCRIPT_DIR/dotfiles" ]; then
			echo "Error: Directory $SCRIPT_DIR/dotfiles does not exist."
			return 1
		fi

# Copy each file and check success
		for file in ".bashrc" ".bash_aliases" ".vimrc" ".zshrc"; do
			cp "$SCRIPT_DIR/dotfiles/$file" "$USER_HOME/" && echo "$file copied successfully" || echo "Failed to copy $file"
		done

		echo "Configuration files successfully copied to your home directory !"
		echo
		echo
		echo
	else
		echo
		echo
		echo
		return 0
	fi
}

ask()
{
	while true; do
		read -p "$1 (y/n) : " -n 1 -r first_reply
		echo

		if [[ ! $first_reply =~ ^[YyNn]$ ]]; then
			echo "Invalid input. Please enter 'y' for Yes or 'n' for No."
			echo
			continue
		fi

		read -p "Please confirm (same answer as before (y/n) : " -n 1 -r second_reply
		echo

		if [[ ! $second_reply =~ ^[YyNn]$ ]]; then
			echo "Invalid input. Please enter 'y' for Yes or 'n' for No."
			echo
			continue
		fi

		if [[ ! "${first_reply,,}" == "${second_reply,,}" ]]; then
			echo "The answers do not match. Please try again."
			echo
			continue
		fi

		if [[ ${first_reply,,} == "y" ]]; then
			return 0
		else
			return 1
		fi
	done
}

update_system()
{
	# Updating the system
	echo "Updating package lists..."
	echo
	sudo apt update -y
	echo
	echo
	echo "Upgrading installed packages..."
	echo
	sudo apt upgrade -y
	echo
	echo
	echo
}

install_essential_packages()
{
	# Function to install essential programs
	echo "Installing essential packages (git, curl, wget)"
	echo
# Essential packages list
	essential_packages=("git" "curl" "wget")
# Installing essential packages
	for pkg in "${essential_packages[@]}"; do
		if ! dpkg -s "$pkg" >/dev/null 2>&1; then
			echo "Installing $pkg..."
			if ! sudo apt install -y "$pkg"; then
				echo "Error : $pkg installation failed. Please check the dependencies or your internet connection."
				exit 1
			fi
		else
			echo "$pkg is already installed."
		fi
	done

	echo "All essential packages are correctly installed !"
	echo
	echo
	echo
}

install_optional_packages()
{
	echo "Installing (or not) some optionnal packages"
	echo
	# Function to install optional packages
	declare -A optional_packages_descriptions=(
		["bat"]="A cat clone with syntax highlighting and Git integration."
		["tree"]="A directory listing command that displays directories as a tree structure."
		["vim"]="A highly configurable text editor built to enable efficient text editing."
		["build-essential"]="A package that installs essential packages for building software (gcc, make, etc.)."
	)

	for pkg in "${!optional_packages_descriptions[@]}"; do
		description=${optional_packages_descriptions[$pkg]}
		echo "$pkg: $description"
		if ask "Do you want to install $pkg?"; then
			if ! dpkg -s "$pkg" >/dev/null 2>&1; then
				echo "Installing $pkg..."
				sudo apt install -y "$pkg"
				echo
				echo "$pkg installation completed."
			else
				echo "$pkg is already installed."
			fi
		else
			echo "$pkg installation skipped."
			echo
		fi
		echo
	done

	echo "The optional packages installation process is now complete !"
	echo
	echo
	echo
}

add_aliases()
{
	echo "Setting up some custom aliases"
	echo
	echo
	if ask "Do you want to use some of my custom aliases (choice possible for each alias) ? (y/n) "; then
	# Configure personnal aliases
		echo
		echo "Setting up custom aliases..."
		echo
		echo "#My aliases (import from autosetup project)\n" >> ~/.zshrc
		echo

		if ask "Do you want to use 'bat' for 'batcat' ? (y/n) "; then
			echo
			echo "alias bat='batcat'" >> ~/.zshrc
		fi
		
		if ask "Do you want to use 'update' for 'sudo apt-get update' ? (y/n) "; then
			echo
			echo "alias update='sudo apt-get update'" >> ~/.zshrc
		fi

		if ask "Do you want to use 'upgrade' for 'sudo apt-get upgrade' ? (y/n) "; then
			echo
			echo "alias upgrade='sudo apt-get upgrade'" >> ~/.zshrc
		fi

		if ask "Do you want to use 'norm' for 'norminette -R CheckForbiddenSourceHeader' ? (y/n) "; then
			echo
			echo "alias norm='norminette -R CheckForbiddenSourceHeader'" >> ~/.zshrc
		fi

		if ask "Do you want to use 'wnorm' for 'watch norminette -R CheckForbiddenSourceHeader' ? (y/n) "; then
			echo
			echo "alias wnorm='watch norminette -R CheckForbiddenSourceHeader'" >> ~/.zshrc
		fi

		if ask "Do you want to use 'ccf' for 'cc -Werror -Wextra -Wall' ? (y/n) "; then
			echo
			echo "alias ccf='cc -Werror -Wextra -Wall'" >> ~/.zshrc
		fi

		echo "Creation of custom aliases completed ! (see them in ~/.zshrc)"
	else
		echo "No alias added."
	fi
	echo
	echo
	echo
}

config_git()
{
	echo "Git configuration"
	echo
	if ask "Do you want to configure git ? (y/n) "; then
		echo "Configuring Git..."
		echo

		# Saisie du nom d'utilisateur et vérification qu'il n'est pas vide
		while true; do
			read -p "Enter your Git user name: " git_username
			if [ -z "$git_username" ]; then
				echo "Username cannot be empty. Please enter a valid username."
			else
				break
			fi
		done

		# Saisie de l'email et vérification qu'il n'est pas vide
		while true; do
			read -p "Enter your Git email address: " git_email
			if [ -z "$git_email" ]; then
				echo "Email cannot be empty. Please enter a valid email address."
			else
				break
			fi
		done

		# Application de la configuration Git pour l'utilisateur
		if sudo -u "$SUDO_USER" git config --global user.name "$git_username" &&
		   sudo -u "$SUDO_USER" git config --global user.email "$git_email"; then
			echo "Git configuration completed with username: '$git_username' and email: '$git_email'"
		else
			echo "Failed to configure Git. Please check your installation or permissions."
		fi

		# Vérification que la configuration a été appliquée correctement
		echo
		echo "Verifying Git configuration..."
		actual_username=$(sudo -u "$SUDO_USER" git config --global user.name)
		actual_email=$(sudo -u "$SUDO_USER" git config --global user.email)

		if [ "$actual_username" = "$git_username" ] && [ "$actual_email" = "$git_email" ]; then
			echo "Git has been successfully configured."
			echo "Git Username: $actual_username"
			echo "Git Email: $actual_email"
		else
			echo "There was an issue applying the Git configuration."
		fi
	else
		echo "Git has not been configured with your information. (You can do it later with 'git config --global user.name' and 'git config --global user.email')"
	fi
	echo
	echo
	echo
}


setup_ohmyzsh()
{
	echo "Setting up OhMyZsh"
	echo
	echo
	if ask "Do you want to use (and setup) OhMyZsh ? (y/n) "; then
# Vérifier si Zsh est installé
		echo
		if ! command -v zsh >/dev/null 2>&1; then
			echo "Zsh is not installed. Installing Zsh..."
			echo
			sudo apt-get update
			echo
			echo
			sudo apt-get install -y zsh
			echo
			if command -v zsh >/dev/null 2>&1; then
				echo "Zsh successfully installed. Let's continue !"
				echo
			else
				echo "Failed to install Zsh. Please check your internet connection or package manager settings."
				echo
				echo
				echo
				return 1
			fi
		else
			echo "Zsh is already installed."
			echo
		fi
# Configurer Zsh comme terminal par défaut si ce n'est pas déjà le cas
		echo "Configuring Zsh as the default shell for the user $SUDO_USER..."
		if [ "$(getent passwd "$SUDO_USER" | cut -d: -f7)" != "/bin/zsh" ]; then
			if echo "$SUDO_USER:$(which zsh)" | sudo chsh -s "$(which zsh)" "$SUDO_USER"; then
				echo "Zsh is now set as the default shell for $SUDO_USER."
			else
				echo "Failed to set Zsh as the default shell for $SUDO_USER. You might need to check permissions."
				echo
				echo
				echo
				return 1
			fi
		else
			echo "Zsh is already the default shell for $SUDO_USER."
		fi
		echo
		echo
# Install OhMyZsh
		echo "Installing Oh-My-Zsh for user $SUDO_USER..."
		echo
		if [ ! -d "/home/$SUDO_USER/.oh-my-zsh" ]; then
# Exécuter l'installation d'OhMyZsh
			curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o /tmp/ohmyzsh_install.sh
			sed -i 's/^exec zsh -l/#exec zsh -l/' /tmp/ohmyzsh_install.sh
			sudo -u "$SUDO_USER" RUNZSH=~no sh /tmp/ohmyzsh_install.sh --unattended
			rm /tmp/ohmyzsh_install.sh
# Vérifier si l'installation a réussi
			echo
			if [ -d "/home/$SUDO_USER/.oh-my-zsh" ]; then
				echo "OhMyZsh installation successful for user $SUDO_USER !"
				echo
				echo "Close and reopen the terminal to apply OhMyZsh settings."
			else
				echo "OhMyZsh installation failed for user $SUDO_USER. Please check your internet connection or permissions."
				echo
				echo
				echo
				return 1
			fi
		else
			echo "OhMyZsh is already installed for $SUDO_USER."
		fi
		echo
# Ajouter le lancement de Zsh dans .bashrc de l'utilisateur
		bashrc_path="/home/$SUDO_USER/.bashrc"
		zsh_launch_code="[ -t 1 ] && exec zsh"
		if ! grep -qxF "$zsh_launch_code" "$bashrc_path"; then
			echo "Adding Zsh launch command to $bashrc_path..."
			echo -e "\n# Launch Zsh at bash terminal startup\n$zsh_launch_code" | sudo tee -a "$bashrc_path" > /dev/null
			echo "Zsh launch command added to $bashrc_path."
		else
			echo "Zsh launch command already exists in $bashrc_path."
		fi

	else
		echo "OhMyZsh installation and configuration cancelled."
	fi
	echo "Settings applied. You may need to reopen the terminal to see the full effect."
	echo
	echo
	echo
}

personnalize_terminal()
{
	echo "Personalize the terminal's appearence"
	echo
	echo
	if ask "Do you want to use my personal terminal profile ? (background transparency) (y/n) "; then
	# Configure terminal background transparency
		echo "Configure terminal background transparency..."
		echo
# Get default terminal profile UUID
		DEFAULT_PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d \')

# Disable use of system theme colors
		dconf write /org/gnome/terminal/legacy/profiles:/:$DEFAULT_PROFILE/use-theme-colors false

# Enable background transparency
		dconf write /org/gnome/terminal/legacy/profiles:/:$DEFAULT_PROFILE/use-transparent-background true

# Set transparency level
		dconf write /org/gnome/terminal/legacy/profiles:/:$DEFAULT_PROFILE/background-transparency-percent 13
		echo "Transparency of background terminal set to 13%."
	else
		echo "Terminal personalization cancelled."
	fi
	echo
	echo
	echo
}

install_norminette()
{
	echo "Norminette configuration"
	echo
	echo
	if ask "Do you want to install the Holy norminette ? (y/n) "; then
	# Add 'norminette' module
		echo "Adding norminette module...
		"
		sudo apt update
		sudo apt install -y python3-setuptools pipx
		pipx install norminette
		pipx ensurepath
		source ~/.zshrc
		echo "Norminette added !"
	else
		echo "The norminette module will not be installed. May the force be with you !"
	fi
	echo
	echo
	echo
}

is_firefox_profile()
{
	local dir="$1"
	[[ -f "$dir/prefs.js" && -f "$dir/places.sqlite" ]]
}

restore_firefox_profiles()
{
	echo "Restoring Firefox profiles for each user in the .deb version..."
	for user_home in /home/*; do
		user_name=$(basename "$user_home")
		profile_target_dir="$user_home/.mozilla/firefox"

		for backup_dir in "$user_home/.mozilla/firefox_backup_"* "$user_home/snap/firefox/common/.mozilla/firefox_backup_"* "$user_home/.var/app/org.mozilla.firefox/.mozilla/firefox_backup_"*; do
			if [ -d "$backup_dir" ]; then
				valid_profile_found=false
				for profile_subdir in "$backup_dir"/*/; do
					if is_firefox_profile "$profile_subdir"; then
						echo "Restoring profile of $user_name from $backup_dir..."

# Supprimer uniquement les répertoires de profil existants dans firefox/
						find "$profile_target_dir" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +

# Copier les profils de sauvegarde dans firefox/
						cp -a "$backup_dir/"* "$profile_target_dir/"
						echo "Restoration of $user_name's profile complete."
						valid_profile_found=true
					fi
				done
				if ! $valid_profile_found; then
					echo "No valid Firefox profile backup found for $user_name in $backup_dir."
					echo "Contents of $backup_dir: $(ls "$backup_dir")"
				fi
			else
				echo "Backup directory $backup_dir does not exist for $user_name."
			fi
		done

		if [ -d "$profile_target_dir" ] && [ "$(ls -A "$profile_target_dir")" ]; then
			echo "Complete restoration of $user_name's profile to the .deb version."
		else
			echo "No profile backup restored for $user_name."
		fi
	done
	echo
	echo "Profile restoration to .deb version complete for all users."
	echo "All users can now use Firefox in .deb version with their profiles !"
}

install_firefox()
{
	echo "Firefox in .deb installation"
	echo
	echo
	if ask "Do you want to install Firefox in .deb version ? (y/n) "; then
	# Install firefox in .deb version (or tranfer the snap firefox version profile
	# to .deb future installation, and install it)
		echo
		echo "Starting Firefox .deb installation..."
		echo
# Check disk space for Firefox installation
		echo "Checking available disk space..."
		AVAILABLE_SPACE=$(df ~/ | grep -vE '^Filesystem' | awk '{print $4}')
		if [ "$AVAILABLE_SPACE" -lt 1048576 ]; then
			echo "Not enough disk space for Firefox installation. Installation cancelled."
			echo
			echo
			return 0
		else
			AVAILABLE_SPACE_GB=$(echo "scale=2; $AVAILABLE_SPACE/1048576" | bc)
			echo "Disk space available : $AVAILABLE_SPACE_GB GB"
			echo
			echo
		fi

# Check dependencies for Firefox installation
		echo "Checking dependencies for Firefox installation..."
		echo
		sudo apt-get install firefox --dry-run
		echo
		echo
# Ask for confirmation to proceed with the installation
		if ask "Do you want to proceed with the installation of Firefox ? (y/n) "; then
# Perform the actual installation of Firefox
			echo "Start of Firefox .deb installation protocol..."
			echo
# Verification and copy of snap, flatpak and/or .deb firefox version profile
			echo "Save Firefox profiles for each user (for : .deb, snap, flatpak)..."
			for user_home in /home/*; do
				user_name=$(basename "$user_home")
# .deb installation profile
				profile_dir_deb="$user_home/.mozilla/firefox"
				if [ -d "$profile_dir_deb" ]; then
					backup_dir="$user_home/.mozilla/firefox_backup_$(date +%Y%m%d)"
					echo "Profile (.deb) of $user_name saved in $backup_dir !"
					cp -a "$profile_dir_deb" "$backup_dir"
				fi
# Snap installation profile
				profile_dir_snap="$user_home/snap/firefox/common/.mozilla/firefox"
				if [ -d "$profile_dir_snap" ]; then
					backup_dir="$user_home/snap/firefox/common/.mozilla/firefox_backup_$(date +%Y%m%d)"
					echo "Profile (snap) of $user_name saved in $backup_dir !"
					cp -a "$profile_dir_snap" "$backup_dir"
				fi
# Flatpak installation profile
				profile_dir_flatpak="$user_home/.var/app/org.mozilla.firefox/.mozilla/firefox"
				if [ -d "$profile_dir_flatpak" ]; then
					backup_dir="$user_home/.var/app/org.mozilla.firefox/.mozilla/firefox_backup_$(date +%Y%m%d)"
					echo "Profile (flatpak) of $user_name saved in $backup_dir !"
					cp -a "$profile_dir_flatpak" "$backup_dir"
				fi
			done
			echo "Profile saving complete !"
			echo
# Update and install necessary dependencies
			echo "Install necessary dependencies..."
			echo
			sudo apt-get update
			echo
			sudo apt-get install -y curl wget apt-transport-https dirmngr ca-certificates
			echo
			echo "Needed dependencies are now installed !"
			echo
			echo
# Remove snap and/or flatpak version of firefox, and clean up any previous .deb installations
			echo "Removing potential existing Firefox versions"
			echo
			echo "Remove old Firefox snap installation..."
			if snap list firefox >/dev/null 2>&1; then
				if ! sudo snap remove --purge firefox; then
					echo "Error : Firefox snap removal failed. Please check the cause manually."
				else
					echo "Firefox snap version removed with success !"
				fi
			else
				echo "Snap 'firefox' is not installed."
				echo "Error : Firefox snap removal failed. Please check the cause manually."
			fi
			echo
			echo "Remove old Firefox flatpak installation..."
			if command -v flatpak >/dev/null 2>&1; then
				if flatpak list | grep -q org.mozilla.firefox; then
					if ! sudo flatpak uninstall --delete-data org.mozilla.firefox; then
						echo "Error : Firefox flatpak removal failed. Please check the cause manually."
					else
						echo "Firefox flatpak version removed with success !"
					fi
				else
						echo "flatpak 'firefox' is not installed."
						echo "Error : Firefox flatpak removal failed. Please check the cause manually."
				fi
			else
				echo "Flatpak is not installed on this system. Skipping flatpak removal for Firefox."
			fi
			echo
			echo "Remove old firefox .deb installation..."
			if dpkg -l | grep -q firefox; then
				if ! sudo apt purge firefox; then
					echo "Error : Firefox .deb removal failed. Please check the cause manually."
				else
					echo "Previous firefox .deb version removed with success !"
				fi
			else
				echo ".deb 'firefox' is not installed."
				echo "Error : Firefox .deb removal failed. Please check the cause manually."
			fi
			echo
			echo
# Configure the official Mozilla repository
			echo "Create a directory to store APT repository keys if it doesn't already exist..."
			sudo install -d -m 0755 /etc/apt/keyrings
			echo "Directory created. Let's continue !"
			echo
			echo
			echo "Import signing keys from Mozilla APT repository..."
			wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
			echo "Mozilla APT repository signature keys imported correctly. Let's continue !"
			echo
			echo
			echo "Digital fingerprint verification..."
			if ! sudo -u "$SUDO_USER" gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | awk '/pub/ { getline; gsub(/^ +| +$/, ""); if ($0 == "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3") { print "The digital fingerprint of the key matches (" $0 ").\nLet'\''s continue!"; exit 0 } else { print "Key verification failure: the fingerprint (" $0 ") does not match the one due."; exit 1 } }'; then
				echo "Digital fingerprint not as expected (35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3). Firefox installation has been cancelled for security reasons."
				echo
				echo
				return 1
			fi
			echo
			echo
			echo "Add the Mozilla APT repository to your list of sources ( /etc/apt/sources.list.d/mozilla.list )..."
			if ! grep -q "^deb .\+https://packages.mozilla.org/apt" /etc/apt/sources.list.d/mozilla.list; then
				echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null
				echo "Mozilla APT repository successfully added to your list of sources ( /etc/apt/sources.list.d/mozilla.list )."
			else
				echo "Mozilla APT repository is already configured in your list of sources ( /etc/apt/sources.list.d/mozilla.list )."
			fi
			echo
			echo
			echo "Configuring APT to give priority to packages from the Mozilla repository..."
			echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla
			echo "APT has been correctly configured to give priority to packages from the Mozilla repository. Let's continue !"
			echo
			echo
# Install Firefox from official Mozilla repository
			echo "Update your package list and install the Firefox .deb package..."
			echo
			sudo apt update
			if sudo apt install -y firefox; then
				echo
				echo "Firefox installation done !"
				echo
				echo
				restore_firefox_profiles
			else
				echo "Error: Failed to install Firefox .deb version. Please check the cause manually."
			fi
			echo "Installation and configuration of Firefox .deb complete !"
		else
			echo "Firefox installation cancelled."
			echo
			echo
			echo
			return 0
		fi
	else
		echo "Firefox .deb installation cancelled."
	fi
	echo
	echo
	echo

	# Execute these commands below to return to the snap version of Firefox
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
	echo "Discord .deb installation"
	echo
	echo
	if ask "Do you want to install Discord in .deb version ? (y/n) "; then
	# Install the .deb version of Discord after user confirmation
	# (if storage space is sufficient and dependencies are compatible)
		echo "Discord installation..."
		echo

# Check available disk space
		echo "Checking available disk space..."
		echo
		AVAILABLE_SPACE=$(df ~/ | grep -vE '^Filesystem' | awk '{print $4}')
		if [ "$AVAILABLE_SPACE" -lt 1048576 ]; then # Minimum 1GB in KB
			echo "Not enough disk space for discord installation. Installation cancelled."
			echo
			echo
			echo
			return 0
		else
			AVAILABLE_SPACE_GB=$(echo "scale=2; $AVAILABLE_SPACE/1048576" | bc)
			echo "Disk space available : $AVAILABLE_SPACE_GB GB"
			echo
		fi

# Download the Discord .deb file
		echo "Downloading Discord .deb file..."
		echo
		wget -O /tmp/discord.deb "https://discord.com/api/download?platform=linux&format=deb"
		echo "Discord .deb file downloaded !"
		echo

# Check dependencies with a dry-run installation
		echo "Checking required dependencies (see the result of virtual installation below, before validating installation)..."
		echo
		echo
		sudo apt install /tmp/discord.deb --dry-run
		echo
		echo

# Ask for confirmation to proceed with the installation
		if ask "Do you want to proceed with the installation of Discord? (y/n) "; then
# Perform the actual installation of Discord
			echo "Discord will be installed..."
			echo
			sudo apt install /tmp/discord.deb
# Remove the downloaded .deb file
			rm /tmp/discord.deb
			echo
			echo
			echo "Discord installation completed successfully !"
		else
			echo "Installation cancelled."
			rm /tmp/discord.deb
			echo
			echo
			echo
			return 0
		fi
	else
		echo "Discord .deb installation cancelled."
	fi
	echo
	echo
	echo
}

sudo_execute
update_system
import_config_files
install_essential_packages
install_optional_packages
config_git
setup_ohmyzsh
personnalize_terminal
install_norminette
install_firefox
install_discord
add_aliases

echo "Configuration changes are applied in this terminal. Please close and re-open the terminal to apply changes for future sessions."

