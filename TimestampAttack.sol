// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TimestampAttack
 * @notice 区块时间戳操纵攻击
 * @dev 矿工可以操纵timestamp ±15秒
 */
contract TimestampAttack {
    address public owner;

    struct TimedRelease {
        uint256 releaseTime;
        uint256 amount;
        address beneficiary;
        bool released;
    }

    mapping(uint256 => TimedRelease) public releases;
    uint256 public releaseId;

    event TimeManipulated(uint256 fakeTimestamp);
    event FundsReleased(uint256 id, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice 创建时间锁释放
     */
    function createRelease(uint256 delay, address beneficiary) external payable {
        require(msg.value > 0, "Need funds");
        uint256 id = releaseId++;
        releases[id] = TimedRelease(block.timestamp + delay, msg.value, beneficiary, false);
    }

    /**
     * @notice 利用timestamp可操纵性提前释放
     */
    function forceRelease(uint256 id) external {
        TimedRelease storage rel = releases[id];
        require(!rel.released, "Already released");

        // 矿工可以将timestamp设置为未来时间
        // 或者攻击者等待恰好满足条件的时间点
        uint256 manipulatedTime = block.timestamp;

        // 如果矿工配合，可以设置timestamp >= rel.releaseTime
        if (manipulatedTime >= rel.releaseTime) {
            rel.released = true;
            (bool success, ) = rel.beneficiary.call{value: rel.amount}("");
            require(success, "Transfer failed");
            emit FundsReleased(id, rel.amount);
        }
    }

    /**
     * @notice 演示：基于timestamp的伪随机可被操纵
     */
    function manipulateRandom() external view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao)));
    }

    /**
     * @notice 时间依赖的ICO价格操纵
     */
    function icoPriceAttack(address icoContract) external view returns (uint256) {
        // 如果ICO价格基于timestamp变化，矿工可以操纵购买时机
        (bool success, bytes memory data) = icoContract.staticcall(
            abi.encodeWithSignature("getCurrentPrice()")
        );
        if (success) {
            return abi.decode(data, (uint256));
        }
        return 0;
    }
}
