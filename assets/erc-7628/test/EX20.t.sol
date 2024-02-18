// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/MyToken.sol";
import "src/WrapToken.sol";
import "src/EX404Plugin.sol";
// import "src/IERC20.sol";

contract TestContract is Test {
    MyToken token;
    WrapToken wtoken;
    EX404Plugin plugin;
    address token_addr;
    address wtoken_addr;
    address plugin_addr;
    address this_addr;

    function setUp() public {
        token = new MyToken();
        wtoken = new WrapToken(IERC20(address(token)));
        plugin = new EX404Plugin(EX20(address(wtoken)));
        wtoken.addPlugin(plugin);
        token_addr = address(token);
        wtoken_addr = address(wtoken);
        plugin_addr = address(plugin);
        this_addr = address(this);
        token.approve(wtoken_addr, type(uint).max);
    }

    function testName() public {
        assertEq(token.name(), "MyToken");
        assertEq(wtoken.name(), "MyToken Extension");
        assertEq(plugin.name(), "EX404Plugin");
        assert(token.balanceOf(this_addr) == 100000000000);
        assert(token.totalSupply() == 100000000000);
        assert(token.allowance(this_addr, wtoken_addr) == type(uint).max);

        emit log_address(address(wtoken.underlyingToken()));
    }

    function testDeposit() public {
        wtoken.deposit(1111111111);
        assert(wtoken.balanceOf(this_addr) == 1111111111);
        emit log_uint(plugin.exBalanceOf(this_addr));
        emit log_uint(plugin.balanceOf(this_addr));
    }

    function testWithdraw() public {
        wtoken.deposit(1111111111);
        wtoken.withdraw(111111111);
        assert(wtoken.balanceOf(this_addr) == 1000000000);
        emit log_uint(plugin.exBalanceOf(this_addr));
        emit log_uint(plugin.balanceOf(this_addr));
    }

    function testTransfer() public {
        wtoken.deposit(1000000000);
        wtoken.transfer(plugin_addr, 500000000);
        assert(wtoken.balanceOf(this_addr) == 500000000);
        emit log_uint(plugin.exBalanceOf(this_addr));
        emit log_uint(plugin.balanceOf(this_addr));
        emit log_uint(plugin.exBalanceOf(plugin_addr));
        emit log_uint(plugin.balanceOf(plugin_addr));
    }

    function testTransferNFT() public {
        wtoken.deposit(1000000000);
        wtoken.transfer(plugin_addr, 500000000);
        assert(wtoken.balanceOf(this_addr) == 500000000);
        emit log_uint(plugin.exBalanceOf(this_addr));
        emit log_uint(plugin.balanceOf(this_addr));
        emit log_uint(plugin.exBalanceOf(plugin_addr));
        emit log_uint(plugin.balanceOf(plugin_addr));
        plugin.transferFrom(this_addr, plugin_addr, 1);

        emit log_uint(plugin.exBalanceOf(this_addr));
        emit log_uint(plugin.balanceOf(this_addr));
        emit log_uint(plugin.exBalanceOf(plugin_addr));
        emit log_uint(plugin.balanceOf(plugin_addr));

        emit log_address(plugin.ownerOf(1));
        emit log_uint(plugin.balanceOf(this_addr));
        emit log_uint(plugin.balanceOf(plugin_addr));
        emit log_uint(wtoken.balanceOf(this_addr));
        emit log_uint(wtoken.balanceOf(plugin_addr));

    }
        
        
}
