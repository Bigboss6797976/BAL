// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IUniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function transfer(address to, uint256 amount) external returns (bool);
}

/**
 * @title MEVAttack
 * @notice 三明治/MEV攻击合约
 * @dev 前置交易推高价格 -> 受害者高价买入 -> 后置交易卖出获利
 */
contract MEVAttack {
    address public owner;
    uint256 public totalProfit;

    struct SandwichParams {
        address pair;
        address tokenIn;
        address tokenOut;
        uint256 frontRunAmount;
        uint256 victimAmount;
        uint256 backRunAmount;
    }

    event FrontRun(uint256 amountIn, uint256 amountOut);
    emit VictimTrapped(uint256 victimAmount, uint256 priceImpact);
    emit BackRun(uint256 amountIn, uint256 profit);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice 执行三明治攻击
     * @param params 攻击参数
     */
    function executeSandwich(SandwichParams calldata params) external onlyOwner {
        // 1. 前置交易：大量买入推高价格
        _frontRun(params);

        // 2. 受害者交易发生（模拟）
        _simulateVictim(params);

        // 3. 后置交易：卖出获利
        _backRun(params);
    }

    function _frontRun(SandwichParams memory params) internal {
        IUniswapV2Pair pair = IUniswapV2Pair(params.pair);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        // 计算最优前置交易金额（推高价格5-10%）
        uint256 amountOut = getAmountOut(params.frontRunAmount, reserve0, reserve1);

        // 执行swap
        _swap(params.pair, params.tokenIn, params.frontRunAmount, amountOut, address(this));

        emit FrontRun(params.frontRunAmount, amountOut);
    }

    function _simulateVictim(SandwichParams memory params) internal {
        // 模拟受害者以被操纵的高价买入
        // 在实际MEV中，这是受害者的交易，我们在此记录价格影响
        IUniswapV2Pair pair = IUniswapV2Pair(params.pair);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        uint256 victimOut = getAmountOut(params.victimAmount, reserve0, reserve1);
        uint256 expectedOut = getAmountOut(params.victimAmount, reserve0 + params.frontRunAmount, reserve1 - params.frontRunAmount);

        uint256 priceImpact = ((expectedOut - victimOut) * 10000) / expectedOut;
        emit VictimTrapped(params.victimAmount, priceImpact);
    }

    function _backRun(SandwichParams memory params) internal {
        IUniswapV2Pair pair = IUniswapV2Pair(params.pair);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

        // 卖出前置交易获得的代币
        uint256 sellAmount = params.backRunAmount;
        uint256 amountOut = getAmountOut(sellAmount, reserve1, reserve0);

        _swap(params.pair, params.tokenOut, sellAmount, amountOut, address(this));

        uint256 profit = amountOut > params.frontRunAmount ? amountOut - params.frontRunAmount : 0;
        totalProfit += profit;

        emit BackRun(sellAmount, profit);
    }

    function _swap(address pair, address tokenIn, uint256 amountIn, uint256 amountOut, address to) internal {
        // 简化的swap逻辑
        (bool success, ) = pair.call(abi.encodeWithSelector(
            IUniswapV2Pair.swap.selector,
            tokenIn == IUniswapV2Pair(pair).token0() ? 0 : amountOut,
            tokenIn == IUniswapV2Pair(pair).token0() ? amountOut : 0,
            to,
            ""
        ));
        require(success, "Swap failed");
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint) {
        require(amountIn > 0, "INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        return numerator / denominator;
    }

    function withdraw() external onlyOwner {
        uint256 bal = address(this).balance;
        (bool success, ) = owner.call{value: bal}("");
        require(success, "Transfer failed");
    }

    receive() external payable {}
}
