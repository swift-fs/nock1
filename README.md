# Nockchain Wallet & Node Launcher

Easy scripts to build, generate wallets, and launch Nockchain nodes.

---

## Features

- **Wallet Generator**  
  Builds Nockchain if not already built, then generates a new wallet with keys and memo.

- **Node Launcher**  
  Loads wallet keys, allows port customization, updates Makefile, and launches leader & follower nodes in detached `screen` sessions.

---

## Hardware Requirements

> Hardware requirements are highly speculative since mainnet launch details are not finalized.

| RAM      | CPU              | Disk           |
|----------|------------------|----------------|
| 64 GB    | 6 cores or higher | 100-200 GB SSD |

- More CPU cores = higher hashrate = better mining chances  
- These specs are for testnet; mainnet requirements may vary.

---

## Prerequisites

- Linux/macOS with:
  - `screen` installed
  - `make` and build tools
  - `bash`

---

## Usage

## Quick Start

```bash
sudo apt-get -qq update && sudo apt-get upgrade -y
sudo apt -qq install git -y
```

### 1. Generate Wallet
Clone the repository:

```bash
git clone https://github.com/CodeDialect/nockchain.git
cd nockchain/

```
Run the wallet generator script:

```bash
chmod +x wallet-generator.sh
./wallet-generator.sh
```

- If this is your first run, it will build Nockchain in a detached `screen` session.
- Rerun after build completes to generate wallet keys.

### 2. Launch Nodes

Run the node launcher script:

```bash
chmod +x node-launcher.sh
./node-launcher.sh
```

- Enter a public key.
- Optionally customize P2P and API ports (default 3005/3006).
- Launches leader and follower nodes in detached `screen` sessions.

---

## Open Ports & Firewall Setup

To allow the necessary network ports for Nockchain nodes and SSH access, you can use `ufw` (Uncomplicated Firewall):

```bash
# Allow SSH access
sudo ufw allow ssh
sudo ufw allow 22

# Enable the firewall
sudo ufw enable

# Open Nockchain node ports (default)
sudo ufw allow 3005/tcp
sudo ufw allow 3006/tcp
sudo ufw reload
```

Make sure these ports match those you set when launching the node (defaults: `3005` for P2P, `3006` for API).

---

## Useful Commands

### Wallet Commands

> **Important:** After every terminal restart, run these commands before using wallet commands to avoid `command not found` errors:

```bash
cd nockchain
export PATH="$PATH:$(pwd)/target/release"
```

- **General wallet command:**

```bash
nockchain-wallet --nockchain-socket ./test-leader/nockchain.sock
```

- **Check wallet balance:**

```bash
nockchain-wallet --nockchain-socket ./test-leader/nockchain.sock balance
```

> Note: The `~` symbol in balance output represents zero, and balance will be zero until you mine a block.

---

### Screen Commands

> To avoid overlapping screens, minimize or close your current screen before switching.

- Reattach leader logs screen:

```bash
screen -r leader
```

- Reattach follower logs screen:

```bash
screen -r follower
```

- Minimize (detach) current screen session:

```
CTRL + A, then D
```

- List all screen sessions:

```bash
screen -ls
```

- Stop node inside a screen (graceful shutdown):

```
CTRL + C
```

- Kill and remove a screen session (replace `NAME` with session name):

```bash
screen -XS NAME quit
```

---

## Contributing

Contributions, issues, and feature requests are welcome!  
Feel free to fork and submit pull requests.
Discord: https://discord.gg/4w7cRka4

---

*Happy mining with Nockchain!* 
