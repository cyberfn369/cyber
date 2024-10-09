#!/bin/sh

if [ -z "$1" ]; then
    echo "Error: Please provide a text file with username:password pairs."
    exit 1
fi
if [ ! -f "$1" ] || [ ! -r "$1" ]; then
    echo "Error: File does not exist or is not readable."
    exit 1
fi


user_exists() {
    grep -q "^$1:" /etc/passwd
}
generate_encrypted_password() {
    openssl passwd -6 "$1" 2>/dev/null
}

specified_users=$(cut -d':' -f1 "$1")

while IFS=: read -r username password; do
    if user_exists "$username"; then
        echo "User $username already exists."
    else
        echo "Creating user: $username"
        USERID=$(($(tail -n 1 /etc/passwd | cut -d: -f3) + 1))
        GROUPID=$(id -g)
        HOMEDIR="/home/$username"
        SHELL="/bin/sh"

        
        echo "$username:x:$USERID:$GROUPID::${HOMEDIR}:${SHELL}" >> /etc/passwd
        if [ -z "$password" ]; then
            echo "$username:!!:18469:0:99999:7:::" >> /etc/shadow
            echo "No password provided for $username. User will be required to set a password at next login."
        else
            encrypted_password=$(generate_encrypted_password "$password")
            echo "$username:$encrypted_password:18469:0:99999:7:::" >> /etc/shadow
            echo "Password set for user $username."
        fi
        mkdir -p "$HOMEDIR"
        chown "$username:$GROUPID" "$HOMEDIR"
        chmod 755 "$HOMEDIR"
        echo "Home directory created for user $username at $HOMEDIR."
    fi
done < "$1"

UID_THRESHOLD=1000
exclusion="root nobody daemon bin sys man"
while IFS=: read -r system_username _ uid _; do
    if [ "$uid" -ge "$UID_THRESHOLD" ] && ! echo "$exclusion" | grep -qw "$system_username"; then
        if ! echo "$specified_users" | grep -q "^$system_username$"; then
            sed -i "/^$system_username:/d" /etc/passwd
            sed -i "/^$system_username:/d" /etc/shadow
            rm -rf "/home/$system_username"
            echo "User $system_username and their home directory have been removed."
        fi
    fi
done < /etc/passwd
