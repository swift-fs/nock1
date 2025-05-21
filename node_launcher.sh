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
# Ensure nockchain is built
if [ ! -f ".nockbuild_done" ]; then
  echo -e "${YELLOW}Running build in screen...${NC}"
  screen -dmS nockbuild bash -c "cd nockchain && make build-hoon-all && make install-nockchain && make install-nockchain-wallet && touch ../.nockbuild_done; exec bash"
  echo -e "${CYAN}⏳ Build running: screen -r nockbuild"
  echo "Rerun this script once build is complete."
  exit 0
fi

cd nockchain

# Prompt for public key
echo -e "${CYAN}Enter your Public Key:${NC}"
read -rp "> " public_key

# Insert public key into Makefile
sed -i "s/^MINING_PUBKEY *=.*/MINING_PUBKEY = $public_key/" Makefile

# Prompt for custom ports
echo -e "${CYAN}Customize ports? (default 3005/3006)? [y/N]${NC}"
read -rp "> " ports
if [[ "$ports" =~ ^[Yy]$ ]]; then
  read -rp "P2P Port [default: 3005]: " port1
  read -rp "API Port [default: 3006]: " port2
  port1=${port1:-3005}
  port2=${port2:-3006}
  sed -i "s/3005/$port1/g" Makefile
  sed -i "s/3006/$port2/g" Makefile
  echo -e "${GREEN}✔ Ports set: $port1 / $port2${NC}"
fi

# Launch nodes in screen
echo -e "${CYAN}Launching leader & follower in screen...${NC}"
screen -dmS leader bash -c "cd $(pwd); make run-nockchain-leader"
screen -dmS follower bash -c "cd $(pwd); make run-nockchain-follower"

echo -e "${GREEN}
✅ Nodes are live!

To view logs:
  screen -r leader
  screen -r follower

To stop:
  screen -XS leader quit
  screen -XS follower quit
${NC}"
