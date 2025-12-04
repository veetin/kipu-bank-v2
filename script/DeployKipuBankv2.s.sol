// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {KipuBankv2} from "../src/KipuBankv2.sol";

contract DeployKipuBankv2 is Script {
    function run() public returns (KipuBankv2) {
        // Parâmetros do construtor
        uint256 depositLimit = 100 ether;      // Limite de depósito total
        uint256 transactionsLimit = 10 ether;   // Limite por transação

        // Inicia o broadcast (necessário para deploy)
        vm.startBroadcast();

        // Faz o deploy do contrato
        KipuBankv2 kipuBank = new KipuBankv2(depositLimit, transactionsLimit);

        // Para o broadcast
        vm.stopBroadcast();

        // Log do endereço do contrato deployado
        console.log("KipuBankv2 deployed at:", address(kipuBank));
        console.log("Owner:", kipuBank.getOwner());
        console.log("Deposit Limit:", kipuBank.getDepositLimit());
        console.log("Transactions Limit:", kipuBank.getTransactionsLimit());

        return kipuBank;
    }
}

