# KipuBank v2

A secure, multi-asset smart contract banking system built on Ethereum that allows users to deposit and withdraw both native ETH and ERC20 tokens with configurable limits and comprehensive security measures.

**Contract Address:** 0x685191C96874598768bD2E3d8C5E2b8286af668D

**Sepolia Scan:** https://sepolia.etherscan.io/address/0x685191C96874598768bD2E3d8C5E2b8286af668D

## Overview

KipuBank v2 is a smart contract that acts as a custodian for digital assets. It supports:
- **Native ETH deposits and withdrawals**
- **ERC20 token deposits and withdrawals**
- **Configurable deposit and transaction limits**
- **Owner-only withdrawal mechanism**
- **Reentrancy protection**
- **Comprehensive access controls**

## Features

### Core Functionality

- ✅ **Dual Asset Support**: Store both ETH and ERC20 tokens
- ✅ **Deposit Limits**: Configurable maximum total deposits
- ✅ **Transaction Limits**: Maximum amount per transaction
- ✅ **Owner Controls**: Only contract owner can withdraw funds
- ✅ **Balance Tracking**: Separate tracking for ETH and each ERC20 token
- ✅ **Event Logging**: Comprehensive event emission for all operations

### Security Features

- 🔒 **ReentrancyGuard**: Protection against reentrancy attacks
- 🔒 **Ownable**: Access control using OpenZeppelin's Ownable pattern
- 🔒 **SafeERC20**: Safe token transfers handling non-standard ERC20 tokens
- 🔒 **Input Validation**: Zero address and zero amount checks
- 🔒 **Checks-Effects-Interactions**: Secure state update pattern

## Contract Architecture

### Storage Structure

```solidity
// ETH balances per user
mapping(address => uint256) public balances;

// ERC20 token balances per token and per user
mapping(address => mapping(address => uint256)) public tokenBalances;

// Limits
uint256 internal depositLimit;        // Maximum total deposits
uint256 internal transactionsLimit;  // Maximum per transaction

// Counters
uint256 internal counterDeposit;
uint256 internal counterWithdraw;
```

### Key Functions

#### ETH Operations

**`deposit()`** - Deposits native ETH
- `payable` function that accepts ETH
- Validates amount and sender
- Checks deposit and transaction limits
- Updates user balance
- Emits `Deposit` event

**`withdraw(uint256 amount)`** - Withdraws ETH (owner only)
- Requires `onlyOwner` modifier
- Validates balance sufficiency
- Transfers ETH to owner
- Emits `Withdraw` event

#### ERC20 Token Operations

**`depositToken(address token, uint256 amount)`** - Deposits ERC20 tokens
- Requires token approval before calling
- Validates token address and amount
- Checks deposit and transaction limits
- Uses `safeTransferFrom` for secure transfer
- Updates token balance mapping
- Emits `DepositToken` event

**`withdrawToken(address token, uint256 amount)`** - Withdraws ERC20 tokens (owner only)
- Requires `onlyOwner` modifier
- Validates token balance
- Uses `safeTransfer` for secure transfer
- Emits `WithdrawToken` event

#### View Functions

- `getBalance(address)` - Returns ETH balance for an address
- `getTokenBalance(address token, address user)` - Returns ERC20 balance
- `getContractBalance()` - Returns total ETH in contract
- `getContractTokenBalance(address token)` - Returns total tokens in contract
- `getDepositLimit()` - Returns maximum deposit limit
- `getTransactionsLimit()` - Returns maximum transaction limit
- `getCounterDeposit()` - Returns total deposit count
- `getCounterWithdraw()` - Returns total withdrawal count

## How It Works

### ETH Deposit Flow

```
1. User calls deposit() with ETH (msg.value)
2. Contract validates:
   - Amount > 0
   - Sender != address(0)
   - Contract balance + amount <= depositLimit
   - Amount <= transactionsLimit
3. Updates balances[msg.sender] += msg.value
4. Emits Deposit event
```

### ERC20 Deposit Flow

```
1. User approves contract to spend tokens
2. User calls depositToken(tokenAddress, amount)
3. Contract validates:
   - Amount > 0
   - Token address != address(0)
   - Contract token balance + amount <= depositLimit
   - Amount <= transactionsLimit
4. Transfers tokens from user to contract (safeTransferFrom)
5. Updates tokenBalances[token][user] += amount
6. Emits DepositToken event
```

### Withdrawal Flow (Owner Only)

```
1. Owner calls withdraw(amount) or withdrawToken(token, amount)
2. Contract validates:
   - Owner has sufficient balance
   - Amount > 0
3. Updates balance (checks-effects-interactions pattern)
4. Transfers funds to owner
5. Emits Withdraw/WithdrawToken event
```

## Usage Examples

### Deploying the Contract

```bash
# Using Foundry script
forge script script/DeployKipuBankv2.s.sol:DeployKipuBankv2 \
    --rpc-url http://localhost:8545 \
    --private-key $PRIVATE_KEY \
    --broadcast
```

### Depositing ETH

```solidity
// Send ETH directly with the transaction
kipuBank.deposit{value: 1 ether}();
```

### Depositing ERC20 Tokens

```solidity
// Step 1: Approve the contract
IERC20(tokenAddress).approve(address(kipuBank), amount);

// Step 2: Deposit tokens
kipuBank.depositToken(tokenAddress, amount);
```

### Withdrawing (Owner Only)

```solidity
// Withdraw ETH
kipuBank.withdraw(amount);

// Withdraw ERC20 tokens
kipuBank.withdrawToken(tokenAddress, amount);
```

### Querying Balances

```solidity
// ETH balance
uint256 ethBalance = kipuBank.getBalance(userAddress);

// ERC20 token balance
uint256 tokenBalance = kipuBank.getTokenBalance(tokenAddress, userAddress);

// Contract total ETH
uint256 contractETH = kipuBank.getContractBalance();

// Contract total tokens
uint256 contractTokens = kipuBank.getContractTokenBalance(tokenAddress);
```

## Security Considerations

### Implemented Protections

1. **ReentrancyGuard**: All state-changing functions use `nonReentrant` modifier
2. **Ownable**: Only owner can withdraw funds
3. **SafeERC20**: Handles tokens that don't return boolean values
4. **Input Validation**: All functions validate addresses and amounts
5. **Checks-Effects-Interactions**: State updates before external calls

### Important Notes

⚠️ **Owner Responsibility**: The contract owner has full control over withdrawals. Ensure the owner address is secure.

⚠️ **Token Approvals**: Users must approve the contract before depositing ERC20 tokens.

⚠️ **Limits**: Both deposit and transaction limits are set at deployment and cannot be changed.

## Development

### Prerequisites

- [Foundry](https://getfoundry.sh/) installed
- Solidity ^0.8.0
- OpenZeppelin Contracts v5.x

### Build

```bash
forge build
```

### Test

```bash
forge test
```

### Format

```bash
forge fmt
```

## Deployment

### Local Deployment

This guide explains how to deploy contracts locally using Foundry Forge.

#### Prerequisites

1. **Foundry installed**: Make sure you have Foundry installed
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Verify installation**:
   ```bash
   forge --version
   ```

#### Step-by-Step Local Deployment

### 1. Compile Contracts

Before deploying, you need to compile the contracts:

```bash
forge build
```

This will:
- Compile all contracts in `src/`
- Verify dependencies in `lib/`
- Generate artifacts in `out/`

### 2. Start a Local Network (Anvil)

Anvil is Foundry's tool for creating a local blockchain:

```bash
anvil
```

This will:
- Start a local blockchain on port 8545 (default)
- Create 10 test accounts with funds
- Display private keys and addresses

**Example output:**
```
Available Accounts
==================
(0) 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000.0 ETH)
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

...
```

### 3. Configure Environment Variables (Optional)

You can configure environment variables for convenience:

```bash
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export RPC_URL=http://localhost:8545
```

### 4. Deploy the Contract

#### Option A: Deploy with Script (Recommended)

Use the created deploy script:

```bash
forge script script/DeployKipuBankv2.s.sol:DeployKipuBankv2 \
    --rpc-url http://localhost:8545 \
    --private-key $PRIVATE_KEY \
    --broadcast
```

Or without environment variables:

```bash
forge script script/DeployKipuBankv2.s.sol:DeployKipuBankv2 \
    --rpc-url http://localhost:8545 \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --broadcast
```

**Important parameters:**
- `--rpc-url`: Local network URL (Anvil)
- `--private-key`: Private key of the account that will deploy
- `--broadcast`: Actually performs the deploy (without this, it only simulates)

#### Option B: Direct Deploy (Without Script)

```bash
forge create src/KipuBankv2.sol:KipuBankv2 \
    --rpc-url http://localhost:8545 \
    --private-key $PRIVATE_KEY \
    --constructor-args 100000000000000000000 10000000000000000000
```

**Note:** Constructor values are in wei:
- `100000000000000000000` = 100 ether (deposit_limit)
- `10000000000000000000` = 10 ether (transactions_limit)

### 5. Verify the Deployment

After deployment, you will see:
- The deployed contract address
- The transaction hash
- The gas cost

**Example output:**
```
KipuBankv2 deployed at: 0x5FbDB2315678afecb367f032d93F642f64180aa3
Owner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Deposit Limit: 100000000000000000000
Transactions Limit: 10000000000000000000
```

### 6. Interact with the Contract (Optional)

You can use `cast` (Foundry CLI) to interact:

```bash
# Check contract balance
cast balance <CONTRACT_ADDRESS> --rpc-url http://localhost:8545

# Call a view function
cast call <CONTRACT_ADDRESS> \
    "getDepositLimit()" \
    --rpc-url http://localhost:8545

# Make a deposit (send ETH)
cast send <CONTRACT_ADDRESS> \
    "deposit()" \
    --value 1ether \
    --private-key $PRIVATE_KEY \
    --rpc-url http://localhost:8545
```

#### Useful Commands

##### Check Compilation
```bash
forge build
```

##### Run Tests
```bash
forge test
```

##### Run Tests with Verbosity
```bash
forge test -vvv
```

##### Check Gas
```bash
forge script script/DeployKipuBankv2.s.sol:DeployKipuBankv2 \
    --rpc-url http://localhost:8545 \
    --private-key $PRIVATE_KEY
```

##### Clean Build
```bash
forge clean
```

#### Troubleshooting

##### Error: "Failed to get EIP-1559 fees"
- Make sure Anvil is running
- Check if the port is correct (8545)

##### Error: "Insufficient funds"
- Use one of the accounts provided by Anvil
- Verify the account has sufficient ETH

##### Compilation Error
- Run `forge build` to see detailed errors
- Check if all dependencies are installed: `forge install`

#### Next Steps

1. **Test the contract**: Use `forge test` to run tests
2. **Deploy to testnet**: Configure `foundry.toml` with testnet RPC
3. **Verify contract**: Use tools like Etherscan (for testnets/mainnet)

#### Complete Session Example

```bash
# Terminal 1: Start Anvil
anvil

# Terminal 2: Deploy
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
forge script script/DeployKipuBankv2.s.sol:DeployKipuBankv2 \
    --rpc-url http://localhost:8545 \
    --private-key $PRIVATE_KEY \
    --broadcast
```

### Contract Verification

This guide explains how to verify smart contracts on blockchain explorers (like Etherscan, Basescan, etc.) using Foundry.

#### What is Contract Verification?

Contract verification is the process of publishing your smart contract's source code on a blockchain explorer. This allows anyone to:
- View the contract's source code
- Verify that the compiled code matches the source code
- Interact with the contract through the explorer's interface
- Trust the contract, since the code is public and verifiable

#### Prerequisites

1. **Contract already deployed**: You need the address of the deployed contract
2. **Explorer API Key**: You need an API key from the blockchain explorer
   - **Etherscan**: https://etherscan.io/apis
   - **Basescan**: https://basescan.org/apis
   - **Other explorers**: Consult the specific explorer's documentation

3. **Compilation artifacts**: Make sure compiled files are in `out/`

#### Initial Setup

##### 1. Get API Key

1. Create an account on the blockchain explorer (Etherscan, Basescan, etc.)
2. Go to the API Keys section
3. Create a new API key
4. Copy the key

##### 2. Configure Environment Variable

```bash
# For Etherscan (Ethereum Mainnet/Testnets)
export ETHERSCAN_API_KEY=your_api_key_here

# For Basescan (Base Mainnet/Testnets)
export BASESCAN_API_KEY=your_api_key_here

# For other networks, consult the explorer's documentation
```

##### 3. Configure foundry.toml (Optional)

You can also configure API keys directly in `foundry.toml`:

```toml
[etherscan]
etherscan = { key = "your_api_key_here" }
basescan = { key = "your_api_key_here" }
```

#### Basic Verification

##### General Command

```bash
forge verify-contract \
    <CONTRACT_ADDRESS> \
    <CONTRACT_NAME> \
    --chain <NETWORK> \
    --etherscan-api-key <API_KEY> \
    --constructor-args <ARGS_ENCODED>
```

##### Example: Verify KipuBankv2

#### Ethereum Sepolia (Testnet)

```bash
forge verify-contract \
    0x1234567890123456789012345678901234567890 \
    src/KipuBankv2.sol:KipuBankv2 \
    --chain sepolia \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(uint256,uint256)" 100000000000000000000 10000000000000000000)
```

#### Base Sepolia (Testnet)

```bash
forge verify-contract \
    0x1234567890123456789012345678901234567890 \
    src/KipuBankv2.sol:KipuBankv2 \
    --chain base_sepolia \
    --etherscan-api-key $BASESCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(uint256,uint256)" 100000000000000000000 10000000000000000000)
```

#### Ethereum Mainnet

```bash
forge verify-contract \
    0x1234567890123456789012345678901234567890 \
    src/KipuBankv2.sol:KipuBankv2 \
    --chain mainnet \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(uint256,uint256)" 100000000000000000000 10000000000000000000)
```

#### Encode Constructor Arguments

KipuBankv2 has a constructor with two parameters:
- `uint256 _depositLimit` (e.g., 100 ether = 100000000000000000000 wei)
- `uint256 _transactionsLimit` (e.g., 10 ether = 10000000000000000000 wei)

##### Method 1: Using cast abi-encode (Recommended)

```bash
cast abi-encode "constructor(uint256,uint256)" 100000000000000000000 10000000000000000000
```

##### Method 2: Manual encoding

For simple values, you can use `cast --to-wei`:

```bash
# Convert ether to wei
cast --to-wei 100 ether  # Result: 100000000000000000000
cast --to-wei 10 ether   # Result: 10000000000000000000
```

#### Verification with Libraries

If the contract uses external libraries (like OpenZeppelin), you need to specify the paths:

```bash
forge verify-contract \
    <CONTRACT_ADDRESS> \
    src/KipuBankv2.sol:KipuBankv2 \
    --chain <NETWORK> \
    --etherscan-api-key <API_KEY> \
    --constructor-args <ARGS_ENCODED> \
    --libraries <LIBRARIES>
```

#### Automatic Verification After Deploy

You can verify automatically after deployment using the `--verify` flag:

```bash
forge script script/DeployKipuBankv2.s.sol:DeployKipuBankv2 \
    --rpc-url <RPC_URL> \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY
```

#### Supported Networks

Foundry supports verification on various networks. Some examples:

- `mainnet` - Ethereum Mainnet
- `sepolia` - Ethereum Sepolia Testnet
- `goerli` - Ethereum Goerli Testnet (deprecated)
- `base` - Base Mainnet
- `base_sepolia` - Base Sepolia Testnet
- `optimism` - Optimism Mainnet
- `optimism_sepolia` - Optimism Sepolia Testnet
- `arbitrum` - Arbitrum Mainnet
- `arbitrum_sepolia` - Arbitrum Sepolia Testnet
- `polygon` - Polygon Mainnet
- `polygon_mumbai` - Polygon Mumbai Testnet

To see all supported networks:

```bash
forge verify-contract --help
```

#### Complete Example: Verify KipuBankv2

##### Step 1: Deploy the Contract

```bash
forge script script/DeployKipuBankv2.s.sol:DeployKipuBankv2 \
    --rpc-url https://sepolia.infura.io/v3/YOUR_INFURA_KEY \
    --private-key $PRIVATE_KEY \
    --broadcast
```

**Note the deployed contract address**, for example: `0x5FbDB2315678afecb367f032d93F642f64180aa3`

##### Step 2: Encode Constructor Arguments

```bash
# Constructor values: depositLimit=100 ether, transactionsLimit=10 ether
cast abi-encode "constructor(uint256,uint256)" \
    $(cast --to-wei 100 ether) \
    $(cast --to-wei 10 ether)
```

##### Step 3: Verify the Contract

```bash
forge verify-contract \
    0x5FbDB2315678afecb367f032d93F642f64180aa3 \
    src/KipuBankv2.sol:KipuBankv2 \
    --chain sepolia \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(uint256,uint256)" 100000000000000000000 10000000000000000000)
```

##### Step 4: Verify Status

After running the command, you will see a success message. Access the blockchain explorer and verify that the contract is marked as "Verified".

#### Verify UfesToken

UfesToken is a simple ERC20 contract with no constructor arguments:

```bash
forge verify-contract \
    <UFES_TOKEN_ADDRESS> \
    src/UfesToken.sol:UfesToken \
    --chain sepolia \
    --etherscan-api-key $ETHERSCAN_API_KEY
```

#### Troubleshooting

##### Error: "Contract source code already verified"

The contract has already been verified previously. This is not a problem - it means the verification was successful.

##### Error: "Unable to verify"

Possible causes:
1. **Incorrect constructor arguments**: Check if the arguments are encoded correctly
2. **Different compiler version**: Make sure to use the same Solidity version
3. **Different optimizations**: Check if the optimization settings are the same
4. **Invalid API Key**: Verify that the API key is correct and active

##### Check Compilation Settings

To check the settings used in compilation:

```bash
forge build --sizes
```

##### Verify with Verbosity

Use `-vvv` to see more details:

```bash
forge verify-contract \
    <ADDRESS> \
    src/KipuBankv2.sol:KipuBankv2 \
    --chain sepolia \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args <ARGS> \
    -vvv
```

##### Error: "Compiler version mismatch"

Make sure the Solidity version in the contract matches the version used by the explorer. You can specify the version:

```bash
forge verify-contract \
    <ADDRESS> \
    src/KipuBankv2.sol:KipuBankv2 \
    --chain sepolia \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --compiler-version <VERSION> \
    --constructor-args <ARGS>
```

#### Manual Verification (Alternative)

If automatic verification fails, you can verify manually:

1. Access the blockchain explorer (Etherscan, Basescan, etc.)
2. Navigate to the contract page
3. Click "Contract" → "Verify and Publish"
4. Fill in the fields:
   - Compiler Type: Solidity (Single file) or Solidity (Standard JSON Input)
   - Compiler Version: The version used (e.g., v0.8.20+commit.a1b79de6)
   - License: MIT (or your contract's license)
   - Source Code: Paste the contract's source code
5. Click "Verify and Publish"

#### Automated Verification Script

You can create a script to automate verification:

```bash
#!/bin/bash

# Configuration
CONTRACT_ADDRESS="0x1234567890123456789012345678901234567890"
CHAIN="sepolia"
API_KEY=$ETHERSCAN_API_KEY

# Constructor arguments
DEPOSIT_LIMIT=100000000000000000000  # 100 ether
TRANSACTIONS_LIMIT=10000000000000000000  # 10 ether

# Encode arguments
CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(uint256,uint256)" $DEPOSIT_LIMIT $TRANSACTIONS_LIMIT)

# Verify
forge verify-contract \
    $CONTRACT_ADDRESS \
    src/KipuBankv2.sol:KipuBankv2 \
    --chain $CHAIN \
    --etherscan-api-key $API_KEY \
    --constructor-args $CONSTRUCTOR_ARGS \
    -vvv
```

Save as `verify.sh`, make it executable and run:

```bash
chmod +x verify.sh
./verify.sh
```

#### Useful Links

- [Foundry Documentation - Verifying Contracts](https://book.getfoundry.sh/forge/verify-contract)
- [Etherscan API Documentation](https://docs.etherscan.io/api-endpoints/contracts)
- [Basescan API Documentation](https://docs.basescan.org/api-endpoints/contracts)

#### Important Notes

⚠️ **Security**: Never share your API keys publicly. Use environment variables or `.env` files (not committed to git).

⚠️ **Costs**: Contract verification is free, but you need an API key (which is also free).

⚠️ **Time**: Verification may take a few minutes. If it fails, try again after a few minutes.

⚠️ **Irreversible**: Once verified, the source code becomes publicly available permanently. Make sure you're ready to publish the code.

## Project Structure

```
kipu-bank-v2/
├── src/
│   ├── KipuBankv2.sol      # Main contract
│   └── UfesToken.sol       # Example ERC20 token
├── script/
│   ├── DeployKipuBankv2.s.sol
│   └── DeployUfesToken.s.sol
├── test/
│   └── Counter.t.sol
├── lib/
│   ├── forge-std/
│   └── openzeppelin-contracts/
├── foundry.toml
└── README.md
```

## Events

The contract emits the following events:

- `Deposit(address indexed sender, uint256 amount)` - ETH deposit
- `Withdraw(address indexed sender, uint256 amount)` - ETH withdrawal
- `DepositToken(address indexed sender, address indexed token, uint256 amount)` - ERC20 deposit
- `WithdrawToken(address indexed sender, address indexed token, uint256 amount)` - ERC20 withdrawal

## Errors

Custom errors for gas-efficient reverts:

- `DepositLimitExceeded` - Deposit would exceed limit
- `TransactionsLimitExceeded` - Transaction amount exceeds limit
- `InsufficientBalance` - User doesn't have enough balance
- `InvalidAmount` - Amount is zero
- `InvalidAddress` - Address is zero
- `FailedWithdraw` - ETH transfer failed
- `FailedTokenTransfer` - Token transfer failed

## License

MIT

## Contributing

This is a project for learning and demonstration purposes. Contributions and suggestions are welcome!

## Disclaimer

This contract is provided as-is for educational purposes. Always audit smart contracts before deploying to mainnet and use at your own risk.
