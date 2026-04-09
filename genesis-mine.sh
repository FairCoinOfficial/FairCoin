#!/bin/bash
# ============================================================================
# FairCoin Genesis Block Miner
# ============================================================================
# Run this script ONCE before launching the FairCoin network for the first time.
# It will:
#   1. Mine the genesis blocks (mainnet, testnet, regtest)
#   2. Show you the values to put in src/chainparams.cpp
#   3. Optionally auto-patch chainparams.cpp for you
#
# Prerequisites:
#   sudo apt-get install python3 build-essential
#
# Usage:
#   chmod +x genesis-mine.sh
#   ./genesis-mine.sh
#
# After running, delete this script - you only need it once.
# ============================================================================

set -e

echo "============================================"
echo "  FairCoin Genesis Block Miner"
echo "============================================"
echo ""

# Check python3
if ! command -v python3 &>/dev/null; then
    echo "ERROR: python3 is required. Install with: sudo apt-get install python3"
    exit 1
fi

# Create the Python genesis miner
cat > /tmp/faircoin_genesis_miner.py << 'PYEOF'
#!/usr/bin/env python3
"""
FairCoin Genesis Block Miner

Mines genesis blocks by finding a nonce that produces a hash below the target.
Uses the same Quark/scrypt hashing as the FairCoin daemon for PoW validation,
but for genesis block mining we only need SHA256d (double SHA-256) which is
what GetHash() uses for the block header.
"""

import hashlib
import struct
import time
import sys

def uint256_from_compact(nBits):
    """Convert compact target representation to uint256."""
    nSize = nBits >> 24
    nWord = nBits & 0x007fffff
    if nSize <= 3:
        nWord >>= 8 * (3 - nSize)
    else:
        nWord <<= 8 * (nSize - 3)
    return nWord

def sha256d(data):
    """Double SHA-256 hash."""
    return hashlib.sha256(hashlib.sha256(data).digest()).digest()

def serialize_block_header(version, prev_hash, merkle_root, timestamp, bits, nonce):
    """Serialize a block header for hashing (80 bytes)."""
    header = struct.pack('<I', version)                    # 4 bytes
    header += prev_hash                                     # 32 bytes
    header += merkle_root                                   # 32 bytes
    header += struct.pack('<I', timestamp)                  # 4 bytes
    header += struct.pack('<I', bits)                       # 4 bytes
    header += struct.pack('<I', nonce)                      # 4 bytes
    return header

def hash_to_int(hash_bytes):
    """Convert hash bytes (little-endian) to integer."""
    return int.from_bytes(hash_bytes, byteorder='little')

def int_to_hash_hex(val):
    """Convert integer to hash hex string (big-endian display format)."""
    return val.to_bytes(32, byteorder='big').hex()

def create_coinbase_script(timestamp_str):
    """Create coinbase scriptSig from timestamp string."""
    timestamp_bytes = timestamp_str.encode('utf-8')
    # Match the C++ code: CScript() << 486604799 << CScriptNum(4) << vector<unsigned char>(timestamp)
    script = b''
    # Push 486604799 (0x1d00ffff) as 4-byte little-endian
    val = 486604799
    script += bytes([4])  # push 4 bytes
    script += struct.pack('<I', val)
    # Push CScriptNum(4)
    script += bytes([1, 4])  # push 1 byte: 0x04
    # Push timestamp
    script += bytes([len(timestamp_bytes)]) + timestamp_bytes
    return script

def create_coinbase_tx(timestamp_str, value_satoshis, pubkey_hex):
    """Create the coinbase transaction for the genesis block."""
    tx = b''
    # Version
    tx += struct.pack('<I', 1)
    # Timestamp (nTime for PoS coins) - set to 0 for genesis
    tx += struct.pack('<I', 0)
    # Number of inputs
    tx += bytes([1])
    # Input: prevout hash (null)
    tx += b'\x00' * 32
    # Input: prevout index (0xffffffff)
    tx += struct.pack('<I', 0xffffffff)
    # Input: scriptSig
    scriptsig = create_coinbase_script(timestamp_str)
    # Serialize scriptsig length as varint
    tx += bytes([len(scriptsig)])
    tx += scriptsig
    # Input: sequence
    tx += struct.pack('<I', 0xffffffff)
    # Number of outputs
    tx += bytes([1])
    # Output: value
    tx += struct.pack('<q', value_satoshis)
    # Output: scriptPubKey (pubkey + OP_CHECKSIG)
    pubkey_bytes = bytes.fromhex(pubkey_hex)
    scriptpubkey = bytes([len(pubkey_bytes)]) + pubkey_bytes + bytes([0xac])  # OP_CHECKSIG
    tx += bytes([len(scriptpubkey)])
    tx += scriptpubkey
    # Lock time
    tx += struct.pack('<I', 0)
    return tx

def compute_merkle_root(tx_data):
    """Compute merkle root from a single transaction."""
    return sha256d(tx_data)

def mine_genesis(network_name, version, timestamp_str, timestamp_unix, nbits,
                 value_satoshis, pubkey_hex, prev_hash=None):
    """Mine a genesis block and return the nonce and hashes."""
    print(f"\n{'='*60}")
    print(f"  Mining {network_name} genesis block...")
    print(f"{'='*60}")
    print(f"  Timestamp: \"{timestamp_str}\"")
    print(f"  nTime:     {timestamp_unix}")
    print(f"  nBits:     0x{nbits:08x}")
    print(f"  Value:     {value_satoshis / 100000000:.8f} FAIR")
    print()

    if prev_hash is None:
        prev_hash = b'\x00' * 32

    # Create coinbase transaction
    coinbase_tx = create_coinbase_tx(timestamp_str, value_satoshis, pubkey_hex)

    # Compute merkle root
    merkle_root = compute_merkle_root(coinbase_tx)

    # Target from compact bits
    target = uint256_from_compact(nbits)

    print(f"  Merkle Root: {merkle_root[::-1].hex()}")
    print(f"  Target:      {int_to_hash_hex(target)}")
    print()
    print(f"  Searching for valid nonce...", flush=True)

    nonce = 0
    start_time = time.time()
    last_report = start_time

    while True:
        header = serialize_block_header(version, prev_hash, merkle_root,
                                        timestamp_unix, nbits, nonce)
        block_hash = sha256d(header)
        hash_int = hash_to_int(block_hash)

        if hash_int <= target:
            elapsed = time.time() - start_time
            hash_hex = block_hash[::-1].hex()
            merkle_hex = merkle_root[::-1].hex()

            print(f"\n  FOUND! ({elapsed:.1f}s, {nonce} iterations)")
            print(f"  {'─'*56}")
            print(f"  nNonce:          {nonce}")
            print(f"  hashGenesisBlock: 0x{hash_hex}")
            print(f"  hashMerkleRoot:   0x{merkle_hex}")
            print(f"  {'─'*56}")

            return nonce, hash_hex, merkle_hex

        nonce += 1

        if nonce % 500000 == 0:
            now = time.time()
            rate = nonce / (now - start_time)
            print(f"    ...nonce {nonce:>10d} ({rate:.0f} hash/s)", flush=True)

        if nonce >= 0xFFFFFFFF:
            print("  ERROR: Nonce space exhausted! Try a different nTime.")
            sys.exit(1)

# ============================================================================
# FairCoin Parameters
# ============================================================================

TIMESTAMP = "FairCoin genesis - a new beginning - fairco.in"
GENESIS_TIME = 1744156800  # April 9, 2026 00:00:00 UTC
PUBKEY_HEX = "040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

print("============================================")
print("  FairCoin Genesis Block Miner")
print("============================================")
print(f"  Timestamp: \"{TIMESTAMP}\"")
print(f"  nTime:     {GENESIS_TIME}")

# --- Mine Mainnet ---
mainnet_nonce, mainnet_hash, mainnet_merkle = mine_genesis(
    network_name="MAINNET",
    version=1,
    timestamp_str=TIMESTAMP,
    timestamp_unix=GENESIS_TIME,
    nbits=0x1e0ffff0,
    value_satoshis=0,
    pubkey_hex=PUBKEY_HEX
)

# --- Mine Testnet ---
# Testnet uses same tx but different nTime in some cases; here same nTime
testnet_nonce, testnet_hash, testnet_merkle = mine_genesis(
    network_name="TESTNET",
    version=1,
    timestamp_str=TIMESTAMP,
    timestamp_unix=GENESIS_TIME,
    nbits=0x1e0ffff0,
    value_satoshis=0,
    pubkey_hex=PUBKEY_HEX
)
# Note: Testnet inherits from mainnet constructor, so it has the same
# merkle root and same nBits. The nonce will be the same since nTime is the same.

# --- Mine Regtest ---
regtest_nonce, regtest_hash, regtest_merkle = mine_genesis(
    network_name="REGTEST",
    version=1,
    timestamp_str=TIMESTAMP,
    timestamp_unix=GENESIS_TIME,
    nbits=0x207fffff,
    value_satoshis=0,
    pubkey_hex=PUBKEY_HEX
)

# ============================================================================
# Output summary
# ============================================================================
print(f"\n{'='*60}")
print(f"  ALL GENESIS BLOCKS MINED SUCCESSFULLY!")
print(f"{'='*60}")
print()
print("Copy these values into src/chainparams.cpp:")
print()
print("--- MAINNET (CMainParams) ---")
print(f'genesis.nNonce = {mainnet_nonce};')
print(f'assert(hashGenesisBlock == uint256("0x{mainnet_hash}"));')
print(f'assert(genesis.hashMerkleRoot == uint256("0x{mainnet_merkle}"));')
print()
print("--- TESTNET (CTestNetParams) ---")
print(f'genesis.nNonce = {testnet_nonce};')
print(f'assert(hashGenesisBlock == uint256("0x{testnet_hash}"));')
print()
print("--- REGTEST (CRegTestParams) ---")
print(f'genesis.nNonce = {regtest_nonce};')
print(f'assert(hashGenesisBlock == uint256("0x{regtest_hash}"));')
print()

# Write results to file for the shell script to read
with open("/tmp/faircoin_genesis_results.txt", "w") as f:
    f.write(f"MAINNET_NONCE={mainnet_nonce}\n")
    f.write(f"MAINNET_HASH={mainnet_hash}\n")
    f.write(f"MAINNET_MERKLE={mainnet_merkle}\n")
    f.write(f"TESTNET_NONCE={testnet_nonce}\n")
    f.write(f"TESTNET_HASH={testnet_hash}\n")
    f.write(f"REGTEST_NONCE={regtest_nonce}\n")
    f.write(f"REGTEST_HASH={regtest_hash}\n")

PYEOF

echo "Starting genesis block mining..."
echo "(This may take a few minutes depending on your CPU)"
echo ""

python3 /tmp/faircoin_genesis_miner.py

if [ $? -ne 0 ]; then
    echo "ERROR: Genesis mining failed!"
    exit 1
fi

# Read results
source /tmp/faircoin_genesis_results.txt

echo ""
echo "============================================"
echo "  Auto-patch chainparams.cpp?"
echo "============================================"
echo ""
echo "This will update src/chainparams.cpp with the mined values."
echo ""
read -p "Apply changes automatically? [y/N] " REPLY

if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    CHAINPARAMS="$(dirname "$0")/src/chainparams.cpp"

    if [ ! -f "$CHAINPARAMS" ]; then
        echo "ERROR: Cannot find $CHAINPARAMS"
        exit 1
    fi

    # Backup
    cp "$CHAINPARAMS" "${CHAINPARAMS}.bak"
    echo "Backup saved to ${CHAINPARAMS}.bak"

    # Patch mainnet nonce
    sed -i "s/genesis.nNonce = 0; \/\/ TODO: Re-mine genesis block to find valid nonce/genesis.nNonce = ${MAINNET_NONCE};/" "$CHAINPARAMS"

    # Patch mainnet asserts
    sed -i "s|// TODO: Update these asserts after mining the new genesis block||" "$CHAINPARAMS"
    sed -i "s|//assert(hashGenesisBlock == uint256(\"0xNEW_GENESIS_HASH\"));|assert(hashGenesisBlock == uint256(\"0x${MAINNET_HASH}\"));|" "$CHAINPARAMS"
    sed -i "s|//assert(genesis.hashMerkleRoot == uint256(\"0xNEW_MERKLE_ROOT\"));|assert(genesis.hashMerkleRoot == uint256(\"0x${MAINNET_MERKLE}\"));|" "$CHAINPARAMS"

    # Patch testnet nonce
    sed -i "s/genesis.nNonce = 0; \/\/ TODO: Re-mine testnet genesis block/genesis.nNonce = ${TESTNET_NONCE};/" "$CHAINPARAMS"

    # Patch testnet assert
    sed -i "s|// TODO: Update after mining testnet genesis||" "$CHAINPARAMS"
    sed -i "s|//assert(hashGenesisBlock == uint256(\"0xNEW_TESTNET_GENESIS_HASH\"));|assert(hashGenesisBlock == uint256(\"0x${TESTNET_HASH}\"));|" "$CHAINPARAMS"

    # Patch regtest nonce
    sed -i "s/genesis.nNonce = 0; \/\/ TODO: Re-mine regtest genesis block/genesis.nNonce = ${REGTEST_NONCE};/" "$CHAINPARAMS"

    # Patch regtest assert
    sed -i "s|// TODO: Update after mining regtest genesis||" "$CHAINPARAMS"
    sed -i "s|//assert(hashGenesisBlock == uint256(\"0xNEW_REGTEST_GENESIS_HASH\"));|assert(hashGenesisBlock == uint256(\"0x${REGTEST_HASH}\"));|" "$CHAINPARAMS"

    # Patch mainnet checkpoint with genesis hash
    sed -i "s|boost::assign::map_list_of(0, uint256(\"0x0\")); // TODO: Update with new genesis hash|boost::assign::map_list_of(0, uint256(\"0x${MAINNET_HASH}\"));|" "$CHAINPARAMS"

    # Patch testnet checkpoint
    sed -i "s|boost::assign::map_list_of(0, uint256(\"0x0\")); // TODO: Update with new testnet genesis hash|boost::assign::map_list_of(0, uint256(\"0x${TESTNET_HASH}\"));|" "$CHAINPARAMS"

    # Patch regtest checkpoint
    sed -i "s|boost::assign::map_list_of(0, uint256(\"0x0\")); // TODO: Update with new regtest genesis hash|boost::assign::map_list_of(0, uint256(\"0x${REGTEST_HASH}\"));|" "$CHAINPARAMS"

    echo ""
    echo "chainparams.cpp has been patched!"
    echo ""
    echo "Next steps:"
    echo "  1. Generate your cryptographic keys (see doc/GENERATE-KEYS.md)"
    echo "  2. Replace the placeholder keys in src/chainparams.cpp"
    echo "  3. Recompile: make -j\$(nproc)"
    echo "  4. Start your node: ./src/faircoind -daemon -gen=1"
    echo ""
    echo "You can now delete this script: rm genesis-mine.sh"
else
    echo ""
    echo "No changes made. Apply the values manually to src/chainparams.cpp"
    echo "The mined values are saved in /tmp/faircoin_genesis_results.txt"
fi

# Cleanup
rm -f /tmp/faircoin_genesis_miner.py

echo ""
echo "Done!"
