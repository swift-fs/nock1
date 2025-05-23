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
🚀 NOCKCHAIN NODE LAUNCHER
---------------------------------------${NC}"
#!/bin/bash

set -e

# ========== COLOR CODES ==========
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

# ========== PATHS ==========
BINARY_PATH="$HOME/nockchain/target/release/nockchain"
LOG_PATH="$HOME/nockchain/build.log"
# --- Root setup ---
if [ "$(id -u)" -eq 0 ]; then
  echo -e "\e[33m>> Running as root. Updating system and installing sudo...\e[0m"
  apt-get update && apt-get upgrade -y

  if ! command -v sudo &> /dev/null; then
    apt-get install sudo -y
  fi
fi

if [ ! -f "$BINARY_PATH" ]; then
    echo -e "${YELLOW}>> Nockchain not built yet. Starting Phase 1 (Build)...${RESET}"

    echo -e "${CYAN}>> Installing system dependencies...${RESET}"
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libclang-dev llvm-dev

    if ! command -v cargo &> /dev/null; then
        echo -e "${CYAN}>> Installing Rust...${RESET}"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi

    echo -e "${CYAN}>> Cloning Nockchain repo and starting build...${RESET}"
    rm -rf nockchain .nockapp
    git clone https://github.com/zorp-corp/nockchain
    cd nockchain
    cp .env_example .env

    echo -e "${CYAN}>> Launching build in screen session 'nockbuild' and logging to build.log...${RESET}"
    screen -dmS nockbuild bash -c "cd \$HOME/nockchain && make install-hoonc && make build && make install-nockchain-wallet && make install-nockchain | tee build.log"

    echo -e "${GREEN}>> Build started in screen session 'nockbuild'.${RESET}"
    echo -e "${YELLOW}>> To monitor build: screen -r nockbuild${RESET}"
    echo -e "${YELLOW}>> Re-run this script when build completes.${RESET}"
    exit 0
fi

# ========== PHASE 2: VERIFY BUILD ==========
if [ -f "$BINARY_PATH" ]; then
    echo -e "${GREEN}>> Build detected. Continuing Phase 2 (Wallet + Miner Setup)...${RESET}"
else
    echo -e "${RED}!! ERROR: Build not completed or failed.${RESET}"
    echo -e "${YELLOW}>> Check build log: $LOG_PATH${RESET}"
    echo -e "${YELLOW}>> Resume screen: screen -r nockbuild${RESET}"
    exit 1
fi

cd "$HOME/nockchain"
export PATH="$PATH:$(pwd)/target/release"
echo "export PATH=\"\$PATH:$(pwd)/target/release\"" >> ~/.bashrc

# ========== WALLET ==========
echo -e "${YELLOW}\nDo you want to import an existing wallet? (y/n)${RESET}"
read -rp "> " use_existing

if [[ "$use_existing" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Place 'keys.export' in this directory and press Enter to import.${RESET}"
    read -rp "Continue when ready..."
    nockchain-wallet import-keys --input keys.export
else
    echo -e "${CYAN}>> Generating new wallet...${RESET}"
    nockchain-wallet keygen
    echo -e "${CYAN}>> Backing up keys to 'keys.export'...${RESET}"
    nockchain-wallet export-keys
fi

# ========== PUBLIC KEY ==========
echo -e "${YELLOW}Enter your PUBLIC KEY to use for mining:${RESET}"
read -rp "> " MINING_KEY

if [[ -z "$MINING_KEY" ]]; then
    echo -e "${RED}!! ERROR: Public key cannot be empty.${RESET}"
    exit 1
fi

# Update .env
sed -i "s/^MINING_PUBKEY=.*/MINING_PUBKEY=$MINING_KEY/" .env

# ========== FIREWALL ==========
echo -e "${CYAN}>> Configuring firewall...${RESET}"
sudo ufw allow ssh
sudo ufw allow 22
sudo ufw allow 3005/tcp
sudo ufw allow 3006/tcp
sudo ufw allow 3005/udp
sudo ufw allow 3006/udp
sudo ufw --force enable

# Automatically run miner1 in a screen session with full config
cd ~/nockchain
mkdir -p miner1 && cd miner1
screen -dmS miner1 bash -c "RUST_LOG=info,nockchain=info,nockchain_libp2p_io=info,libp2p=info,libp2p_quic=info \
MINIMAL_LOG_FORMAT=true \
nockchain --mining-pubkey $MINING_KEY --mine"

# Prompt for multiple miners
read -rp "$(echo -e '\e[33mDo you want to run multiple miners? Enter number (e.g. 3 for 3 miners total), or 1 to skip: \e[0m')" NUM_MINERS
if [[ "$NUM_MINERS" =~ ^[2-9][0-9]*$ ]]; then
  for i in $(seq 2 "$NUM_MINERS"); do
    mkdir -p ~/nockchain/miner$i
    screen -dmS miner$i bash -c "cd ~/nockchain/miner$i && \
RUST_LOG=info,nockchain=info,nockchain_libp2p_io=info,libp2p=info,libp2p_quic=info \
MINIMAL_LOG_FORMAT=true \
nockchain --mining-pubkey $MINING_KEY --mine"
    echo -e "\e[32m>> Miner $i started in screen session 'miner$i'.\e[0m"
  done
else
  echo -e "\e[36m>> Skipping additional miners.\e[0m"
fi

