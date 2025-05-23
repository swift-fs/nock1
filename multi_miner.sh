#!/bin/bash

set -e

CYAN="\e[36m"
YELLOW="\e[33m"
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

NCK_DIR="$HOME/nockchain"
NCK_BIN="$NCK_DIR/target/release/nockchain"

# Check if nockchain build exists
if [ ! -f "$NCK_BIN" ]; then
    echo -e "${RED}!! Nockchain is not built yet.${RESET}"
    echo -e "${YELLOW}>> Please run the main launcher script first to build nockchain.${RESET}"
    echo -e "Example: bash nockchain_miner_setup.sh"
    exit 1
fi

cd "$NCK_DIR"

# Extract public key from .env
if [ ! -f .env ]; then
    echo -e "${RED}!! .env file not found in $NCK_DIR. Please run the setup script first.${RESET}"
    exit 1
fi

MINING_KEY=$(grep '^MINING_PUBKEY=' .env | cut -d '=' -f2)

if [[ -z "$MINING_KEY" ]]; then
    echo -e "${RED}!! ERROR: Public key not found in .env file.${RESET}"
    exit 1
fi

echo -e "${GREEN}>> Using public key from .env: $MINING_KEY${RESET}"

# Close existing 'miner' screen if it exists
if screen -list | grep -q "miner"; then
    echo -e "${YELLOW}>> Closing existing 'miner' screen session...${RESET}"
    screen -XS miner quit
fi

# Setup miner1 directory and screen
echo -e "${CYAN}>> Setting up miner1...${RESET}"
mkdir -p miner1 && cd miner1
sudo sysctl -w vm.overcommit_memory=1
screen -dmS miner1 bash -c "cd $NCK_DIR/miner1 && \
RUST_LOG=info,nockchain=info,nockchain_libp2p_io=info,libp2p=info,libp2p_quic=info \\
MINIMAL_LOG_FORMAT=true \\
$NCK_BIN --mining-pubkey $MINING_KEY --mine"

echo -e "${GREEN}>> Miner 1 started in screen session 'miner1'.${RESET}"

# Ask to start more miners
echo -e "${YELLOW}Do you want to run multiple miners? Enter number (e.g. 3 for 3 miners total), or 1 to skip:${RESET}"
read -rp "> " NUM_MINERS

if [[ "$NUM_MINERS" =~ ^[2-9][0-9]*$ ]]; then
    for i in $(seq 2 "$NUM_MINERS"); do
        MINER_DIR="$NCK_DIR/miner$i"
        echo -e "${CYAN}>> Setting up miner$i...${RESET}"
        mkdir -p "$MINER_DIR"
        screen -dmS miner$i bash -c "cd $MINER_DIR && \
RUST_LOG=info,nockchain=info,nockchain_libp2p_io=info,libp2p=info,libp2p_quic=info \\
MINIMAL_LOG_FORMAT=true \\
$NCK_BIN --mining-pubkey $MINING_KEY --mine"
        echo -e "${GREEN}>> Miner $i started in screen session 'miner$i'.${RESET}"
    done
else
    echo -e "${CYAN}>> Skipping multiple miners setup.${RESET}"
fi

echo -e "${YELLOW}To view a miner screen: screen -r miner1, miner2, ...${RESET}"
echo -e "${YELLOW}To detach: Ctrl + A + D${RESET}"
echo -e "${GREEN}All requested miners are now running.${RESET}"
