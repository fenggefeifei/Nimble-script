#!/bin/bash

# Set the color variables
green='\033[0;32m'
red='\033[0;31m'
clear='\033[0m'

# Function to display a spinner
spinner() {
    local pid=$1
    local delay=0.75
    local spinstr='|/-\'
    while ps -p $pid > /dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Inform the user that updates are in progress
echo -e "${green}Updating system and installing dependencies...${clear}"

# Update system and install necessary dependencies
sudo apt-get update > /dev/null

# Install tmux with spinner
echo -ne "\rInstalling tmux "
(sudo apt-get install tmux > /dev/null 2>&1) &
spinner $!
echo ""

# Install build-essential with spinner
echo -ne "\rInstalling build-essential "
(sudo apt-get install build-essential -y > /dev/null 2>&1) &
spinner $!
echo ""

# Install make with spinner
echo -ne "\rInstalling make "
(sudo apt-get install make -y > /dev/null 2>&1) &
spinner $!
echo ""

echo "Installation completed successfully."

# Install python3 env with spinner
echo -ne "\rInstalling python3 env "
(sudo apt-get install python3-venv -y > /dev/null 2>&1) &
spinner $!
echo ""

echo "Installation completed successfully."

# Function to check if Go version 1.22 is installed
check_go_version() {
    if ! command -v go &> /dev/null; then
        echo -e "${green}Go is not installed. Installing Go version 1.22...${clear}"
        sudo snap install go --classic >/dev/null || { echo -e "${red}Failed to install Go. Returning to options menu.${clear}"; sleep 3; return; }
        echo -e "${green}Go version 1.22 has been installed.${clear}"
        sleep 3
    elif [[ "$(go version)" != *"1.22"* ]]; then
        echo -e "${green}Updating Go to version 1.22...${clear}"
        sudo snap refresh go --channel=1.22 >/dev/null || { echo -e "${red}Failed to update Go. Returning to options menu.${clear}"; sleep 3; return; }
        echo -e "${green}Go has been updated to version 1.22.${clear}"
        sleep 3
    else
        echo -e "${green}Go version 1.22 is already installed.${clear}"
        sleep 3
    fi
}

# Function to install NVIDIA driver 545
install_nvidia_driver() {
    if ! dpkg -l | grep -q "nvidia-driver-545"; then
        echo -e "${green}Installing NVIDIA driver 545... please wait.${clear}"
        sudo apt-get install nvidia-driver-545 -y >/dev/null || { echo -e "${red}Failed to install NVIDIA driver. Returning to options menu.${clear}"; sleep 3; return; }
        sleep 3  # Adding a delay before returning to the options menu
    else
        echo -e "${green}NVIDIA driver 545 is already installed.${clear}"
        sleep 3  # Adding a delay before returning to the options menu
    fi
}

# Function to install NVIDIA CUDA Toolkit
install_cuda_toolkit() {
    if ! dpkg -l | grep -q "nvidia-cuda-toolkit"; then
        echo -e "${green}Installing NVIDIA CUDA Toolkit... This may take some time depending on your download speed.${clear}"
        sudo apt-get install nvidia-cuda-toolkit -y >/dev/null || { echo -e "${red}Failed to install NVIDIA CUDA Toolkit. Returning to options menu.${clear}"; sleep 3; return; }
        sleep 3  # Adding a delay before returning to the options menu
    else
        echo -e "${green}NVIDIA CUDA Toolkit is already installed.${clear}"
        sleep 3  # Adding a delay before returning to the options menu
    fi
}

# Call function to check and install/update Go version
check_go_version
# Call function to install NVIDIA driver
install_nvidia_driver
# Call function to install NVIDIA CUDA Toolkit
install_cuda_toolkit

# Function to install the wallet
install_wallet() {
    # Check if the wallet has already been installed
    if [ ! -f "$HOME/go/bin/nimble-networkd" ]; then
        echo -e "${green}Cloning into wallet and compiling...${clear}"
        # Remove the directory if it exists
        if [ -d "$HOME/nimble/wallet-public" ]; then
            echo -e "${green}Removing existing wallet-public directory...${clear}"
            rm -rf "$HOME/nimble/wallet-public" || { echo -e "${red}Failed to remove existing directory. Returning to options menu.${clear}"; sleep 3; return; }
        fi
        # Git clone into wallet and compile
        mkdir -p "$HOME/nimble" && cd "$HOME/nimble" || { echo -e "${red}Failed to create directory. Returning to options menu.${clear}"; sleep 3; return; }
        git clone https://github.com/nimble-technology/wallet-public.git > /dev/null || { echo -e "${red}Failed to clone repository. Returning to options menu.${clear}"; sleep 3; return; }
        cd wallet-public || { echo -e "${red}Failed to change directory. Returning to options menu.${clear}"; sleep 3; return; }
        make install || { echo -e "${red}Failed to install wallet. Returning to options menu.${clear}"; sleep 3; return; }
    fi

    # Ask user to enter sub-wallet name
    cd "$HOME/go/bin" || { echo -e "${red}Failed to change directory. Returning to options menu.${clear}"; sleep 3; return; }
    echo -e "${green}Please enter a name for your wallet...${clear}"
    read -r varwallet
    ./nimble-networkd keys add "$varwallet"
    echo $'\r'
    echo -e $'\r'"${red}Please remember to save your wallet seed phrase and address!${clear}"
    echo $'\r'
    read -rp "Have you recorded your wallet seed phrase and address? (yes/no): " confirmation
    if [ "$confirmation" = "yes" ]; then
        echo -e "${green}You will be returned to the options menu shortly.${clear}"
        sleep 3
    else
        echo -e "${red}Please record your wallet seed phrase and address before continuing.${clear}"
        sleep 3
        return
    fi
}

# Function to install the miner
install_miner() {
    # Check if the miner has already been installed
    if [ ! -f "$HOME/go/bin/nimble-miner" ]; then
        echo -e "${green}Cloning into miner and compiling...${clear}"
        # Remove the directory if it exists
        if [ -d "$HOME/nimble/nimble-miner-public" ]; then
            echo -e "${green}Removing existing nimble-miner-public directory...${clear}"
            rm -rf "$HOME/nimble/nimble-miner-public" || { echo -e "${red}Failed to remove existing directory. Returning to options menu.${clear}"; sleep 3; return; }
        fi
        # Git clone into miner and compile
        mkdir -p "$HOME/nimble" && cd "$HOME/nimble" || { echo -e "${red}Failed to create directory. Returning to options menu.${clear}"; sleep 3; return; }
        git clone https://github.com/nimble-technology/nimble-miner-public.git > /dev/null || { echo -e "${red}Failed to clone repository. Returning to options menu.${clear}"; sleep 3; return; }
        cd nimble-miner-public || { echo -e "${red}Failed to change directory. Returning to options menu.${clear}"; sleep 3; return; }
        git pull || { echo -e "${red}Failed to pull changes. Returning to options menu.${clear}"; sleep 3; return; }
        make install || { echo -e "${red}Failed to install miner. Returning to options menu.${clear}"; sleep 3; return; }
        source ./nimenv_localminers/bin/activate
    fi

    # Ask user to enter a sub address to mine to
    echo -e "${green}Please enter a sub address to mine to....:${clear}"
    read -r varaddress

    # Start the miner
    tmux new-session -d -s Nimble "make run addr=$varaddress"
    echo $'\r'
    echo -e "${green}Miner has been started in a new Tmux window. Use the command tmux attach to view your mining progress${clear}"
    echo $'\r'
    echo -e "${green}Press any key to return to the options menu.${clear}"
    read -n 1 -s -r -p ""
}


# Function to run the wallet
run_wallet() {
    if [ ! -f "$HOME/go/bin/nimble-networkd" ]; then
        echo -e "${red}Please install the Wallet first!${clear}"
        sleep 3
        return
    else
        echo -e "${green}Running the wallet...${clear}"
        sleep 3
        cd "$HOME/go/bin" || { echo -e "${red}Failed to change directory. Returning to options menu.${clear}"; sleep 3; return; }
        echo -e "${green}Please enter a name for your wallet...${clear}"
        read -r varwallet
        ./nimble-networkd keys add "$varwallet"
        echo $'\r'
        echo -e $'\r'"${red}Please remember to save your wallet seed phrase and address!${clear}"
        echo $'\r'
        read -rp "Have you recorded your wallet seed phrase and address? (yes/no): " confirmation
        if [ "$confirmation" = "yes" ]; then
            echo -e "${green}You will be returned to the options menu shortly.${clear}"
            sleep 3
        else
            echo -e "${red}Please record your wallet seed phrase and address before continuing.${clear}"
            sleep 3
            return
        fi
    fi
}

# Function to run the miner
run_miner() {
    if [ ! -f "$HOME/nimble/nimble-miner-public/execute.py" ]; then
        echo -e "${red}Please install the Miner first!${clear}"
        sleep 3
        return
    else
        echo -e "${green}Please enter a sub address to mine to....:${clear}"
        read -r varaddress
        cd "$HOME/nimble/nimble-miner-public" || { echo -e "${red}Failed to change directory. Returning to options menu.${clear}"; sleep 3; return; }
        # Activate and Start the miner
        source ./nimenv_localminers/bin/activate || { echo -e "${red}Failed to activate environment. Returning to options menu.${clear}"; sleep 3; return; }
        tmux new-session -d -s Nimble "make run addr=$varaddress" || { echo -e "${red}Failed to start miner. Returning to options menu.${clear}"; sleep 3; return; }
        echo $'\r'
        echo -e "${green}Miner has been started in a new Tmux window. Use the command tmux attach to view mining progress${clear}"
        echo $'\r'
        echo -e "${green}Press CTRL+B then D on its own to exit the miner${clear}"
        echo $'\r'
        sleep 5
        echo -e "${green}You will be returned to the options menu shortly.${clear}"
        sleep 3
        return  # Exiting the function and returning to the options menu
    fi
}

# Function to check Master Wallet Balance
check_balance() {
    echo -e "${green}Please enter your Master Wallet Address:${clear}"
    read -r varmaster
    cd "$HOME/nimble/nimble-miner-public" || { echo -e "${red}Failed to change directory. Returning to options menu.${clear}"; sleep 3; return; }
    echo -e "${green}Your Current Nimble Balance is:${clear}"
    make check addr="$varmaster" || { echo -e "${red}Failed to check balance. Returning to options menu.${clear}"; sleep 3; return; }
    echo -e "${green}Press any key to return to the options menu...${clear}"
    read -n 1 -s -r -p "" # Wait for a single keypress
    # Return to the options menu
}

# Main script modification
while true; do
    OPTION=$(whiptail --title "Nimble Network" --menu "Choose an option" 15 65 6 \
        "1" "Install Nimble Wallet" \
        "2" "Install Nimble Miner" \
        "3" "Run the Wallet if already installed" \
        "4" "Run the Miner if already installed" \
	"5" "Check your Master Wallet Balance (miner must be installed)" \
        "6" "Exit" 3>&1 1>&2 2>&3)

    case $OPTION in
        1) install_wallet ;;
        2) install_miner ;;
        3) run_wallet ;;
        4) run_miner ;;
	5) check_balance ;;
        6) break ;;
        *) echo -e "${red}Invalid option, please try again.${clear}" ;;
    esac
done
