// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UfesToken is ERC20 {
    constructor(address _owner, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _mint(_owner, 1000000000000000000000000);
    }
}