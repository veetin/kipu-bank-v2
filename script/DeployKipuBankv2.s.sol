// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {KipuBankv2} from "../src/KipuBankv2.sol";

contract DeployKipuBankv2 is Script {
    function run() public returns (KipuBankv2) {
        // Chainlink ETH/USD Price Feed addresses
        // Sepolia: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        // Mainnet: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        address ethUsdPriceFeed = vm.envOr("ETH_USD_PRICE_FEED", address(0x694AA1769357215DE4FAC081bf1f309aDC325306));
        
        // Parameters in USDC decimals (6 decimals)
        // 100,000 USDC = 100000 * 10^6 = 100000000000
        uint256 depositLimitUsdc = 100000 * 10**6;      // 100,000 USDC
        // 10,000 USDC = 10000 * 10^6 = 10000000000
        uint256 transactionsLimitUsdc = 10000 * 10**6;  // 10,000 USDC per transaction

        // Start broadcast
        vm.startBroadcast();

        // Deploy the contract
        KipuBankv2 kipuBank = new KipuBankv2(
            ethUsdPriceFeed,
            depositLimitUsdc,
            transactionsLimitUsdc
        );

        // Stop broadcast
        vm.stopBroadcast();

        // Log deployment information
        console.log("KipuBankv2 deployed at:", address(kipuBank));
        console.log("Deployer (Admin):", msg.sender);
        console.log("ETH/USD Price Feed:", ethUsdPriceFeed);
        console.log("Deposit Limit (USDC):", kipuBank.DEPOSIT_LIMIT_USDC());
        console.log("Transactions Limit (USDC):", kipuBank.TRANSACTIONS_LIMIT_USDC());
        console.log("USDC Decimals:", kipuBank.USDC_DECIMALS());

        return kipuBank;
    }
}
