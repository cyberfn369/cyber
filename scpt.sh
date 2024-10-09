#!/bin/sh

# Check if the input file is provided
if [ -z "$1" ]; then
    echo "Error: Please provide a text file with username:password pairs."
    exit 1
fi

# Check if the file exists and is readable
if [ ! -f "$1" ] || [ ! -r "$1" ]; then
    echo "Error: File does not exist or is not readable."
    exit 1
fi

# Function to check if a user already exists
user_exists() {
    grep -q "^$1:" /etc/passwd
}

# Function to generate an encrypted password
generate_encrypted_password() {
    openssl passwd -6 "$1" 2>/dev/null
}

# Collect specified users from input file
specified_users=$(cut -d':' -f1 "$1")

# Process the input file line by line
while IFS=: read -r username password; do
    # Check if user exists
    if user_exists "$username"; then
        echo "User $username already exists."
    else
        echo "Creating user: $username"

        # Auto-generate a unique user ID (UID)
        USERID=$(($(tail -n 1 /etc/passwd | cut -d: -f3) + 1))
        GROUPID=$(id -g)  # Use current group ID
        HOMEDIR="/home/$username"
        SHELL="/bin/sh"  # Default shell

        # Add user to /etc/passwd
        echo "$username:x:$USERID:$GROUPID::${HOMEDIR}:${SHELL}" >> /etc/passwd

        # Add entry to /etc/shadow
        if [ -z "$password" ]; then
            # Force password change at next login
            echo "$username:!!:18469:0:99999:7:::" >> /etc/shadow
            echo "No password provided for $username. User will be required to set a password at next login."
        else
            encrypted_password=$(generate_encrypted_password "$password")
            echo "$username:$encrypted_password:18469:0:99999:7:::" >> /etc/shadow
            echo "Password set for user $username."
        fi

        # Create home directory and set permissions
        mkdir -p "$HOMEDIR"
        chown "$username:$GROUPID" "$HOMEDIR"
        chmod 755 "$HOMEDIR"
        echo "Home directory created for user $username at $HOMEDIR."
    fi
done < "$1"

# Deleting users not specified in the input file and are not system/application users
# Setting UID threshold (typically system users have UID < 1000)
UID_THRESHOLD=1000

# Loop through all users in /etc/passwd
while IFS=: read -r system_username _ uid _; do
    if [ "$uid" -ge "$UID_THRESHOLD" ]; then  # Skip system users with UID < UID_THRESHOLD
        if ! echo "$specified_users" | grep -q "^$system_username$"; then
            echo "Deleting user $system_username as they are not in the input file."
            
            # Remove the user's entry from /etc/passwd and /etc/shadow
            sed -i "/^$system_username:/d" /etc/passwd
            sed -i "/^$system_username:/d" /etc/shadow
            
            # Remove home directory
            rm -rf "/home/$system_username"
            echo "User $system_username and their home directory have been removed."
        fi
    fi
done < /etc/passwd
