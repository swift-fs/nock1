#!/bin/bash
set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'


echo -e "${CYAN}
 
 ______              _         _                                             
|  ___ \            | |       | |                   _                        
| |   | |  ___    _ | |  ____ | | _   _   _  ____  | |_   ____   ____  _____ 
| |   | | / _ \  / || | / _  )| || \ | | | ||  _ \ |  _) / _  ) / ___)(___  )
| |   | || |_| |( (_| |( (/ / | | | || |_| || | | || |__( (/ / | |     / __/ 
|_|   |_| \___/  \____| \____)|_| |_| \____||_| |_| \___)\____)|_|    (_____)                   
                                
                                                                                                                                
${YELLOW}                      :: Powered by Noderhunterz ::
${NC}"

echo -e "${CYAN}
🔑 NOCKCHAIN WALLET GENERATOR
---------------------------------------${NC}"
sleep 1

# Rust check
if ! command -v cargo &>/dev/null; then
  echo -e "${YELLOW}Installing Rust...${NC}"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y > /dev/null 2>&1
  source "$HOME/.cargo/env"
else
  echo -e "${GREEN}Rust already installed.${NC}"
fi

# Docker check
if ! command -v docker &>/dev/null; then
  echo -e "${YELLOW}Installing Docker...${NC}"
  sudo apt-get -qq remove docker.io docker-doc docker-compose podman-docker containerd runc > /dev/null 2>&1
  sudo apt-get -qq update > /dev/null
  sudo apt-get -qq install -y ca-certificates curl gnupg lsb-release > /dev/null
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg > /dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get -qq update > /dev/null
  sudo apt-get -qq install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null
  sudo systemctl enable docker > /dev/null
  sudo systemctl restart docker
else
  echo -e "${GREEN}Docker already installed.${NC}"
fi

# System dependencies
echo -e "${CYAN}Installing dependencies...${NC}"
sudo apt-get -qq update > /dev/null
sudo apt-get -qq install -y curl iptables build-essential git wget lz4 jq make gcc nano \
  automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev \
  tar clang bsdmainutils ncdu unzip screen > /dev/null


# Clone Nockchain repo if not present
if [ ! -d "nockchain" ]; then
  echo -e "${CYAN}Cloning Nockchain repo...${NC}"
  git clone https://github.com/zorp-corp/nockchain > /dev/null 2>&1
fi

# Ensure nockchain is built
if [ ! -f ".nockbuild_done" ]; then
  echo -e "${YELLOW}Running build in screen...${NC}"
  screen -dmS nockbuild bash -c "cd nockchain && make build-hoon-all && make install-nockchain && make install-nockchain-wallet && touch ../.nockbuild_done; exec bash"
  echo -e "${CYAN}⏳ Build running: screen -r nockbuild"
  echo "Rerun this script once build is complete."
  exit 0
fi

cd nockchain

# Use script to capture full wallet output
echo -e "${CYAN}Generating wallet...${NC}"
script -q -c "nockchain-wallet keygen"
sleep 2
