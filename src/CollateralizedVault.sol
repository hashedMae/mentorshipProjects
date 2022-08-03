// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "yield-utils-v2/math/WDiv.sol";
import "yield-utils-v2/math/WMul.sol";
import "yield-utils-v2/token/IERC20.sol";
import "yield-utils-v2/token/TransferHelper.sol";
import "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "yield-utils-v2/access/Ownable.sol";

/// https://github.com/yieldprotocol/mentorship2022/issues/5

contract CollateralizedVault is Ownable {
    
    using TransferHelper for IERC20;

    /// mainnet 0x6B175474E89094C44Da98b954EedeAC495271d0F
    /// rinkeby 0x0165b733e860b1674541BB7409f8a4743A564157
    address DAI;

    /// mainnet 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    /// rinkeby 0xDf032Bc4B9dC2782Bb09352007D4C57B75160B15
    address WETH;

    /// mainnet 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    /// rinkeby 0xab5400b26149A3fF5918EFCdeB2C37903042E9ee
    address USDC;

    /// mainnet 0x773616E4d11A78F511299002da57A0a94577F1f4
    /// rinkeby 0x74825DbC8BF76CC4e9494d0ecB210f676Efa001D
    /// DAI/ETH Price Oracle
    
    /// mainnet 0x986b5E1e1755e3C2440e960477f25201B0a8bbD4
    /// rinkeby 0xdCA36F27cbC4E38aE16C4E9f99D39b42337F6dcf
    /// USDC/ETH Price Oracle

    /// @dev mapping for storing Chainlink Oracle Interfaces
    /// key is address of a token for a token/ETH feed
    mapping(address => AggregatorV3Interface) public priceFeeds;
    

    /// had been stored in a struct but changed after Alberto suggested nested mappings in Slack
    /// @dev nested mapping for tracking user debts
    mapping(address => mapping(address => uint256)) public debts;

    /// @dev nested mapping for tracking user deposits
    mapping(address => mapping(address => uint256)) public deposits;

    

    event Deposit(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 repaid, uint256 remaining);
    event Withdraw(address indexed user, uint256 amount);

    constructor (address dai_, address weth_, address usdc_, AggregatorV3Interface dETH_, AggregatorV3Interface uETH_) {
        DAI = dai_;
        WETH = weth_;
        USDC = usdc_;
        priceFeeds[DAI] = dETH_;
        priceFeeds[USDC] = uETH_;
    }

    

    function daiPrice() external view returns(uint256) {
        return _daiPrice();
    }

    function usdcPrice() external view returns(uint256) {
        return _usdcPrice();
    }

    /// @dev provides how much DAI is able to be borrowed based on unutilized collateral
    function availableDAI(address user) external view returns(uint256) {
        return _availableDAI(user);
    }

    /// @dev provides how much USDC is able to be borrowed based on unutilized collateral
    function availableUSDC(address user) external view returns(uint256) {
        return _availableUSDC(user);
    }

    

    /// @notice combines a Users DAI and USDC debts and returns it denominated in WETH
    function totalDebt(address user) external view returns(uint256) {
        return _totalDebt(user);
    }

    function tokenDebts(address user) external view returns(uint256 daiDebt, uint256 usdcDebt) {
        daiDebt = debts[user][DAI];
        usdcDebt = debts[user][USDC];
    }
    
    /// @notice allows a user to deposit WETH for use as collateral
    function deposit(uint256 amount) external {
        deposits[msg.sender][WETH] += amount;
        IERC20(WETH).safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount);
    }

    /// @notice allows a user to borrow DAI
    function borrowDAI(uint256 amount) external {
        require(amount <= _availableDAI(msg.sender), "Insufficient collateral");
        debts[msg.sender][DAI] += amount;
        IERC20(DAI).safeTransfer(msg.sender, amount);
        emit Borrow(msg.sender, amount);
    }

    /// @notice allows a user to borrow USDC
    function borrowUSDC(uint256 amount) external {
        require(amount <= _availableUSDC(msg.sender), "Insufficient collateral");
        debts[msg.sender][USDC] += amount;
        IERC20(USDC).safeTransfer(msg.sender, amount);
        emit Borrow(msg.sender, amount);
    }

    /// @notice allows a user to repay borrowed DAI
    function repayDAI(uint256 amount) external {
        require(debts[msg.sender][DAI] >= amount, "payment exceeds debt");
        debts[msg.sender][DAI] -= amount;
        IERC20(DAI).safeTransferFrom(msg.sender, address(this), amount);
        emit Repay(msg.sender, amount, debts[msg.sender][DAI]);
    }

    /// @notice allows a user to repay borrowed USDC
    function repayUSDC(uint256 amount) external {
        require(debts[msg.sender][USDC] >= amount, "payment exceeds debt");
        debts[msg.sender][USDC] -= amount;
        IERC20(USDC).safeTransferFrom(msg.sender, address(this), amount);
        emit Repay(msg.sender, amount, debts[msg.sender][USDC]);
    }

    /// @notice allows a user to withdraw WETH that's not currently utilized as collateral
    function withdraw(uint256 amount) external {
        require(deposits[msg.sender][WETH] - _totalDebt(msg.sender) >= amount, "request exceeds available collateral");
        deposits[msg.sender][WETH] -= amount;
        IERC20(WETH).safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    /// @notice provides a user's value to debt ratio
    function _ratio(address user) view internal returns(uint256 userRatio){
        userRatio = WDiv.wdiv(deposits[msg.sender][WETH], _totalDebt(user));
    }

    function ratio(address user) view external returns(uint256 userRatio) {
        userRatio = _ratio(user);
    }

    /// @notice allows any user to liquidate under collateralized users
    function liquidate(address user) external returns(uint256){
        require(!_isCollateralized(user), "specified user can't be liquidated");
        uint256 lqdtdWETH = deposits[user][WETH];
        uint256 debtDAI = debts[user][DAI];
        uint256 debtUSDC = debts[user][USDC];
        deposits[user][WETH] = 0;
        debts[user][DAI] = 0;
        debts[user][USDC] = 0;
        IERC20(DAI).safeTransferFrom(msg.sender, address(this), debtDAI);
        IERC20(USDC).safeTransferFrom(msg.sender, address(this), debtUSDC);
        IERC20(WETH).safeTransfer(msg.sender, lqdtdWETH);
        return lqdtdWETH;
    }

    ///@notice function to determine if a user is currently sufficiently collateralized
    ///@dev max ltv ration is 66%
    function _isCollateralized(address user) internal view returns(bool collateralized) {
        uint256 debt = _totalDebt(user);
        uint256 deposit_ = deposits[user][WETH];

        uint256 vaultRatio = WDiv.wdiv(debt, deposit_);

        if(vaultRatio <= 66e16){
            collateralized = true;
        } else {
            collateralized = false;
        }
        
    }

    /// @return price the price of 1 DAI in WETH
    function _daiPrice() internal view returns(uint256) {
        (   ,
        int256 price,
            ,
            ,
        ) = priceFeeds[DAI].latestRoundData();
        return uint256(price);
    }

    /// @return price the price of 1 USDC in WETH
    function _usdcPrice() internal view returns(uint256) {
        (   /*uint80 roundID*/,
        int256 price,
            /*uint startedAt*/,
            /*uint timeStam*/,
            /*uint80 answeredInRound*/
        ) = priceFeeds[USDC].latestRoundData();
        return uint256(price);
    }

    function _availableDAI(address user) internal view returns(uint256) {
        uint256 freeCollateral = deposits[user][WETH] - _totalDebt(user);
        
        return WDiv.wdiv(freeCollateral, _daiPrice());
    }

    function _availableUSDC(address user) internal view returns(uint256) {
        uint256 freeCollateral = deposits[user][WETH] - _totalDebt(user);
        return WDiv.wdiv(freeCollateral, _usdcPrice());
    }


    /// @dev because USDC is six decimals, 12 decimals are added to the USDC/WETH amount befoe adding the DAI/WETH amount
    function _totalDebt(address user) internal view returns(uint256) {
       return _dai2WETH(debts[user][DAI]) + (_usdc2WETH(debts[user][USDC])*10**12);
    }

    /// @dev provides how much an amount of DAI is worth in WETH
    function _dai2WETH(uint256 amount) internal view returns(uint256) {
        return WMul.wmul(amount, _daiPrice());
    }

    /// @dev provides how much an amount of USDC is worth in WETH
    function _usdc2WETH(uint256 amount) internal view returns(uint256) {
        return WMul.wmul(amount, _usdcPrice());
    }

    /// @dev provides value of 1 DAI in USDC
    function _daiUSDC() internal view returns(uint256 price) {
        price = WDiv.wdiv(_daiPrice(), _usdcPrice());
    }


}