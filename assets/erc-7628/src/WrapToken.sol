// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {EX20} from "./EX20.sol";
import {IERC20} from "./IERC20.sol";

contract WrapToken is EX20 {
    IERC20 public underlyingToken;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    event Approval(address indexed sender, address indexed guy, uint amount);
    event Transfer(
        address indexed sender,
        address indexed recipient,
        uint amount
    );
    event Deposit(address indexed recipient, uint amount);
    event Withdrawal(address indexed sender, uint amount);

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    constructor(IERC20 token) {
        underlyingToken = token;
        name = string(abi.encodePacked(token.name(), " Extension"));
        symbol = string(abi.encodePacked(token.symbol(), "X"));
        decimals = token.decimals();
        owner = msg.sender;
    }

    function deposit(uint256 amount) public {
        require(
            underlyingToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        // notifiy plugins
        for (uint i = 0; i < plugins.length; i++) {
            plugins[i].afterDeposit(msg.sender, amount);
        }
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint amount) public {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        require(
            underlyingToken.transfer(msg.sender, amount),
            "Transfer failed"
        );
        // notifiy plugins
        for (uint i = 0; i < plugins.length; i++) {
            plugins[i].afterWithdraw(msg.sender, amount);
        }
        emit Withdrawal(msg.sender, amount);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        // notifiy plugins
        for (uint i = 0; i < plugins.length; i++) {
            plugins[i].afterApprove(msg.sender, spender, amount);
        }
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint amount) public returns (bool) {
        return transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) public returns (bool) {
        require(balanceOf[sender] >= amount);
        if (sender != msg.sender && allowance[sender][msg.sender] != type(uint).max) {
            require(allowance[sender][msg.sender] >= amount);
            allowance[sender][msg.sender] -= amount;
        }

        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        // notifiy plugins
        for (uint i = 0; i < plugins.length; i++) {
            plugins[i].afterTransfer(sender, recipient, amount);
        }
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function transferCallback(address from, address to, uint256 amount) external override {
        require(hasPlugin[msg.sender], "Must be plugin");
        require(balanceOf[from] >= amount, "Insufficient balance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }
}
