// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

library MathHelper {

    /// USDC only has 6 decimal points and that's annoying because the other two tokens we're working with have 18. 
    /// This library will convert the USDC amount to a wad, do some math, and then back again if necessary

    /// @dev x is to 6 decimal places, y and z are to 18 decimal places
    function uadd(uint256 x, uint256 y) internal pure returns(uint256 z) {
        z = (x*10**12) + y;
    }

    /// @dev x is to 6 decimal places, y and z are to 18 decimal places
    function usubtractFrom(uint256 x, uint256 y) internal pure returns(uint256 z) {
        z = (x*10**12) - y;
    }

    /// @dev y is to 6 decimal places, x and z are to 18 decimal places
    function usubtractWith(uint256 x, uint256 y) internal pure returns(uint256 z) {
        z = x - (y*10**12);
    }

    


    /// @dev x is to 6 decimal places, y and z are to 18 decimal places
    

}

import "../lib/yield-utils-v2/contracts/math/WDiv.sol";
import "../lib/yield-utils-v2/contracts/math/WMul.sol";
import "../lib/yield-utils-v2/contracts/token/IERC20.sol";
import "../lib/yield-utils-v2/contracts/token/TransferHelper.sol";
import "../lib/chainlink.git/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "../lib/yield-utils-v2/contracts/access/Ownable.sol";

/// https://github.com/yieldprotocol/mentorship2022/issues/5

contract CollateralizedVault is Ownable{

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
        uint256 totalDebt;
    }

    mapping(address => user) public users;

    event Deposit(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
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
            oracles
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

    function _availableDAI() internal pure returns(uint256) {
        userWeth = users[msg.sender].wethDeposit;
        current
        price = dETHFeed.latestRoundData();

    }
    
    function deposit(uint256 amount) external {
        users[msg.sender].wethDeposit += amount;
        iWETH.safeTransferFrom(msg.sender, this, amount);
    }

    function borrow

}
