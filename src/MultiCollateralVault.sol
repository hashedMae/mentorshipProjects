// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "yield-utils/math/WDiv.sol";
import "yield-utils/math/WMul.sol";
import "yield-utils/token/IERC20.sol";
import "yield-utils/token/IERC20Metadata.sol";
import "yield-utils/token/TransferHelper.sol";
import "yield-utils/access/Ownable.sol";
import "yield-utils/access/AccessControl.sol";

import "chainlink/v0.8/interfaces/AggregatorV3Interface.sol";

library RMul {
    function rmul(uint256 x, uint256 y) internal pure returns(uint256 z) {
        z = x * y;
        unchecked {z /= 10**27;}
    }
}

library RDiv {
    function rdiv(uint256 x, uint256 y) internal pure returns(uint256 z) {
        z = (x*10**27) / y;
    }
}


/// https://github.com/yieldprotocol/mentorship2022/issues/6

/// @title MultiCollateralVault
/// @author hashedMae
/// @notice A contract for borrowing WETH against deposits of tokens that have been added as approved collateral
/// @dev Additional collaterals can be added after deployment but only WETH can ever be borrowed

contract MultiCollateralVault is AccessControl {
    
    using TransferHelper for IERC20;

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 repaid, uint256 remaining);
    event Withdraw(address indexed user, address indexed token, uint256 amount);

    /// mainnet 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    /// rinkeby 0xDf032Bc4B9dC2782Bb09352007D4C57B75160B15
     address WETH;

    

    /// @dev nested mapping for tracking user WETH debt
    mapping(address =>  uint256) public Debt;

    /// @dev nested mapping for tracking user deposits, first address is user address, second is token address
    /// mapping(user => mapping(token => deposit))
    mapping(address => mapping(address => uint256)) public Deposits;

    /// @dev mapping for storage of Chainlink Oracle interfaces
    /// @dev Token address pairings used as keys (ex mapping(BTC => mapping(ETH => AggregatorV3Interface)))
    mapping(address => AggregatorV3Interface) public Oracles;

    /// @dev mapping for storing the maximum LTV of a collateral token
    /// @dev is a factor with 27 decimals
    mapping(address => uint256) public Ratios;

    address[] public Collaterals;

    ///@param WETH_ address for the WETH contract
    constructor (address WETH_) {
        WETH = WETH_;
    }

/***
-------------------------------------------------------------------------------------------------------------------------------------------------------------
    Admin Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------
 */
    function addCollateral(address token, AggregatorV3Interface oracle) external auth {
        _addCollateral(token, oracle);
    }

    function setRatio(address token, uint256 rad) external auth {
        _setRatio(token, rad);
    }

    function liquidate(address user) external auth {
        _liquidate(user);
    }

    /// @dev checks to see if a token is currently accepted as collteral and if it has been added but not yet live cause there is no ratio set yet
    function _addCollateral(address token_, AggregatorV3Interface oracle_) internal {
        require(token_ != address(0), "token cannot be zero address");
        require(oracle_ != AggregatorV3Interface(address(0)), "oracle cannot be zero address");
        if(Oracles[token_] == oracle_ && Ratios[token_] != 0) {
            revert("token has already been added as collateral");
        }
        if(Oracles[token_] == oracle_ && Ratios[token_] == 0)  {
            revert("token added but ratio not set");
        } else{
            Collaterals.push(token_);
            Oracles[token_] = oracle_;
        }
    }

    /// @dev A token must be added to the list of accepted collateral before a ratio can be set for it
    function _setRatio(address token_, uint256 rad) internal {
        require(token_ != address(0), "token cannot be zero address");
        require(rad > 0, "ratio must be greater than 0");
        require(rad < 1e27, "ratio must be less than 1");
        require(Oracles[token_] != AggregatorV3Interface(address(0)), "token has not been added as collateral");

        Ratios[token_] = rad;
    }

    
    /// @notice allows authorized user to liquidate under collateralized Users
    function _liquidate(address user) internal {
        require(_ltvRatio(user) < _maxRatio(user), "specified user can't be liquidated");
        Debt[user] = 0;
        address[] memory _collaterals = Collaterals;
        uint128 _length = _collaterals.length:
        for(uint128 i = 0; i < _length;) {
            uint256 amount = Deposits[user][_collaterals[i]];
            Deposits[user][_collaterals[i]] = 0;
            IERC20(_collaterals[i]).safeTransfer(msg.sender, amount);
            unchecked{i++;}
        }
    } 

/***
-------------------------------------------------------------------------------------------------------------------------------------------------------------
    Pricing/Vault Ratio functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------
 */

    /// @return price the value of token denominated in WETH
    /// @param token address for the token that's being inquired about
    function price(address token) public view returns(uint256) {
        return _price(token);
    }

    /// @notice calculates the total value of a users deposits in ETH
    function totalDeposits() view external returns(uint256) {
        return _totalDeposits(msg.sender);
    }

    /// @notice provides how much WETH a user is currently able to borrow
    function borrowingPower() view external returns(uint256) {
        return _borrowingPower(msg.sender);
    }

    /// @notice provides a user's maximum combined loan to value ratio
    function maxRatio() view external returns(uint256) {
        return _maxRatio(msg.sender);
    }

    /// @notice provides a user's current loan to value ratio
    function ltvRatio() view external returns(uint256) {
        return _ltvRatio(msg.sender);
    }
    
    function _price(address token) internal view returns(uint256) {
        AggregatorV3Interface iOracle = Oracles[token];
        (   /*uint80 roundID*/,
        int256 answer,
            /*uint startedAt*/,
            /*uint timeStam*/,
            /*uint80 answeredInRound*/
        ) = iOracle.latestRoundData();
        return uint256(answer);
    }

    /// @dev calculates the the ratioed value of a users deposits in ETH
    function _ratioedDeposits(address user) internal view returns(uint256) {
        uint256 ratioedValue;
        address[] memory _collaterals = Collaterals;
        uint128 _length = _collaterals.length;
        for(uint128 i = 0; i < _length; ) {
            ratioedValue += RMul.rmul(
                WMul.wmul(
                Deposits[user][_collaterals[i]]*10**_decimalsDifference(_collaterals[i]),
                _price(_collaterals[i])), 
                Ratios[_collaterals[i]]);
                unchecked{i++;}
        }
        return ratioedValue;
    }

    
    function _totalDeposits(address user) internal view returns(uint256) {
        uint256 totalValue;
        address[] memory _collaterals = Collaterals;
        uint128 _length = _collaterals.length;
        for(uint256 i = 0; i < _length;){
            totalValue += WMul.wmul(Deposits[user][_collaterals[i]]*10**_decimalsDifference(_collaterals[i]), _price(_collaterals[i]));
            unchecked{i++;}
        }
        return totalValue;
    }

    function _borrowingPower(address user) internal view returns(uint256) {
        return _ratioedDeposits(user) - Debt[user];
    }

    /// @dev deposit values are calculated as wads and max ltv ratios are stored as rads so it was necessary to convert the deposit values to rad first
    function _maxRatio(address user) internal view returns(uint256){
        return RDiv.rdiv(_ratioedDeposits(user)*10**9, _totalDeposits(user)*10**9);
    }

    
    function _ltvRatio(address user) internal view returns(uint256){
        return WDiv.wdiv(_ratioedDeposits(user), Debt[user]);
    }

    /// @dev provides an adjusted ltv ratio in the case that the user were to withdraw an amount of collateral tokens
    /// @param user address for the user in question
    /// @param token address of the token being calculated for withdrawal
    /// @param amount requested amount of tokens for withdrawal
    /// @return uint256 the loan to value ratio if the withdrawal were to take place, this can be compared to a user's maximum ltv to verify if the withdrawal is valid or not
    function _adjustedLTV(address user, address token, uint256 amount) internal view returns(uint256) {
        uint256 ratioedValue;
        uint256 postBalance = Deposits[user][token] - amount;
        address[] memory _collaterals = Collaterals;
        uint128 _length = _collaterals.length;
        for (uint128 i = 0; i < _length;) {
            if(_collaterals[i] == token) {
                ratioedValue += RMul.rmul(
                    WMul.wmul(
                    postBalance*10**_decimalsDifference(_collaterals[i]), 
                    _price(_collaterals[i])), 
                    Ratios[_collaterals[i]]);
            } else {
                ratioedValue += RMul.rmul(
                    WMul.wmul(
                    Deposits[user][_collaterals[i]]*10**_decimalsDifference(_collaterals[i]),
                    _price(_collaterals[i])), 
                    Ratios[_collaterals[i]]);
            }
            unchecked{i++;}
        }
        return WDiv.wdiv(ratioedValue, Debt[user]);
    }

/***
-------------------------------------------------------------------------------------------------------------------------------------------------------------
    User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------
 */
    
    /// @notice allows a user to deposit WETH for use as collateral
    function deposit(address token, uint256 amount) external {
        _deposit(msg.sender, token, amount);
    }

    /// @notice allows a user to borrow WETH
    function borrow(uint256 amount) external {
        _borrow(msg.sender, amount);
    }

    /// @notice allows a user to withdraw token that are not currently utilized as collateral
    function withdraw(address token, uint256 amount) external {
        _withdraw(msg.sender, token, amount);
    }

    /// @notice allows a user to repay their debts
    function repay(uint256 amount) external {
        _repay(msg.sender, amount);
    }

    /// @dev to ensure that a token is being accepted as collateral we check to ensure that a maximum loan to value ratio has been set since
    /// that is the final step in adding a new token in collateral
    function _deposit(address user, address token, uint256 amount) internal {
        require(Ratios[token] != 0, "token not currently accepted as collateral");
        Deposits[user][token] += amount;
        IERC20(token).safeTransferFrom(user, address(this), amount);
        emit Deposit(user, token, amount);
    }

    
    function _borrow(address user, uint256 amount) internal {
        require(amount <= _borrowingPower(user), "Insufficient collateral");
        Debt[user] += amount;
        IERC20(WETH).safeTransfer(user, amount);
        emit Borrow(user, amount);
    }

    

    /// @notice allows a user to withdraw token that are not currently utilized as collateral
    function _withdraw(address user, address token, uint256 amount) internal {
        require(_adjustedLTV(user, token, amount) <= _maxRatio(user), "Position would liquidate");
        Deposits[user][token] -= amount;
        IERC20(token).safeTransfer(user, amount);
        emit Withdraw(user, token, amount);
    }

    function _repay(address user, uint256 amount) internal {
        require(amount <= Debt[user], "repayment exceeds debt");
        Debt[user] -= amount;
        IERC20(WETH).safeTransferFrom(user, address(this), amount);
        emit Repay(user, amount, Debt[user]);
    }


/***
-------------------------------------------------------------------------------------------------------------------------------------------------------------
    Helper Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------
 */
    function _decimalsDifference(address token) internal view returns(uint8){
        return 18 - IERC20Metadata(token).decimals();
    }

}