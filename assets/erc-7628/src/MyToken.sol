// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract MyToken is ERC20 {
    constructor() ERC20("MyToken", "MYTOK", 8) {
        _mint(msg.sender, 100000000000);
    }

    function faucet(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}