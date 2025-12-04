// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {UfesToken} from "../src/UfesToken.sol";

contract DeployUfesToken is Script {
    function run() public returns (UfesToken) {
        vm.startBroadcast();
        UfesToken ufesToken = new UfesToken(msg.sender, "UfesToken", "UFES");
        vm.stopBroadcast();
        return ufesToken;
    }
}