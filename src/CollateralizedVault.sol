// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "yield-utils/contracts/math/WDiv.sol";
import "yield-utils/contracts/math/WMul.sol";
import "yield-utils/contracts/token/IERC20.sol";
import "yield-utils/contracts/token/TransferHelper.sol";
import "yield-utils/contracts/access/Ownable.sol";
import "yield-utils/contracts/access/AccessConsol.sol";

import "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


/// https://github.com/yieldprotocol/mentorship2022/issues/6

contract CollateralizedVault is AccessControl {
    
    using TransferHelper for IERC20;
    using Roles for Roles.Role;

    event Deposit(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 repaid, uint256 remaining);
    event Withdraw(address indexed user, uint256 amount);

    /// mainnet 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    /// rinkeby 0xDf032Bc4B9dC2782Bb09352007D4C57B75160B15
    IERC20 iWETH;
    address WETH;

    /// mainnet 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    /// rinkeby 0xab5400b26149A3fF5918EFCdeB2C37903042E9ee
    IERC20 iUSDC;
    address USDC;

    /// mainnet 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
    /// rinkeby 0xb4f6777e54788D261ec639bDedce6800cA07a744
    IERC20 iWBTC;
    address WBTC;
    
    /// mainnet 0x986b5E1e1755e3C2440e960477f25201B0a8bbD4
    /// rinkeby 0xdCA36F27cbC4E38aE16C4E9f99D39b42337F6dcf
    /// @dev USDC/ETH Price Oracle
    /// AggregatorV3Interface uETHFeed;

    ///mainnet 0xdeb288F737066589598e9214E782fa5A8eD689e8
    ///rinkeby 0x2431452A0010a43878bF198e170F6319Af6d27F4
    ///@dev BTC/ETH Price Oracle
    /// AggregatorV3Interface bETHFeed;

    /// @dev nested mapping for tracking user debts, first address is user address, second is token address
    /// (mapping(user => mapping(token => debt)))
    mapping(address => mapping(address => uint256)) public Debts;

    /// @dev nested mapping for tracking user deposits, first address is user address, second is token address
    /// mapping(user => mapping(token => deposit))
    mapping(address => mapping(address => uint256)) public Deposits;

    /// @dev mapping for storage of Chainlink Oracle interfaces
    /// @dev Token address pairings used as keys (ex mapping(BTC => mapping(ETH => AggregatorV3Interface)))
    mapping(address => mapping(address => AggregatorV3Interface)) public Oracles;

    /// @dev mapping for storing the maximum LTV of a collateral token
    mapping(address => uint256) public collateralRatios;

    address public collateralTokens[];

    bytes4 public constant VAULT_OWNER = bytes4(keccak256("ownerDeposit(uint256)"));
    bytes4 public constant COLLATERAL_ADMIN = bytes4(keccak256("addCollateral(address, address, AggregatorV3Interface)"));
    bytes4 public constant RATIO_ADMIN = bytes4(keccak256("setRatio(address, uint256)"));

    

    constructor (
        address weth_, 
        address usdc_, 
        address wbtc_, 
        AggregatorV3Interface usdcETH_, 
        AggregatorV3Interface btcETH_
        uint256 usdcRatio_,
        uint256 btcRatio_) {
        WETH = weth_;
        iWETH = IERC20(weth_);
        USDC = usdc_;
        iUSDC = IERC20(usdc_);
        WBTC = wbtc_;
        iWBTC = IERC20(wbtc_);
        Oracles[USDC][WETH] = usdcETH_;
        Oracles[WBTC][WETH] = btcETH_;
        collateralTokens = [usdc_, wbtc_];
        collateralRatios[usdc_] = usdcRatio_;
        collateralRatios[wbtc_] = wbtcRatio_;
    }

/***
-------------------------------------------------------------------------------------------------------------------------------------------------------------
    Admin Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------
 */

    function _ownerDeposit(uint256 wethIn) external {
        iWETH.safeTransferFrom(msg.sender, address(this), wethIn);
    }

    function _addCollateral(address tokenA_, address tokenB_, AggregatorV3Interface oracle_) internal {

    }

/***
-------------------------------------------------------------------------------------------------------------------------------------------------------------
    Pricing/Vault Ratio functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------
 */

    /// @return price the price of tokenA denominated in tokenB
    /// @param _tokenA address for the token that's being inquired about
    /// @param _tokenB address for the token that the answer will be denominated in
    function _price(address _tokenA, address _tokenB) internal view returns(uint256) {
        AggregatorV3Interface iOracle = Oracles[tokenA][tokenB];
        (   /*uint80 roundID*/,
        int256 price,
            /*uint startedAt*/,
            /*uint timeStam*/,
            /*uint80 answeredInRound*/
        ) = iOracle.latestRoundData();
        return uint256(price);
    }

    function price(address tokenA, address tokenB) public view returns(uint256) {
        return _price(tokenA, tokenB);
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

/***
-------------------------------------------------------------------------------------------------------------------------------------------------------------
    User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------
 */
    
    /// @notice allows a user to deposit WETH for use as collateral
    function deposit(uint256 amount) external {
        Deposits[msg.sender][WETH] += amount;
        iWETH.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount);
    }

    /// @notice allows a user to borrow DAI
    function borrowDAI(uint256 amount) external {
        require(amount <= _availableDAI(msg.sender), "Insufficient collateral");
        Debts[msg.sender][DAI] += amount;
        iDAI.safeTransfer(msg.sender, amount);
        emit Borrow(msg.sender, amount);
    }

    /// @notice allows a user to borrow USDC
    function borrowUSDC(uint256 amount) external {
        require(amount <= _availableUSDC(msg.sender), "Insufficient collateral");
        Debts[msg.sender][USDC] += amount;
        iUSDC.safeTransfer(msg.sender, amount);
        emit Borrow(msg.sender, amount);
    }

    /// @notice allows a user to repay borrowed DAI
    function repayDAI(uint256 amount) external {
        require(Debts[msg.sender][DAI] >= amount, "payment exceeds debt");
        Debts[msg.sender][DAI] -= amount;
        iDAI.safeTransferFrom(msg.sender, address(this), amount);
        emit Repay(msg.sender, amount, Debts[msg.sender][DAI]);
    }

    /// @notice allows a user to repay borrowed USDC
    function repayUSDC(uint256 amount) external {
        require(Debts[msg.sender][USDC] >= amount, "payment exceeds debt");
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
        iWETH.transfer(msg.sender, lqdtdWETH);
    }

}