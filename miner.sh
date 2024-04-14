#!/bin/bash

# Set the color variable
green='\033[0;32m'

# Clear the color after that
clear='\033[0m'

# Update system and install Go

sudo apt update
sudo apt install tmux -y && sudo apt install build-essential -y && sudo apt install make -y
wget https://go.dev/dl/go1.22.1.linux-amd64.tar.gz
sudo su -c "rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.1.linux-amd64.tar.gz"
export PATH=$PATH:/usr/local/go/bin

# Install python3 environment

sudo apt install python3-venv -y

# Clone into miner and compile

mkdir $HOME/nimble && cd $HOME/nimble
git clone https://github.com/nimble-technology/nimble-miner-public.git
cd nimble-miner-public

# Update git files and install miner

git pull
make install

# Activate the miner

source ./nimenv_localminers/bin/activate

echo -e "${green}Please enter a sub address to mine to....:${clear}"

read varaddress

tmux new-session -d -s Nimble "make run addr=$varaddress"

echo $'\r'

echo -e "${green}Miner has been started in a new Tmux window. Use the commmand tmux attach to view your mining progress${clear}"

echo $'\r'

echo -e "${green}Press CTRL+B then D on it's own to exit the miner${clear}"

echo $'\r'
