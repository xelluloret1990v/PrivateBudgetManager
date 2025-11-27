# **README.md**

# 🛡️ Private Budget Manager — Fully Homomorphic Encrypted Budget Control

**Built with ZAMA FHEVM • Encrypted user spending • Public/Owner decryptable state • Zero-knowledge inputs**

---

## 🚀 Overview

**Private Budget Manager** is a privacy-preserving budgeting dApp built on the **ZAMA FHEVM**. It allows users to:

- Record expenses **encrypted on-chain**
- Track their total spending **without revealing raw values**
- Compare spending vs an encrypted spending limit
- Let the contract owner:
  - Set an encrypted spending limit
  - Reset user expenses

- Decrypt totals + limit **either via user decryption (EIP-712) or public decrypt**, depending on frontend origin

The system uses:

- **FHE.sol** encrypted integer types (`euint64`, `ebool`)
- **externalEuint64** inputs + proof verification
- **Relayer SDK** for:
  - encryption
  - ZK proofs
  - public decryption
  - user decryption

All values stored on-chain remain encrypted at all times.

---

## 🧠 Architecture

```
                                ┌────────────────────────┐
                                │        Frontend        │
                                │  (HTML + JS + ZAMA SDK)│
                                └───────────┬────────────┘
                                            │
                     Encrypted Inputs       │     Decryption (user/public)
                                            ▼
                            ┌────────────────────────────────┐
                            │     ZAMA Relayer & Gateway     │
                            │  • Encrypt inputs              │
                            │  • Generate proofs             │
                            │  • Public/user decrypt         │
                            └───────────────┬────────────────┘
                                            │
                                            ▼
                   ┌────────────────────────────────────────────────┐
                   │        PrivateBudgetManager (Smart Contract)   │
                   │------------------------------------------------│
                   │  • encrypted limit (euint64)                   │
                   │  • encrypted user total (euint64)              │
                   │  • recordExpense()                             │
                   │  • setSpendingLimit() (owner)                  │
                   │  • resetUserExpenses() (owner)                 │
                   │  • getTotalExpenses() → bytes32 handle         │
                   │  • getTotalExceedsLimit() → bytes32 handle     │
                   └────────────────────────────────────────────────┘
```

---

## 🔐 Contract Summary

The contract uses encrypted FHEVM types:

```solidity
euint64 private eSpendingLimit;
mapping(address => euint64) private totalExpenses;
```

### Key behaviors:

### ✔ **All stored values are encrypted**

No plaintext ETH amounts ever touch the blockchain.

### ✔ **Owner can set an encrypted limit**

```solidity
setSpendingLimit(externalEuint64 _spendingLimit, bytes proof)
```

### ✔ **Users record encrypted expenses**

```solidity
recordExpense(externalEuint64 encAmount, bytes proof)
```

### ✔ **Encrypted comparison**

```solidity
FHE.ge(total, eSpendingLimit) → ebool
```

### ✔ **Public decryptable getters**

Each getter turns encrypted data into a **publicly decryptable handle**, which frontend can decrypt using ZAMA Relayer:

- `getTotalExpenses(address)`
- `getTotalExceedsLimit(address)`
- `getSpendingLimit()`

### ✔ **Owner reset**

```solidity
resetUserExpenses(address user)
```

---

## 🖥️ Frontend

The frontend is a **single HTML page** with:

- Wallet connect (MetaMask)
- Set Limit (owner)
- Record Expense (encrypted)
- Get total (decrypt)
- Check if exceeds limit
- Decrypt limit
- Reset user expenses (owner)
- Full developer console logs for all operations

### Decryption Modes

The frontend automatically chooses:

| Environment | Method                            | Notes                           |
| ----------- | --------------------------------- | ------------------------------- |
| **HTTPS**   | `relayer.userDecrypt(handle)`     | requires user EIP-712 signature |
| **HTTP**    | `relayer.publicDecrypt([handle])` | no user signature               |

---

## 🛠️ Setup & Installation

Clone the repo:

```bash
git clone <your-repo-url>
cd private-budget-manager
```

Install dependencies (Hardhat + FHEVM tools):

```bash
npm install
```

Compile the contract:

```bash
npx hardhat compile
```

---

## 🌐 Deployment

Deploy to Sepolia or other ZAMA-supported networks:

```bash
npx hardhat run scripts/deploy.js --network sepolia
```

After deployment, update:

```
/index.html → contractAddress
```

---

## 🧪 Running the Frontend

You **must serve over HTTP or HTTPS**:

### Simple local server:

```bash
npx serve .
```

Open:

```
http://localhost:3000
```

HTTPS (enables user decryption):

```
https://localhost:3000
```

---

## 💡 Usage Guide

### 1. Connect Wallet

The header button will connect via MetaMask.

### 2. (Owner) Set Spending Limit

Enter ETH amount → encrypted → submitted to contract.

### 3. Record Expense

User inputs ETH amount → encrypted → added to their encrypted total.

### 4. Get Total

Displays decrypted total (ETH).

### 5. Check If Exceeds Limit

Decrypts the encrypted boolean (0/1).

### 6. Decrypt Spending Limit

Shows the owner-set limit.

### 7. (Owner) Reset User Expenses

Resets user’s encrypted total back to encrypted zero.

---

## 🧩 How FHE Works in This App

### 🔸 All amounts are encrypted at input

Frontend uses:

```js
relayer.createEncryptedInput(...)
```

### 🔸 Contract never sees plaintext

Even comparisons like:

```solidity
FHE.ge(total, eSpendingLimit)
```

happen in the encrypted domain.

### 🔸 No plaintext emissions

Events emit only encrypted handles (`bytes32`).

---

## 📁 Project Structure

```
.
├── contracts/
│   └── PrivateBudgetManager.sol
├── index.html (frontend)
├── scripts/
│   └── deploy.js
├── server.js
└── README.md  ← (this file)
```

---

## 🔒 Security Considerations

- Owner-restricted operations use `onlyOwner`
- All state stored as **encrypted FHE types**
- No plaintext arithmetic
- No leakage via events
- All decryptable values require:
  - user decryption (HTTPS)
  - OR public decryption (testnet-only)

---

## 📜 License

MIT — free to use, modify, and improve.

---

## 🙌 Credits

Built using:

- **ZAMA FHEVM**
- **Relayer SDK**
- Ethers.js
- MetaMask

---

**Built with ❤️ by the Zama team**
