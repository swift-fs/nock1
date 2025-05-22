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

# ========== PHASE 1: BUILD ==========
if [ ! -f "$BINARY_PATH" ]; then
    echo -e "${YELLOW}>> Nockchain not built yet. Starting Phase 1 (Build)...${RESET}"

    echo -e "${CYAN}>> Installing system dependencies...${RESET}"
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt install -y curl ufw sudo screen iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libclang-dev llvm-dev

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
sudo ufw allow 3007/tcp
sudo ufw allow 3006/udp
sudo ufw allow 3005/udp
sudo ufw allow 3007/udp
sudo ufw --force enable

# ========== START MINER ==========
echo -e "${CYAN}>> Starting miner in screen session 'miner'...${RESET}"
screen -dmS miner bash -c "nockchain --mining-pubkey $MINING_KEY --mine \
  --peer /ip4/95.216.102.60/udp/3006/quic-v1 \
  --peer /ip4/65.108.123.225/udp/3006/quic-v1 \
  --peer /ip4/65.109.156.108/udp/3006/quic-v1 \
  --peer /ip4/65.21.67.175/udp/3006/quic-v1 \
  --peer /ip4/65.109.156.172/udp/3006/quic-v1 \
  --peer /ip4/34.174.22.166/udp/3006/quic-v1 \
  --peer /ip4/34.95.155.151/udp/30000/quic-v1 \
  --peer /ip4/34.18.98.38/udp/30000/quic-v1"

echo -e "${GREEN}>> Miner is now running in screen 'miner'!${RESET}"
echo -e "${YELLOW}To view it: screen -r miner${RESET}"
echo -e "${YELLOW}To list all screens: screen -ls${RESET}"
