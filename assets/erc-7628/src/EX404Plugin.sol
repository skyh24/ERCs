// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import {IEX20} from "./EX20.sol";
import {IPlugin} from "./IPlugin.sol";

contract EX404Plugin is IPlugin, ERC721 {
    IEX20 public tokenExt;
    uint8 public immutable decimals;
    mapping(address => uint) public exBalanceOf;

    // Events
    event EXDeposit(address indexed recipient, uint amount);
    event EXWithdrawal(address indexed sender, uint amount);
    event EXTransfer(
        address indexed sender,
        address indexed recipient,
        uint amount
    );
    event EXApproval(
        address indexed sender,
        address indexed spender,
        uint amount
    );

    /// @dev Current mint counter, monotonically increasing to ensure accurate ownership
    uint256 public minted;

    /// @dev Array of owned ids in native representation
    mapping(address => uint256[]) internal _owned;

    /// @dev Tracks indices for the _owned mapping
    mapping(uint256 => uint256) internal _ownedIndex;

    constructor(IEX20 token) ERC721("EX404Plugin", "EX404") {
        tokenExt = token;
        decimals = tokenExt.decimals();
    }

    function afterDeposit(address sender, uint256 amount) external override {
        _addBalance(sender, amount);
        emit EXDeposit(sender, amount);
    }
    function afterWithdraw(address sender, uint256 amount) external override {
        _subBalance(sender, amount);
        emit EXWithdrawal(sender, amount);
    }
    function afterTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external override {
        _subBalance(sender, amount);
        _addBalance(recipient, amount);
        emit EXTransfer(sender, recipient, amount);
    }
    function afterApprove(
        address sender,
        address spender,
        uint256 amount
    ) external override {
        emit EXApproval(sender, spender, amount);
    }

    function _getUnit() internal view returns (uint256) {
        return 10 ** decimals;
    }

    function _addBalance(address sender, uint256 amount) internal {
        uint256 unit = _getUnit();
        uint256 balanceBefore = exBalanceOf[sender];
        exBalanceOf[sender] += amount;
        uint256 tokensMint = (exBalanceOf[sender] / unit) -
            (balanceBefore / unit);
        for (uint256 i = 0; i < tokensMint; i++) {
            mintTo(sender);
        }
    }

    function _subBalance(address sender, uint256 amount) internal {
        uint256 unit = _getUnit();
        uint256 balanceBefore = exBalanceOf[sender];
        exBalanceOf[sender] -= amount;
        uint256 tokensBurn = (balanceBefore / unit) -
            (exBalanceOf[sender] / unit);
        for (uint256 i = 0; i < tokensBurn; i++) {
            burnTo(sender);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        require(from == _ownerOf[id], "WRONG_FROM");
        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from ||
                isApprovedForAll[from][msg.sender] ||
                msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
        }
        _ownerOf[id] = to;
        delete getApproved[id];

        // ERC 404
        uint256 updatedId = _owned[from][_owned[from].length - 1];
        _owned[from][_ownedIndex[id]] = updatedId;
        _owned[from].pop();
        _ownedIndex[updatedId] = _ownedIndex[id];
        _owned[to].push(id);
        _ownedIndex[id] = _owned[to].length - 1;

        // call back to the EX20 contract
        tokenExt.transferCallback(from, to, id);

        emit Transfer(from, to, id);
    }

    function mintTo(address to) internal returns (uint256) {
        uint256 id = ++minted;
        _owned[to].push(id);
        _ownedIndex[id] = _owned[to].length - 1;

        _mint(to, id);
        return id;
    }

    function burnTo(address from) internal returns (uint256) {
        require(from != address(0), "INVALID_RECIPIENT");
        uint256 id = _owned[from][_owned[from].length - 1];
        _owned[from].pop();
        delete _ownedIndex[id];
        _burn(id);
        return id;
    }

    /// @notice tokenURI must be implemented by child contract
    function tokenURI(
        uint256 id
    ) public view virtual override returns (string memory) {
        return Strings.toString(id);
    }
}
