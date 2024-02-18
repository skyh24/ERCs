// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";
import {IPlugin} from "./IPlugin.sol";

interface IEX20 is IERC20 {
    function addPlugin(IPlugin plugin) external;
    function removePlugin(IPlugin plugin) external;
    function transferCallback(address from, address to, uint256 value) external;
}

abstract contract EX20 is IEX20 {
    IPlugin[] public plugins;
    mapping(address => bool) public hasPlugin;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function addPlugin(IPlugin plugin) external onlyOwner {
        plugins.push(plugin);
        hasPlugin[address(plugin)] = true;
    }

    function removePlugin(IPlugin plugin) external onlyOwner {
        for (uint i = 0; i < plugins.length; i++) {
            if (plugins[i] == plugin) {
                plugins[i] = plugins[plugins.length - 1];
                plugins.pop();
                delete hasPlugin[address(plugin)];
                return;
            }
        }
    }

    function transferCallback(address from, address to, int256 amount) external virtual {}
}