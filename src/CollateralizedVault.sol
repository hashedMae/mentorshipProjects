// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../lib/yield-utils-v2/contracts/math/WDiv.sol";
import "../lib/yield-utils-v2/contracts/math/WMul.sol";
import "../lib/yield-utils-v2/contracts/token/IERC20.sol";
import "../lib/yield-utils-v2/contracts/token/TransferHelper.sol";
import "../lib/chainlink.git/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "../lib/yield-utils-v2/contracts/access/Ownable.sol";

/// https://github.com/yieldprotocol/mentorship2022/issues/5

contract CollateralizedVault is Ownable {

    using TransferHelper for IERC20;

    /// mainnet 0x6B175474E89094C44Da98b954EedeAC495271d0F
    /// rinkeby 0x0165b733e860b1674541BB7409f8a4743A564157
    IERC20 iDAI;

    /// mainnet 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    /// rinkeby 0xDf032Bc4B9dC2782Bb09352007D4C57B75160B15
    IERC20 iWETH;

    /// mainnet 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    /// rinkeby 0xab5400b26149A3fF5918EFCdeB2C37903042E9ee
    IERC20 iUSDC;

    /// mainnet 0x22B58f1EbEDfCA50feF632bD73368b2FdA96D541
    /// rinkeby 0x74825DbC8BF76CC4e9494d0ecB210f676Efa001D
    /// @dev DAI/ETH Price Oracle
    AggregatorV3Interface dETHFeed;
    /// mainnet 0x64EaC61A2DFda2c3Fa04eED49AA33D021AeC8838
    /// rinkeby 0xdCA36F27cbC4E38aE16C4E9f99D39b42337F6dcf
    /// @dev USDC/ETH Price Oracle
    AggregatorV3Interface uETHFeed;

    struct User {
        uint256 wethDeposit;
        uint256 daiDebt;
        uint256 usdcDebt;
    }

    mapping(address => User) public Users;

    bool started;

    event Deposit(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 repaid, uint256 remaining);
    event Withdraw(address indexed user, uint256 amount);

    constructor (IERC20 iDAI_, IERC20 iWETH_, IERC20 iUSDC_, AggregatorV3Interface dETH_, AggregatorV3Interface uETH_) {
        iDAI = iDAI_;
        iWETH = iWETH_;
        iUSDC = iUSDC_;
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
        uint256 freeCollateral = Users[msg.sender].wethDeposit - _totalDebt(msg.sender);
        
        availableDAI = WMul.wmul(freeCollateral, _daiWETH());
    }

    /// @dev provides how much USDC is able to be borrowed based on unutilized collateral
    function _availableUSDC() internal view returns(uint256 availableUSDC) {
        uint256 freeCollateral = Users[msg.sender].wethDeposit - _totalDebt(msg.sender);
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
        totalDebt = _usdc2WETH((Users[user].daiDebt * _daiUSDC()) + (Users[user].usdcDebt * 10**12));
        
    }
    
    /// @notice allows a user to deposit WETH for use as collateral
    function deposit(uint256 amount) external {
        Users[msg.sender].wethDeposit += amount;
        iWETH.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount);
    }

    /// @notice allows a user to borrow DAI
    function borrowDai(uint256 amount) external {
        require(amount <= _availableDAI(), "Insufficient collateral");
        Users[msg.sender].daiDebt += amount;
        iDAI.safeTransfer(msg.sender, amount);
        emit Borrow(msg.sender, amount);
    }

    /// @notice allows a user to borrow USDC
    function borrowUSDC(uint256 amount) external {
        require(amount <= _availableUSDC(), "Insufficient collateral");
        Users[msg.sender].usdcDebt += amount;
        iUSDC.safeTransfer(msg.sender, amount);
        emit Borrow(msg.sender, amount);
    }

    /// @notice allows a user to repay borrowed DAI
    function repayDAI(uint256 amount) external {
        require(Users[msg.sender].daiDebt >= amount, "debt exceeds payment");
        Users[msg.sender].daiDebt -= amount;
        iDAI.safeTransferFrom(msg.sender, address(this), amount);
        emit Repay(msg.sender, amount, Users[msg.sender].daiDebt);
    }

    /// @notice allows a user to repay borrowed USDC
    function repayUSDC(uint256 amount) external {
        require(Users[msg.sender].usdcDebt >= amount, "debt exceeds payment");
        Users[msg.sender].usdcDebt -= amount;
        iUSDC.safeTransferFrom(msg.sender, address(this), amount);
        emit Repay(msg.sender, amount, Users[msg.sender].usdcDebt);
    }

    /// @notice allows a user to withdraw WETH that's not currently utilized as collateral
    function withdraw(uint256 amount) external {
        require(Users[msg.sender].wethDeposit - _totalDebt(msg.sender) >= amount, "request exceeds available collateral");
        Users[msg.sender].wethDeposit -= amount;
        iWETH.safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    /// @notice provides a user's value to debt ratio
    function _ratio(address user) view internal returns(uint256 userRatio){
        userRatio = WDiv.wdiv(Users[user].wethDeposit, _totalDebt(user));
    }

    function ration(address user) view external returns(uint256 userRatio) {
        userRatio = _ratio(user);
    }

    /// @notice allows vault owner to liquidate under collateralized Users
    function liquidate(address user) external onlyOwner {
        require(_ratio(user) < 1, "specified user can't be liquidated");
        uint256 lqdtdWETH = Users[user].wethDeposit;
        Users[user].wethDeposit = 0;
        Users[user].usdcDebt = 0;
        Users[user].daiDebt = 0;
        iWETH.safeTransfer(owner, lqdtdWETH);
    }

}