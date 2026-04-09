# How to Generate Cryptographic Keys for FairCoin

This guide explains how to generate the cryptographic key pairs needed before launching
the FairCoin network. **Do this on a secure, offline computer.**

## Prerequisites

```bash
sudo apt-get install openssl
```

## Keys You Need to Generate

You need **3 key pairs** (minimum) for mainnet, and optionally 2 more for testnet:

| Key | Purpose | File Location |
|-----|---------|---------------|
| **Alert Key** | Broadcast emergency alerts to all nodes | `src/chainparams.cpp` → `vAlertPubKey` |
| **Spork Key** | Enable/disable features remotely (sporks) | `src/chainparams.cpp` → `strSporkKey` |
| **Genesis Key** | Receives the premine (5,000,000 FAIR) | `src/chainparams.cpp` → genesis `scriptPubKey` |
| Testnet Alert Key | Same as Alert Key, but for testnet | `src/chainparams.cpp` → testnet `vAlertPubKey` |
| Testnet Spork Key | Same as Spork Key, but for testnet | `src/chainparams.cpp` → testnet `strSporkKey` |

## Step 1: Generate a Key Pair

Run this command for each key you need:

```bash
openssl ecparam -genkey -name secp256k1 -out key.pem
openssl ec -in key.pem -text -noout
```

This outputs something like:

```
read EC key
Private-Key: (256 bit)
priv:
    00:a1:b2:c3:d4:e5:f6:...  (32 bytes)
pub:
    04:aa:bb:cc:dd:ee:ff:...  (65 bytes, starting with 04)
ASN1 OID: secp256k1
```

## Step 2: Extract the Public Key (hex)

The public key is the `pub:` section. Remove all colons and whitespace to get a
130-character hex string starting with `04`.

Example:
```
pub:
    04:c1:0e:83:b2:70:3c:cf:32:2f:7d:bd:62:dd:58:
    55:ac:7c:10:bd:05:58:14:ce:12:1b:a3:26:07:d5:
    73:b8:81:0c:02:c0:58:2a:ed:05:b4:de:b9:c4:b7:
    7b:26:d9:24:28:c6:12:56:cd:42:77:4b:ab:ea:0a:
    07:3b:2e:d0:c9
```

Becomes:
```
04c10e83b2703ccf322f7dbd62dd5855ac7c10bd055814ce121ba32607d573b8810c02c0582aed05b4deb9c4b77b26d92428c61256cd42774babea0a073b2ed0c9
```

## Step 3: Extract the Private Key (hex)

The private key is the `priv:` section. Remove colons, whitespace, and any leading `00:`.
This gives you a 64-character hex string.

**KEEP THIS SECRET. NEVER COMMIT IT TO THE REPOSITORY.**

## Step 4: Put Public Keys in the Code

Edit `src/chainparams.cpp` and replace the placeholder values:

### Alert Key (mainnet)
Find this line:
```cpp
vAlertPubKey = ParseHex("0400000000000000000000000000000000...");
```
Replace the hex string with your **Alert public key**.

### Spork Key (mainnet)
Find this line:
```cpp
strSporkKey = "0400000000000000000000000000000000...";
```
Replace with your **Spork public key**.

### Genesis Key (mainnet)
Find this line in the genesis block section:
```cpp
txNew.vout[0].scriptPubKey = CScript() << ParseHex("0400000000000000...") << OP_CHECKSIG;
```
Replace with your **Genesis public key**. This address will receive the premine.

### Testnet Keys
Do the same for the testnet section (look for the `CTestNetParams` class).

## Step 5: Store Private Keys Securely

For each private key, store it in a **secure, offline location**:

- **Alert private key**: Needed to send network-wide alert messages
- **Spork private key**: Needed to activate/deactivate network features
- **Genesis private key**: Needed to spend the 5,000,000 FAIR premine

Recommended storage:
- Password manager (KeePass, 1Password, etc.)
- Encrypted USB drive
- Paper in a safe
- **NEVER** on a server connected to the internet
- **NEVER** in the source code repository

## Step 6: Generate the Obfuscation Pool Dummy Address

After building FairCoin with your new keys, generate a valid FairCoin address:

```bash
./faircoind -daemon
./faircoin-cli getnewaddress
```

Use this address for `strObfuscationPoolDummyAddress` in `src/chainparams.cpp`.

## Step 7: Re-mine the Genesis Block

After updating all keys and parameters, you need to re-mine the genesis block.
The current genesis nonce is set to 0 (placeholder). You need to find a valid nonce.

Add this temporary code in `CMainParams()` constructor, right after `hashGenesisBlock = genesis.GetHash();`:

```cpp
if (true) {
    printf("Searching for genesis block...\n");
    uint256 hashTarget = CBigNum().SetCompact(genesis.nBits).getuint256();
    while (genesis.GetHash() > hashTarget) {
        ++genesis.nNonce;
        if (genesis.nNonce == 0) {
            printf("NONCE WRAPPED, incrementing time\n");
            ++genesis.nTime;
        }
        if (genesis.nNonce % 100000 == 0)
            printf("nonce %08u: hash = %s (target = %s)\n",
                genesis.nNonce, genesis.GetHash().ToString().c_str(),
                hashTarget.ToString().c_str());
    }
    printf("GENESIS BLOCK FOUND!\n");
    printf("nonce: %u\n", genesis.nNonce);
    printf("hash: %s\n", genesis.GetHash().ToString().c_str());
    printf("merkle: %s\n", genesis.hashMerkleRoot.ToString().c_str());
}
```

After finding the nonce:
1. Update `genesis.nNonce` with the found value
2. Uncomment and update the `assert(hashGenesisBlock == ...)` line
3. Update `assert(genesis.hashMerkleRoot == ...)` line
4. Remove the temporary mining code
5. Do the same for testnet and regtest genesis blocks

## Quick Reference: What Goes Where

```
src/chainparams.cpp:
  Line ~375  vAlertPubKey        = YOUR_ALERT_PUBLIC_KEY
  Line ~398  scriptPubKey        = YOUR_GENESIS_PUBLIC_KEY
  Line ~437  strSporkKey         = YOUR_SPORK_PUBLIC_KEY
  Line ~439  strObfuscationPool  = YOUR_FAIRCOIN_ADDRESS
  Line ~464  vAlertPubKey (test) = YOUR_TESTNET_ALERT_PUBLIC_KEY
  Line ~510  strSporkKey (test)  = YOUR_TESTNET_SPORK_PUBLIC_KEY
```

## Security Checklist

- [ ] Generated keys on an offline/air-gapped machine
- [ ] Private keys stored in at least 2 separate secure locations
- [ ] Private keys are NOT in the source code or any git-tracked file
- [ ] Genesis block re-mined with new parameters
- [ ] Temporary mining code removed before release
- [ ] All placeholder values replaced with real keys
