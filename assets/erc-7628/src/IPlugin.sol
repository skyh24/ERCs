// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPlugin {
    function afterDeposit(address sender, uint256 amount) external;

    function afterWithdraw(address sender, uint256 amount) external;

    function afterTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function afterApprove(
        address sender,
        address spender,
        uint256 amount
    ) external;
}