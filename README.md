FairCoin Core v3.0.0
=====================================

FairCoin is a cryptocurrency with Masternodes, Coin Mixing for privacy, and a hybrid PoW/PoS consensus.

- **Coin Mixing** - Anonymized transactions using obfuscation technology
- **FastSend** - Zero confirmation guaranteed transactions
- **Masternodes** - Decentralized network secured with 5,000 FAIR collateral
- **Staking** - Earn rewards by holding FAIR in your wallet

More information at [fairco.in](https://fairco.in)

### Coin Specs

| Parameter | Value |
|---|---|
| Ticker | FAIR |
| Algorithm | Quark |
| Consensus | PoW + PoS Hybrid |
| Block Time | 120 seconds |
| Max Supply | 33,000,000 FAIR |
| Premine | 5,000,000 FAIR (15.15%) |
| Block Reward | 10 FAIR (halving every ~2 years) |
| Min Block Reward | 1.25 FAIR |
| Masternode Collateral | 5,000 FAIR |
| Stake Min Age | 2 hours |

### Block Reward Schedule

| Halving | Block Range | Reward |
|---|---|---|
| 0 | 1 - 525,599 | 10 FAIR |
| 1 | 525,600 - 1,051,199 | 5 FAIR |
| 2 | 1,051,200 - 1,576,799 | 2.5 FAIR |
| 3+ | 1,576,800+ | 1.25 FAIR (minimum) |

### Network Phases

| Phase | Blocks | Duration |
|---|---|---|
| PoW (mining) | 1 - 10,000 | ~14 days |
| PoS (staking) | 10,001+ | Permanent |

### Network Ports

| Network | P2P Port | RPC Port |
|---|---|---|
| Mainnet | 46372 | 46373 |
| Testnet | 46374 | 46375 |

### Address Prefixes

| Network | Prefix | Example |
|---|---|---|
| Mainnet | F | F... |
| Testnet | T | T... |

## Building from Source

### Dependencies (Ubuntu/Debian)

```bash
sudo apt-get install build-essential libtool autotools-dev autoconf pkg-config libssl-dev
sudo apt-get install libboost-all-dev libdb4.8-dev libdb4.8++-dev
sudo apt-get install libminiupnpc-dev libzmq3-dev
# For GUI: sudo apt-get install libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler
```

### Compile

```bash
./autogen.sh
./configure
make -j$(nproc)
```

Binaries will be in `src/`:
- `faircoind` - Daemon
- `faircoin-cli` - Command-line client
- `faircoin-qt` - GUI wallet (if Qt dependencies installed)

### First Launch

If this is a brand new network, run the genesis mining script first:

```bash
./genesis-mine.sh
```

This finds the correct nonce for the genesis block. See [doc/GENERATE-KEYS.md](doc/GENERATE-KEYS.md) for key generation.

## Running

```bash
# Start daemon
./src/faircoind -daemon

# Check status
./src/faircoin-cli getinfo

# Start mining (PoW phase only)
./src/faircoind -daemon -gen=1

# Stop
./src/faircoin-cli stop
```

## Masternode Setup

1. Send exactly 5,000 FAIR to a new address in your wallet
2. Get the transaction ID and output index
3. Edit `~/.faircoin/masternode.conf`
4. See [doc/guide-startmany.md](doc/guide-startmany.md) for detailed instructions

## Documentation

- [Build on Unix](doc/build-unix.md)
- [Build on macOS](doc/build-osx.md)
- [Build on Windows](doc/README_windows.txt)
- [Generate Cryptographic Keys](doc/GENERATE-KEYS.md)
- [Masternode Budget](doc/masternode-budget.md)
- [Developer Notes](doc/developer-notes.md)

## License

FairCoin Core is released under the terms of the MIT license.
See [COPYING](COPYING) for more information.
