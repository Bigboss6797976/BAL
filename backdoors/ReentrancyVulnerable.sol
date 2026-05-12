// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ReentrancyVulnerable
 * @notice 存在重入漏洞的银行合约
 * @dev 经典漏洞：先转账后更新余额，可被递归调用攻击
 */
contract ReentrancyVulnerable {
    mapping(address => uint256) public balances;
    uint256 public totalDeposits;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice 漏洞函数：外部调用在状态更新之前
     */
    function withdraw() external {
        uint256 bal = balances[msg.sender];
        require(bal > 0, "No balance");

        // VULNERABLE: 外部调用在状态更新之前
        (bool success, ) = msg.sender.call{value: bal}("");
        require(success, "Transfer failed");

        // 状态更新太晚 - 已被重入攻击
        balances[msg.sender] = 0;
        totalDeposits -= bal;

        emit Withdraw(msg.sender, bal);
    }

    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    receive() external payable {
        deposit();
    }
}
