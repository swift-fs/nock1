#!/bin/bash

set -e

CYAN="\e[36m"
YELLOW="\e[33m"
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"
echo -e "${CYAN}
 
 ______              _         _                                             
|  ___ \            | |       | |                   _                        
| |   | |  ___    _ | |  ____ | | _   _   _  ____  | |_   ____   ____  _____ 
| |   | | / _ \  / || | / _  )| || \ | | | ||  _ \ |  _) / _  ) / ___)(___  )
| |   | || |_| |( (_| |( (/ / | | | || |_| || | | || |__( (/ / | |     / __/ 
|_|   |_| \___/  \____| \____)|_| |_| \____||_| |_| \___)\____)|_|    (_____)                   
                                
                                                                                                                                
${YELLOW}                      :: Powered by Noderhunterz ::
${NC}"
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

# Ask user which mode to run miner1 in
echo -e "${YELLOW}Choose how to run miner1:
1) Without peers
2) With recommended peers${RESET}"
read -rp "Enter 1 or 2: " MINER_MODE

mkdir -p miner1 && cd miner1
sudo sysctl -w vm.overcommit_memory=1
export PATH="$HOME/.cargo/bin:$PATH"

if [[ "$MINER_MODE" == "1" ]]; then
  screen -dmS miner1 bash -c "RUST_LOG=info,nockchain=info,nockchain_libp2p_io=info,libp2p=info,libp2p_quic=info \\
  MINIMAL_LOG_FORMAT=true \\
  $NCK_BIN --mining-pubkey $MINING_KEY --mine"
  echo -e "${GREEN}>> Miner1 started without peers in screen session 'miner1'.${RESET}"

elif [[ "$MINER_MODE" == "2" ]]; then
  screen -dmS miner1 bash -c "RUST_LOG=info,nockchain=info,nockchain_libp2p_io=info,libp2p=info,libp2p_quic=info \\
  MINIMAL_LOG_FORMAT=true \\
  $NCK_BIN --mine \\
  --mining-pubkey $MINING_KEY \\
  --peer /ip4/95.216.102.60/udp/3006/quic-v1 \\
  --peer /ip4/65.108.123.225/udp/3006/quic-v1 \\
  --peer /ip4/65.109.156.108/udp/3006/quic-v1 \\
  --peer /ip4/65.21.67.175/udp/3006/quic-v1 \\
  --peer /ip4/65.109.156.172/udp/3006/quic-v1 \\
  --peer /ip4/34.174.22.166/udp/3006/quic-v1 \\
  --peer /ip4/34.95.155.151/udp/30000/quic-v1 \\
  --peer /ip4/34.18.98.38/udp/30000/quic-v1 \\
  --peer /ip4/96.230.252.205/udp/3006/quic-v1 \\
  --peer /ip4/94.205.40.29/udp/3006/quic-v1 \\
  --peer /ip4/159.112.204.186/udp/3006/quic-v1 \\
  --peer /ip4/217.14.223.78/udp/3006/quic-v1"
  echo -e "${GREEN}>> Miner1 started with peers in screen session 'miner1'.${RESET}"
else
  echo -e "${RED}Invalid choice. Exiting...${RESET}"
  exit 1
fi

# Screen usage instructions
echo -e "${CYAN}To view a miner screen: screen -r miner1, miner2, ...${RESET}"
echo -e "${CYAN}To detach from screen: Ctrl + A then D${RESET}"
echo -e "${CYAN}To list all screens: screen -ls${RESET}"

# Ask to start more miners
echo -e "${YELLOW}Do you want to run multiple miners? Enter number (e.g. 3 for 3 miners total), or 1 to skip:${RESET}"
read -rp "> " NUM_MINERS

if [[ "$NUM_MINERS" =~ ^[2-9][0-9]*$ ]]; then
    for i in $(seq 2 "$NUM_MINERS"); do
        MINER_DIR="$NCK_DIR/miner$i"
        echo -e "${CYAN}>> Setting up miner$i...${RESET}"
        mkdir -p "$MINER_DIR"
        screen -dmS miner$i bash -c "cd $MINER_DIR && \\
RUST_LOG=info,nockchain=info,nockchain_libp2p_io=info,libp2p=info,libp2p_quic=info \\
MINIMAL_LOG_FORMAT=true \\
$NCK_BIN --mining-pubkey $MINING_KEY --mine"
        echo -e "${GREEN}>> Miner $i started in screen session 'miner$i'.${RESET}"
    done
else
    echo -e "${CYAN}>> Skipping multiple miners setup.${RESET}"
fi

echo -e "${GREEN}All requested miners are now running.${RESET}"
