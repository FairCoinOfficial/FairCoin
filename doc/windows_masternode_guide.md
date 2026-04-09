# Masternode Guide for Windows

## Prerequisites

- FairCoin wallet (`faircoin-qt.exe`)
- Exactly **5,000 FAIR** in your wallet
- A static public IP address (or VPS)

## Setup Steps

### 1. Install and Sync

1. Run `faircoin-qt.exe` for the first time
2. Allow firewall/antivirus connections when prompted
3. Wait for the wallet to fully synchronize with the network

### 2. Send Collateral

1. Go to **Help > Debug Console**
2. Run: `getaccountaddress 0`
3. Copy the result - this is your **masternode deposit address**
4. Send **exactly 5,000 FAIR** to this address (no more, no less)
5. Wait for **15 confirmations**

### 3. Generate Masternode Key

In the Debug Console, run:

```
masternode genkey
```

Copy the result - this is your **masternode private key**.

### 4. Edit faircoin.conf

Open the configuration file located at:

```
C:\Users\<YourUsername>\AppData\Roaming\faircoin\faircoin.conf
```

Add the following:

```
rpcuser=CHOOSE_A_USERNAME
rpcpassword=CHOOSE_A_STRONG_PASSWORD
listen=1
server=1
daemon=1
masternode=1
externalip=YOUR_PUBLIC_IP
masternodeaddr=YOUR_PUBLIC_IP:46372
masternodeprivkey=YOUR_MASTERNODE_PRIVKEY
```

Save and close.

### 5. Edit masternode.conf

Open the file at:

```
C:\Users\<YourUsername>\AppData\Roaming\faircoin\masternode.conf
```

Add a line:

```
mn1 YOUR_PUBLIC_IP:46372 YOUR_MASTERNODE_PRIVKEY YOUR_TXID OUTPUT_INDEX
```

To find your **TXID**: go to Transactions, double-click the 5,000 FAIR transaction.

### 6. Start the Masternode

1. Close and reopen the wallet
2. Wait for 15 confirmations of your collateral transaction
3. Go to the **Masternodes** tab
4. Click **Start All** or **Start Alias**
5. You should see "Masternode started successfully"

Your masternode will appear with status **ENABLED** after being active for a certain number of blocks.
