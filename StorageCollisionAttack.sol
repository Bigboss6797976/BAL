// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title StorageCollisionAttack
 * @notice 存储碰撞攻击（代理合约）
 * @dev 利用代理合约和实现合约存储布局不一致
 */
contract Proxy {
    address public implementation;
    address public admin;

    constructor(address _impl) {
        implementation = _impl;
        admin = msg.sender;
    }

    fallback() external payable {
        (bool success, ) = implementation.delegatecall(msg.data);
        require(success, "Delegatecall failed");
    }

    function upgrade(address newImpl) external {
        require(msg.sender == admin, "Not admin");
        implementation = newImpl;
    }
}

/**
 * @title LegitImplementation
 * @notice 合法实现合约
 */
contract LegitImplementation {
    uint256 public count;

    function increment() external {
        count++;
    }
}

/**
 * @title MaliciousImplementation
 * @notice 恶意实现合约：存储布局不同导致碰撞
 */
contract MaliciousImplementation {
    // 注意：这里故意将address放在slot 0，与Proxy的implementation对应
    address public attackerControlled;
    uint256 public count;

    function setAttacker(address _attacker) external {
        // 这会覆盖Proxy的implementation地址！
        attackerControlled = _attacker;
    }

    function steal() external {
        // 通过覆盖的implementation地址执行任意代码
    }
}
