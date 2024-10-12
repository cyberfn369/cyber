#!/bin/sh
logf=”pkg.txt"
chkcmd() { command -v "$1" >/dev/null 2>&1 ; }

any additional ones
default_package_manager=""
additional_package_managers=""

if chkcmd apt; then
    default_package_manager="apt"
elif chkcmd dnf; then
    default_package_manager="dnf"
elif chkcmd yum; then
    default_package_manager="yum"
elif chkcmd pacman; then
    default_package_manager="pacman"
elif chkcmd zypper; then
    default_package_manager="zypper"
else
    echo "Error: No supported package manager found."
    exit 1
fi

if chkcmd apt && [ "$default_package_manager" != "apt" ]; then
    additional_package_managers="$additional_package_managers apt"
fi
if chkcmd dnf && [ "$default_package_manager" != "dnf" ]; then
    additional_package_managers="$additional_package_managers dnf"
fi
if chkcmd yum && [ "$default_package_manager" != "yum" ]; then
    additional_package_managers="$additional_package_managers yum"
fi
if chkcmd pacman && [ "$default_package_manager" != "pacman" ]; then
    additional_package_managers="$additional_package_managers pacman"
fi
if chkcmd zypper && [ "$default_package_manager" != "zypper" ]; then
    additional_package_managers="$additional_package_managers zypper"
fi

# Log additional package managers
echo "$additional_package_managers" > "$logf"

echo "Default package manager: $default_package_manager"
echo "Additional package managers logged in: $logf"

# Task 2: Determine the best service manager (systemctl, service, etc.)
service_manager=""

if chkcmd systemctl; then
    service_manager="systemctl"
elif chkcmd service; then
    service_manager="service"
else
    echo "Error: No supported service manager found."
    exit 1
fi

echo "Service manager detected: $service_manager"

echo "Updating the system using $default_package_manager..."

if [ "$default_package_manager" = "apt" ]; then
    sudo apt update
elif [ "$default_package_manager" = "dnf" ]; then
    sudo dnf check-update
elif [ "$default_package_manager" = "yum" ]; then
    sudo yum check-update
elif [ "$default_package_manager" = "pacman" ]; then
    sudo pacman -Sy
elif [ "$default_package_manager" = "zypper" ]; then
    sudo zypper refresh
else
    echo "Error: Unsupported package manager for system update."
    exit 1
fi

echo "System update completed."

echo "Installing UFW using $default_package_manager..."

if [ "$default_package_manager" = "apt" ]; then
    sudo apt install -y ufw gufw
elif [ "$default_package_manager" = "dnf" ]; then
    sudo dnf install -y ufw gufw
elif [ "$default_package_manager" = "yum" ]; then
    sudo yum install -y ufw gufw
elif [ "$default_package_manager" = "pacman" ]; then
    sudo pacman -S --noconfirm ufw gufw
elif [ "$default_package_manager" = "zypper" ]; then
    sudo zypper install -y ufw gufw
else
    echo "Error: Could not install UFW. Unsupported package manager."
    exit 1
fi

echo "UFW installation completed."

# Enable and start UFW using the detected service manager
echo "Configuring UFW using $service_manager..."

if [ "$service_manager" = "systemctl" ]; then
    sudo systemctl enable ufw
    sudo systemctl start ufw
elif [ "$service_manager" = "service" ]; then
    sudo service ufw enable
    sudo service ufw start
else
    echo "Error: Unsupported service manager for managing UFW."
    exit 1
fi

echo "UFW is installed and started successfully.”
