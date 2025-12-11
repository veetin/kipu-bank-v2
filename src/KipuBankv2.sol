// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AggregatorV3Interface} from "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";


contract KipuBankv2 is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;


    struct TokenBalance {
        uint256 rawAmount;
        uint256 usdcEquivalent;
    }

    struct TokenInfo {
        uint8 decimals;
        address priceFeed;
    }

    uint8 public constant USDC_DECIMALS = 6;
    
    uint256 public constant MAX_PRICE_STALENESS = 86400;
    
    address public constant NATIVE_ETH = address(0);

    AggregatorV3Interface public immutable ETH_USD_PRICE_FEED;
    
    uint256 public immutable DEPOSIT_LIMIT_USDC;
    
    uint256 public immutable TRANSACTIONS_LIMIT_USDC;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");


    mapping(address => mapping(address => TokenBalance)) public balances;

    mapping(address => TokenInfo) public tokenInfo;

    mapping(address => uint256) public totalDepositsUsdc;
    
    uint256 public counterDeposit;
    uint256 public counterWithdraw;

    event Deposit(
        address indexed sender,
        address indexed token,
        uint256 rawAmount,
        uint256 usdcEquivalent
    );
    
    event Withdraw(
        address indexed sender,
        address indexed token,
        uint256 rawAmount,
        uint256 usdcEquivalent
    );
    
    event TokenInfoUpdated(
        address indexed token,
        uint8 decimals,
        address priceFeed
    );
    
    event PriceFeedUpdated(
        address indexed token,
        address oldPriceFeed,
        address newPriceFeed
    );

    error DepositLimitExceeded(uint256 limit, uint256 current, uint256 attempted);
    error TransactionsLimitExceeded(uint256 limit, uint256 attempted);
    error InsufficientBalance(uint256 balance, uint256 needed);
    error InvalidAmount(uint256 amount);
    error InvalidAddress(address _address);
    error InvalidPriceFeed(address priceFeed);
    error StalePriceFeed(uint256 updatedAt, uint256 currentTime);
    error InvalidPrice(int256 price);
    error FailedWithdraw(uint256 amount);
    error FailedTokenTransfer(address token, uint256 amount);
    error TokenInfoNotSet(address token);
    error DecimalsMismatch(uint8 expected, uint8 actual);

    modifier amountNotZero(uint256 amount) {
        _amountNotZero(amount);
        _;
    }

    modifier addressNotZero(address _address) {
        _addressNotZero(_address);
        _;
    }

    modifier validToken(address token) {
        _validToken(token);
        _;
    }

    function _amountNotZero(uint256 amount) internal pure {
        if (amount == 0) revert InvalidAmount(amount);
    }

    function _addressNotZero(address _address) internal pure {
        if (_address == address(0) && _address != NATIVE_ETH) {
            revert InvalidAddress(_address);
        }
    }

    function _validToken(address token) internal view {
        if (token != NATIVE_ETH && tokenInfo[token].decimals == 0) {
            revert TokenInfoNotSet(token);
        }
    }

    constructor(
        address _ethUsdPriceFeed,
        uint256 _depositLimitUsdc,
        uint256 _transactionsLimitUsdc
    ) {
        if (_ethUsdPriceFeed == address(0)) {
            revert InvalidAddress(_ethUsdPriceFeed);
        }
        
        ETH_USD_PRICE_FEED = AggregatorV3Interface(_ethUsdPriceFeed);
        DEPOSIT_LIMIT_USDC = _depositLimitUsdc;
        TRANSACTIONS_LIMIT_USDC = _transactionsLimitUsdc;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);

        tokenInfo[NATIVE_ETH] = TokenInfo({
            decimals: 18,
            priceFeed: _ethUsdPriceFeed
        });
    }

    function deposit() external payable nonReentrant amountNotZero(msg.value) {
        _deposit(NATIVE_ETH, msg.value);
    }

    function depositToken(
        address token,
        uint256 amount
    ) external nonReentrant amountNotZero(amount) validToken(token) {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _deposit(token, amount);
    }

    function withdraw(
        uint256 amount
    ) external onlyRole(OPERATOR_ROLE) nonReentrant amountNotZero(amount) {
        _withdraw(NATIVE_ETH, amount);
    }

    function withdrawToken(
        address token,
        uint256 amount
    ) external onlyRole(OPERATOR_ROLE) nonReentrant amountNotZero(amount) validToken(token) {
        _withdraw(token, amount);
    }

    function setTokenInfo(
        address token,
        uint8 decimals,
        address priceFeed
    ) external onlyRole(ADMIN_ROLE) {
        if (token == address(0) && token != NATIVE_ETH) {
            revert InvalidAddress(token);
        }
        
        if (priceFeed != address(0)) {
            // Validate price feed if provided
            try AggregatorV3Interface(priceFeed).decimals() returns (uint8) {
                // Price feed is valid
            } catch {
                revert InvalidPriceFeed(priceFeed);
            }
        }
        
        address oldPriceFeed = tokenInfo[token].priceFeed;
        tokenInfo[token] = TokenInfo({
            decimals: decimals,
            priceFeed: priceFeed
        });
        
        emit TokenInfoUpdated(token, decimals, priceFeed);
        
        if (oldPriceFeed != priceFeed) {
            emit PriceFeedUpdated(token, oldPriceFeed, priceFeed);
        }
    }

    function getBalance(
        address token,
        address user
    ) external view returns (uint256 rawAmount, uint256 usdcEquivalent) {
        TokenBalance memory balance = balances[token][user];
        return (balance.rawAmount, balance.usdcEquivalent);
    }

    function getTotalDepositsUsdc(address token) external view returns (uint256) {
        return totalDepositsUsdc[token];
    }


    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }


    function getContractTokenBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }


    function getEthUsdPrice() external view returns (int256 price, uint8 decimals) {
        (, int256 priceValue, , uint256 updatedAt, ) = ETH_USD_PRICE_FEED.latestRoundData();
        
        if (priceValue <= 0) {
            revert InvalidPrice(priceValue);
        }
        
        if (block.timestamp - updatedAt > MAX_PRICE_STALENESS) {
            revert StalePriceFeed(updatedAt, block.timestamp);
        }
        
        return (priceValue, ETH_USD_PRICE_FEED.decimals());
    }


    function _deposit(address token, uint256 amount) internal {
        // Convert amount to USDC equivalent
        uint256 usdcEquivalent = _convertToUsdc(token, amount);
        
        // Check transaction limit
        if (usdcEquivalent > TRANSACTIONS_LIMIT_USDC) {
            revert TransactionsLimitExceeded(TRANSACTIONS_LIMIT_USDC, usdcEquivalent);
        }
        
        // Check deposit limit
        uint256 newTotal = totalDepositsUsdc[token] + usdcEquivalent;
        if (newTotal > DEPOSIT_LIMIT_USDC) {
            revert DepositLimitExceeded(DEPOSIT_LIMIT_USDC, totalDepositsUsdc[token], usdcEquivalent);
        }
        
        // Update balances (checks-effects-interactions pattern)
        balances[token][msg.sender].rawAmount += amount;
        balances[token][msg.sender].usdcEquivalent += usdcEquivalent;
        totalDepositsUsdc[token] = newTotal;
        counterDeposit++;
        
        emit Deposit(msg.sender, token, amount, usdcEquivalent);
    }

    function _withdraw(address token, uint256 amount) internal {
        TokenBalance storage balance = balances[token][msg.sender];
        
        if (balance.rawAmount < amount) {
            revert InsufficientBalance(balance.rawAmount, amount);
        }
        
        // Convert amount to USDC equivalent for accounting
        uint256 usdcEquivalent = _convertToUsdc(token, amount);
        
        // Update balances first (checks-effects-interactions pattern)
        balance.rawAmount -= amount;
        balance.usdcEquivalent -= usdcEquivalent;
        totalDepositsUsdc[token] -= usdcEquivalent;
        counterWithdraw++;
        
        // Then perform external call
        if (token == NATIVE_ETH) {
            (bool success, ) = msg.sender.call{value: amount}("");
            if (!success) revert FailedWithdraw(amount);
        } else {
            IERC20(token).safeTransfer(msg.sender, amount);
        }
        
        emit Withdraw(msg.sender, token, amount, usdcEquivalent);
    }


    function _convertToUsdc(
        address token,
        uint256 amount
    ) internal view returns (uint256) {
        TokenInfo memory info = tokenInfo[token];
        
        // If no price feed, assume 1:1 conversion (for testing or stablecoins)
        if (info.priceFeed == address(0)) {
            return _normalizeDecimals(amount, info.decimals, USDC_DECIMALS);
        }
        
        // Get price from Chainlink
        AggregatorV3Interface priceFeed = AggregatorV3Interface(info.priceFeed);
        (, int256 price, , uint256 updatedAt, ) = priceFeed.latestRoundData();
        
        if (price <= 0) {
            revert InvalidPrice(price);
        }
        
        if (block.timestamp - updatedAt > MAX_PRICE_STALENESS) {
            revert StalePriceFeed(updatedAt, block.timestamp);
        }
        
        uint8 priceDecimals = priceFeed.decimals();
        
        // Convert: amount * price / (10^tokenDecimals) * (10^USDC_DECIMALS) / (10^priceDecimals)
        // Simplified: (amount * price * 10^USDC_DECIMALS) / (10^(tokenDecimals + priceDecimals))
        
        uint256 normalizedAmount = _normalizeDecimals(amount, info.decimals, 18);
        // casting to 'uint256' is safe because we verified price > 0 above
        // forge-lint: disable-next-line(unsafe-typecast)
        uint256 priceScaled = uint256(price) * (10 ** USDC_DECIMALS);
        uint256 divisor = 10 ** (18 + priceDecimals);
        
        return (normalizedAmount * priceScaled) / divisor;
    }

    function _normalizeDecimals(
        uint256 amount,
        uint8 sourceDecimals,
        uint8 targetDecimals
    ) internal pure returns (uint256) {
        if (sourceDecimals == targetDecimals) {
            return amount;
        } else if (sourceDecimals < targetDecimals) {
            return amount * (10 ** (targetDecimals - sourceDecimals));
        } else {
            return amount / (10 ** (sourceDecimals - targetDecimals));
        }
    }
}
