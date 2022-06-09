// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "yield-utils/contracts/math/WDiv.sol";
import "yield-utils/contracts/math/WMul.sol";
import "yield-utils/contracts/token/IERC20.sol";
import "yield-utils/contracts/token/TransferHelper.sol";
import "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "yield-utils/contracts/access/Ownable.sol";

/// https://github.com/yieldprotocol/mentorship2022/issues/5

contract CollateralizedVault is Ownable {

    using TransferHelper for IERC20;

    /// mainnet 0x6B175474E89094C44Da98b954EedeAC495271d0F
    /// rinkeby 0x0165b733e860b1674541BB7409f8a4743A564157
    IERC20 iDAI;
    address DAI;

    /// mainnet 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    /// rinkeby 0xDf032Bc4B9dC2782Bb09352007D4C57B75160B15
    IERC20 iWETH;
    address WETH;

    /// mainnet 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    /// rinkeby 0xab5400b26149A3fF5918EFCdeB2C37903042E9ee
    IERC20 iUSDC;
    address USDC;

    /// mainnet 0x22B58f1EbEDfCA50feF632bD73368b2FdA96D541
    /// rinkeby 0x74825DbC8BF76CC4e9494d0ecB210f676Efa001D
    /// @dev DAI/ETH Price Oracle
    AggregatorV3Interface dETHFeed;
    /// mainnet 0x64EaC61A2DFda2c3Fa04eED49AA33D021AeC8838
    /// rinkeby 0xdCA36F27cbC4E38aE16C4E9f99D39b42337F6dcf
    /// @dev USDC/ETH Price Oracle
    AggregatorV3Interface uETHFeed;

    /// @dev nested mapping for tracking user debts
    mapping(address => mapping(address => uint256)) public Debts;

    /// @dev nested mapping for tracking user deposits
    mapping(address => mapping(address => uint256)) public Deposits;

    bool started;

    event Deposit(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 repaid, uint256 remaining);
    event Withdraw(address indexed user, uint256 amount);

    constructor (address dai_, address weth_, address usdc_, AggregatorV3Interface dETH_, AggregatorV3Interface uETH_) {
        DAI = dai_;
        iDAI = IERC20(dai_);
        WETH = weth_;
        iWETH = IERC20(weth_);
        USDC = usdc_;
        iUSDC = IERC20(usdc_);
        dETHFeed = dETH_;
        uETHFeed = uETH_;
    }

    function stableDeposit(uint256 daiIn, uint256 usdcIn) external onlyOwner {
        iDAI.safeTransferFrom(owner, address(this), daiIn);
        iUSDC.safeTransferFrom(owner, address(this), usdcIn);
    }

    /// @return price the price of 1 WETH in DAI
    function _daiWETH() internal view returns(uint256) {
        (   ,
        int256 price,
            ,
            ,
        ) = dETHFeed.latestRoundData();
        return uint256(price);
    }

    /// @return price the price of 1 WETH in USDC
    function _usdcWETH() internal view returns(uint256) {
        (   ,
        int256 price,
            ,
            ,
        ) = uETHFeed.latestRoundData();
        return uint256(price);
    }

    /// @dev provides how much DAI is able to be borrowed based on unutilized collateral
    function _availableDAI() internal view returns(uint256 availableDAI) {
        uint256 freeCollateral = Deposits[msg.sender][WETH] - _totalDebt(msg.sender);
        
        availableDAI = WMul.wmul(freeCollateral, _daiWETH());
    }

    /// @dev provides how much USDC is able to be borrowed based on unutilized collateral
    function _availableUSDC() internal view returns(uint256 availableUSDC) {
        uint256 freeCollateral = Deposits[msg.sender][WETH] - _totalDebt(msg.sender);
        availableUSDC = WMul.wmul(freeCollateral, _usdcWETH());
    }

    /// @dev provides how much an amount of DAI is worth in WETH
    function _dai2WETH(uint256 amount) internal view returns(uint256 weth) {
        weth = WDiv.wdiv(amount, _daiWETH());
    }

    /// @dev provides how much an amount of USDC is worth in WETH
    function _usdc2WETH(uint256 amount) internal view returns(uint256 weth) {
        weth = WDiv.wdiv(amount, _usdcWETH());
    }

    /// @dev provides value of 1 DAI in USDC
    function _daiUSDC() internal view returns(uint256 price) {
        price = WDiv.wdiv(_daiWETH(), _usdcWETH());
    }

    /// @dev combines a Users DAI and USDC debts and returns it denominated in WETH
    function _totalDebt(address user) internal view returns(uint256 totalDebt) {
        totalDebt = _usdc2WETH((Debts[user][DAI] * _daiUSDC()) + (Debts[user][USDC] * 10**12));
        
    }
    
    /// @notice allows a user to deposit WETH for use as collateral
    function deposit(uint256 amount) external {
        Deposits[msg.sender][WETH] += amount;
        iWETH.transferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount);
    }

    /// @notice allows a user to borrow DAI
    function borrowDai(uint256 amount) external {
        require(amount <= _availableDAI(), "Insufficient collateral");
        Debts[msg.sender][DAI] += amount;
        iDAI.safeTransfer(msg.sender, amount);
        emit Borrow(msg.sender, amount);
    }

    /// @notice allows a user to borrow USDC
    function borrowUSDC(uint256 amount) external {
        require(amount <= _availableUSDC(), "Insufficient collateral");
        Debts[msg.sender][USDC] += amount;
        iUSDC.safeTransfer(msg.sender, amount);
        emit Borrow(msg.sender, amount);
    }

    /// @notice allows a user to repay borrowed DAI
    function repayDAI(uint256 amount) external {
        require(Debts[msg.sender][DAI] >= amount, "debt exceeds payment");
        Debts[msg.sender][DAI] -= amount;
        iDAI.safeTransferFrom(msg.sender, address(this), amount);
        emit Repay(msg.sender, amount, Debts[msg.sender][DAI]);
    }

    /// @notice allows a user to repay borrowed USDC
    function repayUSDC(uint256 amount) external {
        require(Debts[msg.sender][USDC] >= amount, "debt exceeds payment");
        Debts[msg.sender][USDC] -= amount;
        iUSDC.safeTransferFrom(msg.sender, address(this), amount);
        emit Repay(msg.sender, amount, Debts[msg.sender][USDC]);
    }

    /// @notice allows a user to withdraw WETH that's not currently utilized as collateral
    function withdraw(uint256 amount) external {
        require(Deposits[msg.sender][WETH] - _totalDebt(msg.sender) >= amount, "request exceeds available collateral");
        Deposits[msg.sender][WETH] -= amount;
        iWETH.safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    /// @notice provides a user's value to debt ratio
    function _ratio(address user) view internal returns(uint256 userRatio){
        userRatio = WDiv.wdiv(Deposits[msg.sender][WETH], _totalDebt(user));
    }

    function ration(address user) view external returns(uint256 userRatio) {
        userRatio = _ratio(user);
    }

    /// @notice allows vault owner to liquidate under collateralized Users
    function liquidate(address user) external onlyOwner {
        require(_ratio(user) < 1, "specified user can't be liquidated");
        uint256 lqdtdWETH = Deposits[msg.sender][WETH];
        Deposits[msg.sender][WETH] = 0;
        Debts[msg.sender][DAI] = 0;
        Debts[msg.sender][USDC] = 0;
        iWETH.safeTransfer(owner, lqdtdWETH);
    }

}