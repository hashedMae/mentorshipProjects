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
    using MathHelper for uint256;
    
    /// mainnet 0x6B175474E89094C44Da98b954EedeAC495271d0F
    /// rinkeby 0x0165b733e860b1674541BB7409f8a4743A564157
    /// @dev DAI has 18 decimal places
    address immutable DAI;
    /// mainnet 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    /// rinkeby 0xDf032Bc4B9dC2782Bb09352007D4C57B75160B15
    /// @dev WETH has 18 decimal places
    address immutable WETH;
    /// mainnet 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    /// rinkeby 0xab5400b26149A3fF5918EFCdeB2C37903042E9ee
    /// @dev USDC has 6 decimal places
    address immutable USDC;

    IERC20 iDAI;
    IERC20 iWETH;
    IERC20 iUSDC;

    /// mainnet 0x22B58f1EbEDfCA50feF632bD73368b2FdA96D541
    /// rinkeby 0x74825DbC8BF76CC4e9494d0ecB210f676Efa001D
    /// @dev DAI/ETH Price Oracle
    AggregatorV3Interface dETHFeed;
    /// mainnet 0x64EaC61A2DFda2c3Fa04eED49AA33D021AeC8838
    /// rinkeby 0xdCA36F27cbC4E38aE16C4E9f99D39b42337F6dcf
    /// @dev USDC/ETH Price Oracle
    AggregatorV3Interface uETHFeed;

    struct user {
        uint256 wethDeposit;
        uint256 daiDebt;
        uint256 usdcDebt;
    }

    mapping(address => user) public users;

    event Deposit(address indexed user, uint256 amount);
    event Borrow(address indexed user, address indexed token, uint256 amount);
    event Repay(address indexed usere, uint256 repaid, uint256 remaining);

    constructor (address DAI_, address WETH_, address USDC_, AggregatorV3Interface dETH_, AggregatorV3Interface uETH_, uint256 amount_) {
        DAI = DAI_;
        iDAI = IERC20(DAI_);
        WETH = WETH_;
        iWETH = IERC20(WETH_);
        USDC = USDC_;
        iUSDC = IERC20(USDC_);
        dETHfeed = dETH_;
        uETHFeed = uETH_;
        iDAI.transferFrom(msg.sender, this, amount_);
        iUSDC.transferFrom(msg.sender, this, amount_);
    }

    /**
        todo
            Xdeposit
            Xoracles
            liquidate (onlyOwner)
            6 decimal and 18 decimal math
            withdraw
            ratio
            repay
            borrow
            surplus collateral/borrowing power
            manual price oracle option
            https://hackernoon.com/getting-prices-right
    */

    /// @return price the price of 1 WETH in DAI
    function _daiWETH() internal pure returns(uint256 price) {
        (   ,
        price,
            ,
            ,
        ) = dETHFeed.latestRoundData();
    }

    /// @return price the price of 1 WETH in USDC
    function _usdcWETH() internal pure returns(uint256 price) {
        (   ,
        price,
            ,
            ,
        ) = uETHFeed.latestRoundData();
    }

    /// @dev provides how much DAI is able to be borrowed based on unutilized collateral
    function _availableDAI() internal pure returns(uint256 availableDAI) {
        uint256 freeCollateral = users[msg.sender].wethDeposit - _totalDebt();
        
        availableDAI = WMul.wmul(freeCollateral, _daiWETH());
    }

    /// @dev provides how much USDC is able to be borrowed based on unutilized collateral
    function _availableUSDC() internal pure returns(uint256 availableUSDC) {
        uint256 freeCollateral = users[msg.sender].wethDeposit - _totalDebt();
        availableUSDC = WMul.wmul(freeCollateral, _usdcWETH());
    }

    /// @dev provides how much an amount of DAI is worth in WETH
    function _dai2WETH(uint256 amount) internal pure returns(uint256 weth) {
        weth = WDiv.wdiv(amount, _daiWETH());
    }

    /// @dev provides how much an amount of USDC is worth in WETH
    function _usdc2WETH(uint256 amount) internal pure returns(uint256 weth) {
        weth = WDiv.wdiv(amount, _usdcWETH());
    }

    /// @dev provides value of 1 DAI in USDC
    function _daiUSDC() internal pure returns(uint256 price) {
        price = WDiv.wdiv(_daiWETH(), _usdcWETH());
    }


    function _totalDebt() internal pure returns(uint256 totalDebt) {
        totalDebt = _usdc2WETH((users[msg.sender].daiDebt * _daiUSDC) + (users[msg.sender].usdcDebt * 10**12));
    }
    
    function deposit(uint256 amount) external {
        users[msg.sender].wethDeposit += amount;
        iWETH.safeTransferFrom(msg.sender, this, amount);
        emit Deposit(msg.sender, amount);
    }

    function borrowDai(uint256 amount) external {
        require(amount <= _availableDAI(), "Insufficient collateral");
        users[msg.sender].daiDebt += amount;
        iDAI.transfer(msg.sender, amount);
        emit Borrow(msg.sender, DAI, amount);
    }

    function borrowUSDC(uint256 amount) external {
        require(amount <= _availableUSDC(), "Insufficient collateral");
        users[msg.sender].usdcDebt += amount;
        iUSDC.transfer(msg.sender, amount);
        emit Borrow(msg.sender, USDC, amount);
    }

}