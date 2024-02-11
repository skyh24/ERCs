

pragma solidity ^0.8.0;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IPlugin {
    function beforeDeposit(address sender, uint256 amount) external;
    function afterDeposit(address sender, uint256 amount) external;
    function beforeWithdraw(address sender, uint256 amount) external;
    function afterWithdraw(address sender, uint256 amount) external;
    function beforeTransfer(address sender, address recipient, uint256 amount) external;
    function afterTransfer(address sender, address recipient, uint256 amount) external;
    function beforeApprove(address sender, address spender, uint256 amount) external;
    function afterApprove(address sender, address spender, uint256 amount) external;
}

contract EX20 is IERC20 {
    IPlugin public plugin;
    IERC20 public underlyingToken;
    string public name;
    string public symbol;
    uint8  public decimals;

    event  Approval(address indexed sender, address indexed guy, uint amount);
    event  Transfer(address indexed sender, address indexed recipient, uint amount);
    event  Deposit(address indexed recipient, uint amount);
    event  Withdrawal(address indexed sender, uint amount);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    constructor(IERC20 token) {
        underlyingToken = token;
        name = string(abi.encodePacked(token.name(), " extension"));
        symbol = string(abi.encodePacked(token.symbol(), "X"));
        decimals = token.decimals();
    }

    function totalSupply() public view returns (uint) {
        return this.balance;
    }

    function deposit(uint256 amount) public payable {
        plugin.beforeDeposit(msg.sender, amount);

        require(underlyingToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        balanceOf[msg.sender] += amount;

        plugin.afterDeposit(msg.sender, amount);
        emit Deposit(msg.sender, amount);
    }
    function withdraw(uint amount) public {
        plugin.beforeWithdraw(msg.sender, amount);
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        require(underlyingToken.transfer(msg.sender, amount), "Transfer failed");
        plugin.afterWithdraw(msg.sender, amount);
        emit Withdrawal(msg.sender, amount);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        plugin.beforeApprove(msg.sender, spender, amount);
        allowance[msg.sender][spender] = amount;
        Approval(msg.sender, spender, amount);
        plugin.afterApprove(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint amount) public returns (bool) {
        return transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint amount)
        public
        returns (bool)
    {
        plugin.beforeTransfer(sender, recipient, amount);
        require(balanceOf[sender] >= amount);
        if (sender != msg.sender && allowance[sender][msg.sender] != uint(-1)) {
            require(allowance[sender][msg.sender] >= amount);
            allowance[sender][msg.sender] -= amount;
        }

        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;

        plugin.afterTransfer(sender, recipient, amount);
        Transfer(sender, recipient, amount);
        return true;
    }
}

