<p align="center">
  <h1 align="center">FairCoin Core</h1>
  <p align="center">
    A decentralized cryptocurrency with Masternodes, Coin Mixing, and PoW/PoS hybrid consensus.
    <br />
    <a href="https://fairco.in">Website</a>
    &middot;
    <a href="https://github.com/FairCoinOfficial/Explorer">Block Explorer</a>
    &middot;
    <a href="https://github.com/FairCoinOfficial/FairCoin/releases">Downloads</a>
  </p>
</p>

---

## Features

- **Masternodes** &mdash; Decentralized network nodes secured with 5,000 FAIR collateral
- **Coin Mixing** &mdash; Privacy-focused anonymized transactions
- **FastSend** &mdash; Guaranteed zero-confirmation transactions
- **Staking** &mdash; Earn rewards by holding FAIR in your wallet
- **Halving Schedule** &mdash; Deflationary block rewards that halve every ~2 years

## Coin Specifications

| | |
|---|---|
| **Ticker** | FAIR |
| **Algorithm** | Quark |
| **Consensus** | PoW + PoS Hybrid |
| **Block Time** | 120 seconds |
| **Max Supply** | 33,000,000 FAIR |
| **Premine** | 5,000,000 FAIR (block 1) |
| **Masternode Collateral** | 5,000 FAIR |
| **Stake Min Age** | 2 hours |
| **Address Prefix** | `F` (mainnet) / `T` (testnet) |

### Block Rewards

| Phase | Blocks | Reward | Duration |
|---|---|---|---|
| Premine | 1 | 5,000,000 FAIR | Instant |
| PoW Mining | 2 &ndash; 10,000 | 10 FAIR | ~14 days |
| PoS Staking | 10,001 &ndash; 525,599 | 10 FAIR | ~2 years |
| 1st Halving | 525,600 &ndash; 1,051,199 | 5 FAIR | ~2 years |
| 2nd Halving | 1,051,200 &ndash; 1,576,799 | 2.5 FAIR | ~2 years |
| 3rd+ Halving | 1,576,800+ | 1.25 FAIR (min) | Permanent |

### Network

| | Mainnet | Testnet |
|---|---|---|
| **P2P Port** | 46372 | 46374 |
| **RPC Port** | 46373 | 46375 |

---

## Quick Start

### First-Time Setup (new network)

```bash
git clone https://github.com/FairCoinOfficial/FairCoin.git
cd FairCoin
chmod +x genesis-mine.sh
./genesis-mine.sh
```

This script automatically installs dependencies, mines the genesis blocks, patches the source code, and compiles everything.

> After running, generate your cryptographic keys following [doc/GENERATE-KEYS.md](doc/GENERATE-KEYS.md), then recompile.

### Building from Source

```bash
# Install dependencies (Ubuntu/Debian)
sudo apt-get install build-essential libtool autotools-dev autoconf pkg-config \
    libssl-dev libboost-all-dev libdb4.8-dev libdb4.8++-dev \
    libminiupnpc-dev libzmq3-dev

# For Qt GUI (optional)
sudo apt-get install libqt5gui5 libqt5core5a libqt5dbus5 \
    qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler

# Compile
./autogen.sh
./configure
make -j$(nproc)
```

### Running

```bash
# Start daemon
./src/faircoind -daemon

# Start daemon with mining (PoW phase only)
./src/faircoind -daemon -gen=1

# Check status
./src/faircoin-cli getinfo

# Stop
./src/faircoin-cli stop
```

---

## Masternode Setup

1. Send **exactly 5,000 FAIR** to a new address in your wallet
2. Wait for 15 confirmations
3. In Debug Console: `masternode genkey` (save the output)
4. In Debug Console: `masternode outputs` (save txid and index)
5. Edit `~/.faircoin/masternode.conf`:
   ```
   mn1 YOUR_IP:46372 YOUR_MASTERNODE_KEY YOUR_TXID OUTPUT_INDEX
   ```
6. Restart wallet and click **Start Alias** in the Masternodes tab

See [Masternode Guide](doc/guide-startmany.md) and [Windows Guide](doc/windows_masternode_guide.md) for detailed instructions.

---

## Documentation

| Topic | Link |
|---|---|
| Build on Linux | [doc/build-unix.md](doc/build-unix.md) |
| Build on macOS | [doc/build-osx.md](doc/build-osx.md) |
| Build on Windows | [doc/README_windows.md](doc/README_windows.md) |
| Generate Keys | [doc/GENERATE-KEYS.md](doc/GENERATE-KEYS.md) |
| Masternode Config | [doc/masternode_conf.md](doc/masternode_conf.md) |
| Masternode Multi-Setup | [doc/guide-startmany.md](doc/guide-startmany.md) |
| Tor Setup | [doc/tor.md](doc/tor.md) |
| Developer Notes | [doc/developer-notes.md](doc/developer-notes.md) |
| Release Notes | [doc/release-notes.md](doc/release-notes.md) |

---

## License

FairCoin Core is released under the terms of the MIT license. See [COPYING](COPYING) for more information.
