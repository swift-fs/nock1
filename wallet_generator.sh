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
