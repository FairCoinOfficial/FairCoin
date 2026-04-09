# How to Generate Cryptographic Keys for FairCoin

This guide explains how to generate the cryptographic key pairs needed before launching
the FairCoin network. **Do this on a secure computer you trust.**

## Prerequisites

```bash
sudo apt-get install openssl python3
```

## Keys You Need

You need **3 key pairs** for mainnet:

| Key | Purpose |
|---|---|
| **Alert Key** | Broadcast emergency alerts to all nodes |
| **Spork Key** | Enable/disable features remotely (sporks) |
| **Genesis Key** | Signs the genesis block coinbase output |

> **Important**: In FairCoin, the premine (5,000,000 FAIR) is paid in **block 1**, not block 0.
> This means **anyone who mines block 1 receives the premine** automatically to their wallet.
> The genesis key is only used to sign the unspendable genesis coinbase, not to receive funds.

## Step 1: Generate All 3 Key Pairs

```bash
mkdir -p ~/MIS_CLAVES_FAIRCOIN

openssl ecparam -genkey -name secp256k1 | openssl ec -text -noout 2>/dev/null > ~/MIS_CLAVES_FAIRCOIN/alert_key.txt
openssl ecparam -genkey -name secp256k1 | openssl ec -text -noout 2>/dev/null > ~/MIS_CLAVES_FAIRCOIN/spork_key.txt
openssl ecparam -genkey -name secp256k1 | openssl ec -text -noout 2>/dev/null > ~/MIS_CLAVES_FAIRCOIN/genesis_key.txt
```

## Step 2: Extract Public Keys

```bash
echo "=== ALERT ==="
grep -A 5 "pub:" ~/MIS_CLAVES_FAIRCOIN/alert_key.txt | tail -n +2 | tr -d ' :\n' | head -c 130
echo ""
echo "=== SPORK ==="
grep -A 5 "pub:" ~/MIS_CLAVES_FAIRCOIN/spork_key.txt | tail -n +2 | tr -d ' :\n' | head -c 130
echo ""
echo "=== GENESIS ==="
grep -A 5 "pub:" ~/MIS_CLAVES_FAIRCOIN/genesis_key.txt | tail -n +2 | tr -d ' :\n' | head -c 130
echo ""
```

Each output is a 130-character hex string starting with `04`. These are your public keys.

## Step 3: Put Public Keys in the Code

Edit `src/chainparams.cpp` and replace these 3 lines in the `CMainParams` class:

```cpp
// Line ~375 - Alert Key
vAlertPubKey = ParseHex("YOUR_ALERT_PUBLIC_KEY");

// Line ~398 - Genesis Key (signs coinbase)
txNew.vout[0].scriptPubKey = CScript() << ParseHex("YOUR_GENESIS_PUBLIC_KEY") << OP_CHECKSIG;

// Line ~437 - Spork Key
strSporkKey = "YOUR_SPORK_PUBLIC_KEY";
```

Do the same for the `CTestNetParams` class (testnet) if you want. You can reuse the same
keys for mainnet and testnet, or generate separate ones.

## Step 4: Re-mine the Genesis Block

Changing the genesis public key changes the merkle root, which invalidates the old nonce
and hash. You need to mine new genesis blocks.

Temporarily replace the 3 assert lines in chainparams.cpp (for mainnet, testnet, regtest)
with mining code:

```cpp
genesis.nNonce = 0;
hashGenesisBlock = genesis.GetHash();
{
    uint256 hashTarget = CBigNum().SetCompact(genesis.nBits).getuint256();
    while (hashGenesisBlock > hashTarget) {
        ++genesis.nNonce;
        hashGenesisBlock = genesis.GetHash();
    }
    printf("nonce=%u hash=%s merkle=%s\n",
        genesis.nNonce, hashGenesisBlock.ToString().c_str(),
        genesis.hashMerkleRoot.ToString().c_str());
}
```

Then:

```bash
touch src/chainparams.cpp
make -j$(nproc)
./src/faircoind
```

It will print the new nonce, hash, and merkle root. Copy those values and replace the
mining code with proper asserts:

```cpp
genesis.nNonce = YOUR_NEW_NONCE;
hashGenesisBlock = genesis.GetHash();
assert(hashGenesisBlock == uint256("0xYOUR_NEW_HASH"));
assert(genesis.hashMerkleRoot == uint256("0xYOUR_NEW_MERKLE"));
```

Also update the 3 checkpoint entries at the top of `chainparams.cpp` with the new genesis
hashes.

## Step 5: Store Private Keys Securely

The private keys are in `~/MIS_CLAVES_FAIRCOIN/`. **Copy this folder to a safe location**:

- USB drive (encrypted)
- Password manager (KeePass, 1Password)
- Paper backup in a safe
- **NEVER** in the git repository
- **NEVER** in a cloud service unencrypted

If you lose the private keys, you lose:
- **Alert private key**: Cannot broadcast emergency network alerts
- **Spork private key**: Cannot activate/deactivate network features
- **Genesis private key**: Not critical - the genesis coinbase is unspendable anyway

## Receiving the Premine

Since the premine is paid in block 1 via `GetBlockValue()`, the wallet that mines block 1
automatically receives 5,000,000 FAIR. Just start mining on a fresh network:

```bash
./src/faircoind -daemon
./src/faircoin-cli setgenerate true 16
./src/faircoin-cli getbalance
```

After block 1 has 6 confirmations (maturity), you'll see 5,000,000 FAIR in your balance.

## Security Checklist

- [ ] Keys generated with openssl on a trusted machine
- [ ] Private keys copied to at least 2 secure locations
- [ ] Private keys are NOT in the source code or git
- [ ] Public keys pasted in `src/chainparams.cpp`
- [ ] Genesis block re-mined with new values
- [ ] `src/chainparams.cpp` asserts updated with final hashes
- [ ] Checkpoints updated with final hashes
- [ ] Code compiles and daemon starts without asserts failing
