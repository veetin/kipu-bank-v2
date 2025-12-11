# KipuBank v2

<<<<<<< HEAD
A production-ready, multi-asset smart contract banking system built on Ethereum with Chainlink price feeds, role-based access control, and unified accounting in USDC decimals.

## Overview

KipuBank v2 is an advanced smart contract that acts as a custodian for digital assets. This evolved version includes:

- **Chainlink Price Feeds Integration**: Real-time ETH/USD conversion using Chainlink Data Feeds
- **Unified Accounting System**: All balances tracked in USDC decimals (6 decimals) for consistent accounting
- **Role-Based Access Control**: Fine-grained permissions using OpenZeppelin's AccessControl
- **Multi-Token Support**: Native ETH (represented as address(0)) and ERC20 tokens
- **Decimal Conversion**: Automatic conversion between different token decimals and USDC standard
- **Production-Ready Security**: Comprehensive error handling, reentrancy protection, and input validation

## Key Improvements from Original KipuBank

### 1. Chainlink Oracle Integration
- **ETH/USD Price Feed**: Uses Chainlink AggregatorV3Interface for real-time price data
- **Bank Cap Control**: Deposit limits enforced in USD terms using price feeds
- **Price Staleness Protection**: Maximum 24-hour staleness check for price data
- **Multi-Token Price Support**: Configurable price feeds per token for accurate valuation

### 2. Unified Accounting System
- **USDC Decimal Standard**: All internal accounting uses 6 decimals (USDC standard)
- **Address(0) for ETH**: Native ETH is represented as `address(0)` in token mappings
- **Dual Balance Tracking**: Each balance stores both raw amount and USDC equivalent
- **Total Deposits Tracking**: Per-token total deposits in USDC equivalent

### 3. Advanced Access Control
- **Role-Based Permissions**: 
  - `DEFAULT_ADMIN_ROLE`: Full administrative control
  - `ADMIN_ROLE`: Can manage token info and settings
  - `OPERATOR_ROLE`: Can withdraw funds
- **Flexible Role Management**: Roles can be granted/revoked dynamically
- **Multi-Admin Support**: Multiple administrators can be assigned

### 4. Type Declarations
- **TokenBalance Struct**: Stores raw amount and USDC equivalent
- **TokenInfo Struct**: Stores token decimals and price feed address
- **Type Safety**: Custom types improve code readability and safety

### 5. Gas Optimizations
- **Immutable Variables**: Price feed and limits stored as immutable for gas savings
- **Constant Values**: USDC decimals and price staleness threshold as constants
- **Efficient Storage**: Nested mappings optimized for gas usage

### 6. Enhanced Error Handling
- **Custom Errors**: Gas-efficient custom errors instead of string messages
- **Comprehensive Validation**: Price feed validation, staleness checks, and amount validation
- **Clear Error Messages**: Specific errors for each failure scenario

## Contract Architecture

### Storage Structure

```solidity
// Type Declarations
struct TokenBalance {
    uint256 rawAmount;        // Amount in token's native decimals
    uint256 usdcEquivalent;   // Amount in USDC decimals (6)
}

struct TokenInfo {
    uint8 decimals;           // Token decimals
    address priceFeed;        // Chainlink price feed (address(0) if none)
}

// Constants
uint8 public constant USDC_DECIMALS = 6;
uint256 public constant MAX_PRICE_STALENESS = 86400; // 24 hours
address public constant NATIVE_ETH = address(0);

// Immutable Variables
AggregatorV3Interface public immutable ETH_USD_PRICE_FEED;
uint256 public immutable DEPOSIT_LIMIT_USDC;
uint256 public immutable TRANSACTIONS_LIMIT_USDC;

// Storage Mappings
mapping(address => mapping(address => TokenBalance)) public balances;
mapping(address => TokenInfo) public tokenInfo;
mapping(address => uint256) public totalDepositsUsdc;
```

### Key Functions

#### Deposit Functions

**`deposit()`** - Deposit native ETH
- Converts ETH to USDC equivalent using Chainlink price feed
- Validates transaction and deposit limits in USD terms
- Updates both raw ETH balance and USDC equivalent
- Emits `Deposit` event with both amounts

**`depositToken(address token, uint256 amount)`** - Deposit ERC20 tokens
- Requires token info to be set via `setTokenInfo()`
- Converts token amount to USDC equivalent
- Validates limits in USD terms
- Uses `safeTransferFrom` for secure token transfer
- Emits `Deposit` event

#### Withdrawal Functions

**`withdraw(uint256 amount)`** - Withdraw ETH (OPERATOR_ROLE only)
- Validates sufficient balance
- Updates accounting in USDC equivalent
- Transfers ETH using low-level call
- Emits `Withdraw` event

**`withdrawToken(address token, uint256 amount)`** - Withdraw ERC20 tokens (OPERATOR_ROLE only)
- Validates token balance
- Updates accounting in USDC equivalent
- Uses `safeTransfer` for secure token transfer
- Emits `Withdraw` event

#### Administrative Functions

**`setTokenInfo(address token, uint8 decimals, address priceFeed)`** - Set token metadata (ADMIN_ROLE only)
- Configures token decimals and optional price feed
- Validates price feed if provided
- Required before depositing ERC20 tokens (except ETH)

#### View Functions

- `getBalance(address token, address user)` - Returns raw amount and USDC equivalent
- `getTotalDepositsUsdc(address token)` - Returns total deposits in USDC decimals
- `getContractBalance()` - Returns contract's ETH balance
- `getContractTokenBalance(address token)` - Returns contract's token balance
- `getEthUsdPrice()` - Returns current ETH/USD price from Chainlink

## How It Works

### Deposit Flow (ETH)

```
1. User calls deposit() with ETH (msg.value)
2. Contract:
   - Gets ETH/USD price from Chainlink
   - Converts ETH amount to USDC equivalent (6 decimals)
   - Validates: usdcEquivalent <= TRANSACTIONS_LIMIT_USDC
   - Validates: totalDepositsUsdc[ETH] + usdcEquivalent <= DEPOSIT_LIMIT_USDC
3. Updates balances[address(0)][user] with both raw and USDC amounts
4. Updates totalDepositsUsdc[address(0)]
5. Emits Deposit event
```

### Deposit Flow (ERC20)

```
1. Admin sets token info: setTokenInfo(token, decimals, priceFeed)
2. User approves contract to spend tokens
3. User calls depositToken(token, amount)
4. Contract:
   - Transfers tokens from user (safeTransferFrom)
   - Converts amount to USDC equivalent using price feed
   - Validates limits in USD terms
5. Updates balances[token][user] and totalDepositsUsdc[token]
6. Emits Deposit event
```

### Decimal Conversion

The contract normalizes all values to USDC decimals (6) for unified accounting:

```solidity
// Example: Convert 1 ETH (18 decimals) to USDC equivalent
// 1. Get ETH price from Chainlink (e.g., $3000 with 8 decimals)
// 2. Calculate: (1e18 * 3000e8 * 1e6) / (1e18 * 1e8) = 3000e6
// Result: 3000 USDC equivalent (6 decimals)
```

### Price Feed Integration

- **ETH/USD**: Uses Chainlink AggregatorV3Interface
- **Other Tokens**: Configurable per token via `setTokenInfo()`
- **Staleness Check**: Prices older than 24 hours are rejected
- **Fallback**: If no price feed, assumes 1:1 conversion (for stablecoins)

## Usage Examples

### Deployment

```bash
# Set environment variable for price feed (optional)
export ETH_USD_PRICE_FEED=0x694AA1769357215DE4FAC081bf1f309aDC325306

# Deploy to Sepolia
forge script script/DeployKipuBankv2.s.sol:DeployKipuBankv2 \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast
```

### Setting Up Token Info

```solidity
// Set USDC token info (6 decimals, no price feed needed for 1:1)
kipuBank.setTokenInfo(
    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // USDC address
    6,                                           // decimals
    address(0)                                   // no price feed
);

// Set DAI token info (18 decimals, with price feed)
kipuBank.setTokenInfo(
    0x6B175474E89094C44Da98b954EedeAC495271d0F, // DAI address
    18,                                          // decimals
    0x773616E4d11A78F511299002da57A0a94577F1f4  // DAI/USD price feed
);
```

### Depositing ETH

```solidity
// Deposit 1 ETH
kipuBank.deposit{value: 1 ether}();

// Check balance
(uint256 rawAmount, uint256 usdcEquivalent) = kipuBank.getBalance(
    address(0),  // ETH is address(0)
    msg.sender
);
// rawAmount: 1000000000000000000 (1e18 wei)
// usdcEquivalent: ~3000000000 (3000e6, assuming $3000/ETH)
```

### Depositing ERC20 Tokens

```solidity
// Step 1: Approve
IERC20(usdcAddress).approve(address(kipuBank), 1000 * 10**6);

// Step 2: Deposit
kipuBank.depositToken(usdcAddress, 1000 * 10**6);

// Check balance
(uint256 rawAmount, uint256 usdcEquivalent) = kipuBank.getBalance(
    usdcAddress,
    msg.sender
);
// rawAmount: 1000000000 (1000e6)
// usdcEquivalent: 1000000000 (1000e6, 1:1 for USDC)
```

### Withdrawing (Operator Only)

```solidity
// Withdraw ETH
kipuBank.withdraw(0.5 ether);

// Withdraw ERC20 tokens
kipuBank.withdrawToken(usdcAddress, 500 * 10**6);
```

### Querying Prices

```solidity
// Get current ETH/USD price
(int256 price, uint8 decimals) = kipuBank.getEthUsdPrice();
// price: 300000000000 (3000e8, Chainlink uses 8 decimals)
// decimals: 8
```

## Interações com o Contrato

Esta seção fornece exemplos práticos de como interagir com o contrato usando Cast (Foundry CLI).

O `cast` é uma ferramenta de linha de comando do Foundry para interagir com contratos.

#### Variáveis de Ambiente

```bash
# Endereço do contrato (ajuste após deploy)
export CONTRACT_ADDRESS=0x...

# RPC URL (ajuste conforme necessário)
export RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
# ou para local: export RPC_URL=http://localhost:8545

# Chave privada (use com cuidado!)
export PRIVATE_KEY=your_private_key
```

#### Consultas (View Functions)

```bash
# Obter saldo de um usuário para ETH
cast call $CONTRACT_ADDRESS \
    "getBalance(address,address)" \
    "0x0000000000000000000000000000000000000000" \
    "0xYourUserAddress" \
    --rpc-url $RPC_URL

# Obter saldo de um usuário para um token ERC20
cast call $CONTRACT_ADDRESS \
    "getBalance(address,address)" \
    "0xTokenAddress" \
    "0xYourUserAddress" \
    --rpc-url $RPC_URL

# Obter total de depósitos em USDC para um token
cast call $CONTRACT_ADDRESS \
    "getTotalDepositsUsdc(address)" \
    "0x0000000000000000000000000000000000000000" \
    --rpc-url $RPC_URL

# Obter saldo de ETH do contrato
cast call $CONTRACT_ADDRESS \
    "getContractBalance()" \
    --rpc-url $RPC_URL

# Obter saldo de token do contrato
cast call $CONTRACT_ADDRESS \
    "getContractTokenBalance(address)" \
    "0xTokenAddress" \
    --rpc-url $RPC_URL

# Obter preço ETH/USD atual
cast call $CONTRACT_ADDRESS \
    "getEthUsdPrice()" \
    --rpc-url $RPC_URL

# Obter informações de um token
cast call $CONTRACT_ADDRESS \
    "tokenInfo(address)" \
    "0xTokenAddress" \
    --rpc-url $RPC_URL

# Obter limites do contrato
cast call $CONTRACT_ADDRESS "DEPOSIT_LIMIT_USDC()" --rpc-url $RPC_URL
cast call $CONTRACT_ADDRESS "TRANSACTIONS_LIMIT_USDC()" --rpc-url $RPC_URL
```

#### Transações (State-Changing Functions)

```bash
# Depositar ETH (0.1 ETH = 100000000000000000 wei)
cast send $CONTRACT_ADDRESS \
    "deposit()" \
    --value 100000000000000000 \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL

# Depositar token ERC20 (1000 tokens com 6 decimais = 1000000000)
cast send $CONTRACT_ADDRESS \
    "depositToken(address,uint256)" \
    "0xTokenAddress" \
    "1000000000" \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL

# Configurar informações de token (apenas ADMIN_ROLE)
cast send $CONTRACT_ADDRESS \
    "setTokenInfo(address,uint8,address)" \
    "0xTokenAddress" \
    "18" \
    "0xPriceFeedAddress" \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL

# Sacar ETH (apenas OPERATOR_ROLE)
cast send $CONTRACT_ADDRESS \
    "withdraw(uint256)" \
    "500000000000000000" \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL

# Sacar token ERC20 (apenas OPERATOR_ROLE)
cast send $CONTRACT_ADDRESS \
    "withdrawToken(address,uint256)" \
    "0xTokenAddress" \
    "500000000" \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL
```

#### Gerenciamento de Roles

```bash
# Verificar se um endereço tem ADMIN_ROLE
cast call $CONTRACT_ADDRESS \
    "hasRole(bytes32,address)" \
    $(cast keccak256 "ADMIN_ROLE") \
    "0xAddressToCheck" \
    --rpc-url $RPC_URL

# Verificar se um endereço tem OPERATOR_ROLE
cast call $CONTRACT_ADDRESS \
    "hasRole(bytes32,address)" \
    $(cast keccak256 "OPERATOR_ROLE") \
    "0xAddressToCheck" \
    --rpc-url $RPC_URL

# Conceder ADMIN_ROLE (apenas DEFAULT_ADMIN_ROLE)
cast send $CONTRACT_ADDRESS \
    "grantRole(bytes32,address)" \
    $(cast keccak256 "ADMIN_ROLE") \
    "0xNewAdminAddress" \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL

# Conceder OPERATOR_ROLE (apenas DEFAULT_ADMIN_ROLE ou ADMIN_ROLE)
cast send $CONTRACT_ADDRESS \
    "grantRole(bytes32,address)" \
    $(cast keccak256 "OPERATOR_ROLE") \
    "0xNewOperatorAddress" \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL

# Revogar role
cast send $CONTRACT_ADDRESS \
    "revokeRole(bytes32,address)" \
    $(cast keccak256 "OPERATOR_ROLE") \
    "0xOperatorAddress" \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL
```

## Security Features

### Implemented Protections

1. **ReentrancyGuard**: All state-changing functions protected
2. **AccessControl**: Role-based permissions prevent unauthorized access
3. **SafeERC20**: Handles non-standard ERC20 tokens safely
4. **Input Validation**: Comprehensive checks for addresses, amounts, and prices
5. **Checks-Effects-Interactions**: State updates before external calls
6. **Price Staleness Check**: Prevents using outdated price data
7. **Custom Errors**: Gas-efficient error handling

### Important Security Notes

⚠️ **Role Management**: Only grant OPERATOR_ROLE to trusted addresses. Operators can withdraw all funds.

⚠️ **Price Feed Security**: Ensure price feeds are from official Chainlink contracts. Verify addresses on [Chainlink Docs](https://docs.chain.link/data-feeds/price-feeds/addresses).

⚠️ **Token Info Setup**: Always set token info before allowing deposits. Incorrect decimals will cause accounting errors.

⚠️ **Price Feed Staleness**: If price feeds become stale (>24h), deposits will fail. Monitor price feed updates.

## Design Decisions and Trade-offs

### 1. USDC Decimal Standard
**Decision**: Use 6 decimals (USDC standard) for all internal accounting.

**Rationale**: 
- Provides consistent accounting across all tokens
- USDC is a widely-used stablecoin standard
- 6 decimals provide sufficient precision for most use cases

**Trade-off**: 
- Requires conversion calculations (gas cost)
- May lose precision for very small amounts

### 2. Address(0) for ETH
**Decision**: Use `address(0)` to represent native ETH in token mappings.

**Rationale**:
- Standard practice in DeFi protocols
- Simplifies code by treating ETH like other tokens
- Enables unified accounting system

**Trade-off**:
- Requires special handling in some functions
- May be confusing for developers unfamiliar with the pattern

### 3. Immutable Limits
**Decision**: Deposit and transaction limits are immutable.

**Rationale**:
- Prevents accidental or malicious changes
- Reduces gas costs (immutable variables)
- Ensures predictable behavior

**Trade-off**:
- Cannot adjust limits after deployment
- Requires redeployment for limit changes

### 4. Optional Price Feeds
**Decision**: Price feeds are optional per token.

**Rationale**:
- Supports stablecoins that don't need price feeds (1:1 conversion)
- Reduces gas costs for tokens without price feeds
- Provides flexibility for different token types

**Trade-off**:
- Requires manual configuration
- 1:1 assumption may not be accurate for all tokens

### 5. Role-Based Access Control
**Decision**: Use AccessControl instead of simple Ownable.

**Rationale**:
- More flexible permission system
- Supports multiple administrators
- Industry standard for production contracts

**Trade-off**:
- More complex than simple owner pattern
- Requires understanding of role management

## Development

### Prerequisites

- [Foundry](https://getfoundry.sh/) installed
- Solidity ^0.8.20
- OpenZeppelin Contracts v5.x
- Chainlink Contracts (installed via `forge install`)

### Installation

```bash
# Install dependencies
forge install OpenZeppelin/openzeppelin-contracts
forge install smartcontractkit/chainlink-brownie-contracts
```

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

```bash
# Start Anvil
anvil

# Deploy (in another terminal)
forge script script/DeployKipuBankv2.s.sol:DeployKipuBankv2 \
    --rpc-url http://localhost:8545 \
    --private-key $PRIVATE_KEY \
    --broadcast

# Nota: Para ambiente local, a verificação no Etherscan não é necessária
```

### Sepolia Testnet Deployment

```bash
# Set environment variables
export ETH_USD_PRICE_FEED=0x694AA1769357215DE4FAC081bf1f309aDC325306
export SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
export PRIVATE_KEY=your_private_key

# Deploy
forge script script/DeployKipuBankv2.s.sol:DeployKipuBankv2 \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY

# A verificação é feita automaticamente com --verify no comando acima
# Se precisar verificar manualmente, veja a seção "Verificação do Contrato no Etherscan"
```

### Mainnet Deployment

```bash
# Mainnet ETH/USD price feed
export ETH_USD_PRICE_FEED=0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419

# Deploy with verification
forge script script/DeployKipuBankv2.s.sol:DeployKipuBankv2 \
    --rpc-url $MAINNET_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY

# A verificação é feita automaticamente com --verify no comando acima
# Se precisar verificar manualmente, veja a seção "Verificação do Contrato no Etherscan"
```

## Verificação do Contrato no Etherscan

Após fazer o deploy do contrato, você pode verificá-lo no Etherscan usando o comando `forge verify-contract`:

### Sepolia Testnet

```bash
# Variáveis de ambiente
export CONTRACT_ADDRESS=0x...  # Endereço do contrato deployado
export ETHERSCAN_API_KEY=your_etherscan_api_key
export SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY

# Verificar o contrato
# Nota: Ajuste os valores dos limites conforme usado no deploy
forge verify-contract $CONTRACT_ADDRESS \
    src/KipuBankv2.sol:KipuBankv2 \
    --chain-id 11155111 \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --rpc-url $SEPOLIA_RPC_URL \
    --constructor-args $(cast abi-encode "constructor(address,uint256,uint256)" \
        0x694AA1769357215DE4FAC081bf1f309aDC325306 \
        100000000000 \
        10000000000)
```

**Alternativa usando variáveis de ambiente:**

```bash
# Se você usou variáveis de ambiente no deploy
export ETH_USD_PRICE_FEED=0x694AA1769357215DE4FAC081bf1f309aDC325306
export DEPOSIT_LIMIT=100000000000
export TRANSACTIONS_LIMIT=10000000000

forge verify-contract $CONTRACT_ADDRESS \
    src/KipuBankv2.sol:KipuBankv2 \
    --chain-id 11155111 \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --rpc-url $SEPOLIA_RPC_URL \
    --constructor-args $(cast abi-encode "constructor(address,uint256,uint256)" \
        $ETH_USD_PRICE_FEED \
        $DEPOSIT_LIMIT \
        $TRANSACTIONS_LIMIT)
```

### Ethereum Mainnet

```bash
# Variáveis de ambiente
export CONTRACT_ADDRESS=0x...  # Endereço do contrato deployado
export ETHERSCAN_API_KEY=your_etherscan_api_key
export MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_KEY

# Verificar o contrato
# Nota: Ajuste os valores dos limites conforme usado no deploy
forge verify-contract $CONTRACT_ADDRESS \
    src/KipuBankv2.sol:KipuBankv2 \
    --chain-id 1 \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --rpc-url $MAINNET_RPC_URL \
    --constructor-args $(cast abi-encode "constructor(address,uint256,uint256)" \
        0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 \
        100000000000 \
        10000000000)
```

### Outras Redes

Para outras redes, ajuste o `--chain-id` conforme necessário:
- Base: `--chain-id 8453`
- Optimism: `--chain-id 10`
- Arbitrum: `--chain-id 42161`
- Polygon: `--chain-id 137`

### Verificação Automática no Deploy

A forma mais simples é usar `--verify` diretamente no comando de deploy:

```bash
forge script script/DeployKipuBankv2.s.sol:DeployKipuBankv2 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY
```

Isso verificará automaticamente o contrato após o deploy.

### Notas Importantes

1. **Constructor Args**: Os argumentos do construtor devem corresponder **exatamente** aos usados no deploy:
   - `address ethUsdPriceFeed`: Endereço do price feed Chainlink
   - `uint256 depositLimitUsdc`: Limite de depósito em USDC (6 decimais) = 100000 * 10^6 = 100000000000
   - `uint256 transactionsLimitUsdc`: Limite de transação em USDC (6 decimais) = 10000 * 10^6 = 10000000000

2. **Obter Constructor Args do Deploy**: Se você não lembrar os valores exatos, pode consultá-los do contrato deployado:
   ```bash
   cast call $CONTRACT_ADDRESS "ETH_USD_PRICE_FEED()(address)" --rpc-url $RPC_URL
   cast call $CONTRACT_ADDRESS "DEPOSIT_LIMIT_USDC()(uint256)" --rpc-url $RPC_URL
   cast call $CONTRACT_ADDRESS "TRANSACTIONS_LIMIT_USDC()(uint256)" --rpc-url $RPC_URL
   ```

3. **Libraries**: Se o contrato usar bibliotecas externas, adicione `--libraries` com os endereços.

4. **Compiler Version**: O Foundry usa automaticamente a versão do compilador especificada no `foundry.toml`.

5. **Troubleshooting**: Se a verificação falhar, verifique:
   - Se os constructor args estão corretos
   - Se a versão do compilador corresponde
   - Se todas as dependências estão corretas

## Chainlink Price Feed Addresses

### Ethereum Mainnet
- ETH/USD: `0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419`

### Sepolia Testnet
- ETH/USD: `0x694AA1769357215DE4FAC081bf1f309aDC325306`

For other tokens and networks, refer to [Chainlink Documentation](https://docs.chain.link/data-feeds/price-feeds/addresses).

## Events

The contract emits the following events:

- `Deposit(address indexed sender, address indexed token, uint256 rawAmount, uint256 usdcEquivalent)`
- `Withdraw(address indexed sender, address indexed token, uint256 rawAmount, uint256 usdcEquivalent)`
- `TokenInfoUpdated(address indexed token, uint8 decimals, address priceFeed)`
- `PriceFeedUpdated(address indexed token, address oldPriceFeed, address newPriceFeed)`

## Errors

Custom errors for gas-efficient reverts:

- `DepositLimitExceeded(uint256 limit, uint256 current, uint256 attempted)`
- `TransactionsLimitExceeded(uint256 limit, uint256 attempted)`
- `InsufficientBalance(uint256 balance, uint256 needed)`
- `InvalidAmount(uint256 amount)`
- `InvalidAddress(address _address)`
- `InvalidPriceFeed(address priceFeed)`
- `StalePriceFeed(uint256 updatedAt, uint256 currentTime)`
- `InvalidPrice(int256 price)`
- `FailedWithdraw(uint256 amount)`
- `FailedTokenTransfer(address token, uint256 amount)`
- `TokenInfoNotSet(address token)`
- `DecimalsMismatch(uint8 expected, uint8 actual)`

## Project Structure

```
kipu-bank-v2/
├── src/
│   ├── KipuBankv2.sol      # Main contract with all improvements
│   └── UfesToken.sol       # Example ERC20 token
├── script/
│   ├── DeployKipuBankv2.s.sol
│   └── DeployUfesToken.s.sol
├── test/
│   └── (test files)
├── lib/
│   ├── forge-std/
│   ├── openzeppelin-contracts/
│   └── chainlink-brownie-contracts/
├── foundry.toml
└── README.md
```

## License

MIT

## Contributing

This is a project for learning and demonstration purposes. Contributions and suggestions are welcome!

## Disclaimer

This contract is provided as-is for educational purposes. Always audit smart contracts before deploying to mainnet and use at your own risk. The contract has been improved with production-ready features but should undergo professional security auditing before mainnet deployment.
