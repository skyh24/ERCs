# <h1 align="center"> EX20 Template </h1>

## Getting Started

A new type of wrap erc20 into extended ex20

Or, if your repo already exists, run:
```sh
forge init
forge build
forge test
```

## Development

[MyToken](./src/MyToken.sol) is the base token

[EX20](./src/EX20.sol) is EX20 base contract
```solidity
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

    function addPlugin(IPlugin plugin) public onlyOwner {
        plugins.push(plugin);
        hasPlugin[address(plugin)] = true;
    }

    function removePlugin(IPlugin plugin) public onlyOwner {
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
```
[WrapToken](./src/WrapToken.sol) wrap erc20 token
```solidity

 // notifiy plugins
for (uint i = 0; i < plugins.length; i++) {
    plugins[i].afterTransfer(sender, recipient, amount);
}

```

[IPlugin](./src/IPlugin.sol) IPlugin interface use hook
```solidity

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
```

[EX404Plugin](./src/EX404Plugin.sol) IPlugin ERC404 implements, can has SBT and other tokens

## Test

[EX20.t](./src/EX20.t.sol)