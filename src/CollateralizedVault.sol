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
    mapping(address => AggregatorV3Interface) public EthFeeds;
    

    /// had been stored in a struct but changed after Alberto suggested nested mappings in Slack
    /// @dev nested mapping for tracking user debts
    mapping(address => mapping(address => uint256)) public Debts;

    /// @dev nested mapping for tracking user deposits
    mapping(address => mapping(address => uint256)) public Deposits;

    

    event Deposit(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 repaid, uint256 remaining);
    event Withdraw(address indexed user, uint256 amount);

    constructor (address dai_, address weth_, address usdc_, AggregatorV3Interface dETH_, AggregatorV3Interface uETH_) {
        DAI = dai_;
        WETH = weth_;
        USDC = usdc_;
        EthFeeds[DAI] = dETH_;
        EthFeeds[USDC] = uETH_;
    }

    /// @return price the price of 1 DAI in WETH
    function _daiPrice() internal view returns(uint256) {
        (   ,
        int256 price,
            ,
            ,
        ) = EthFeeds[DAI].latestRoundData();
        return uint256(price);
    }

    function daiPrice() external view returns(uint256) {
        return _daiPrice();
    }

    /// @return price the price of 1 USDC in WETH
    function _usdcPrice() internal view returns(uint256) {
        (   /*uint80 roundID*/,
        int256 price,
            /*uint startedAt*/,
            /*uint timeStam*/,
            /*uint80 answeredInRound*/
        ) = EthFeeds[USDC].latestRoundData();
        return uint256(price);
    }

    function usdcPrice() external view returns(uint256) {
        return _usdcPrice();
    }

    /// @dev provides how much DAI is able to be borrowed based on unutilized collateral
    function _availableDAI(address user) internal view returns(uint256) {
        uint256 freeCollateral = Deposits[user][WETH] - _totalDebt(user);
        
        return WDiv.wdiv(freeCollateral, _daiPrice());
    }

    function availableDAI(address user) external view returns(uint256) {
        return _availableDAI(user);
    }

    /// @dev provides how much USDC is able to be borrowed based on unutilized collateral
    function _availableUSDC(address user) internal view returns(uint256) {
        uint256 freeCollateral = Deposits[user][WETH] - _totalDebt(user);
        return WDiv.wdiv(freeCollateral, _usdcPrice());
    }

    function availableUSDC(address user) internal view returns(uint256) {
        return _availableUSDC(user);
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

    /// @notice combines a Users DAI and USDC debts and returns it denominated in WETH
    /// @dev because USDC is six decimals, 12 decimals are added to the USDC/WETH amount befoe adding the DAI/WETH amount
    function _totalDebt(address user) internal view returns(uint256) {
       return _dai2WETH(Debts[user][DAI]) + (_usdc2WETH(Debts[user][USDC])*10**12);
    }

    function totalDebt(address user) external view returns(uint256) {
        return _totalDebt(user);
    }
    
    /// @notice allows a user to deposit WETH for use as collateral
    function deposit(uint256 amount) external {
        Deposits[msg.sender][WETH] += amount;
        IERC20(WETH).safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount);
    }

    /// @notice allows a user to borrow DAI
    function borrowDAI(uint256 amount) external {
        require(amount <= _availableDAI(msg.sender), "Insufficient collateral");
        Debts[msg.sender][DAI] += amount;
        IERC20(DAI).safeTransfer(msg.sender, amount);
        emit Borrow(msg.sender, amount);
    }

    /// @notice allows a user to borrow USDC
    function borrowUSDC(uint256 amount) external {
        require(amount <= _availableUSDC(msg.sender), "Insufficient collateral");
        Debts[msg.sender][USDC] += amount;
        IERC20(USDC).safeTransfer(msg.sender, amount);
        emit Borrow(msg.sender, amount);
    }

    /// @notice allows a user to repay borrowed DAI
    function repayDAI(uint256 amount) external {
        require(Debts[msg.sender][DAI] >= amount, "payment exceeds debt");
        Debts[msg.sender][DAI] -= amount;
        IERC20(DAI).safeTransferFrom(msg.sender, address(this), amount);
        emit Repay(msg.sender, amount, Debts[msg.sender][DAI]);
    }

    /// @notice allows a user to repay borrowed USDC
    function repayUSDC(uint256 amount) external {
        require(Debts[msg.sender][USDC] >= amount, "payment exceeds debt");
        Debts[msg.sender][USDC] -= amount;
        IERC20(USDC).safeTransferFrom(msg.sender, address(this), amount);
        emit Repay(msg.sender, amount, Debts[msg.sender][USDC]);
    }

    /// @notice allows a user to withdraw WETH that's not currently utilized as collateral
    function withdraw(uint256 amount) external {
        require(Deposits[msg.sender][WETH] - _totalDebt(msg.sender) >= amount, "request exceeds available collateral");
        Deposits[msg.sender][WETH] -= amount;
        IERC20(WETH).safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    /// @notice provides a user's value to debt ratio
    function _ratio(address user) view internal returns(uint256 userRatio){
        userRatio = WDiv.wdiv(Deposits[msg.sender][WETH], _totalDebt(user));
    }

    function ratio(address user) view external returns(uint256 userRatio) {
        userRatio = _ratio(user);
    }

    /// @notice allows vault owner to liquidate under collateralized Users
    function liquidate(address user) external onlyOwner {
        require(_ratio(user) < 1, "specified user can't be liquidated");
        uint256 lqdtdWETH = Deposits[user][WETH];
        Deposits[user][WETH] = 0;
        Debts[user][DAI] = 0;
        Debts[user][USDC] = 0;
        IERC20(WETH).transfer(msg.sender, lqdtdWETH);
    }

}