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
        unchecked {z /= 1e27;}
    }
}

library RDiv {
    function rdiv(uint256 x, uint256 y) internal pure returns(uint256 z) {
        z = (x*1e27) / y;
    }
}


/// https://github.com/yieldprotocol/mentorship2022/issues/6

/// @title MultiCollateralVault
/// @author hashedMae
/// @notice A contract for borrowing WETH against deposits of tokens that have been added as approved collateral
/// @dev Additional collaterals can be added after deployment but only WETH can ever be borrowed

contract MultiCollateralVault is AccessControl {
    
    using TransferHelper for IERC20;

    event Deposit(address indexed user, IERC20 indexed token, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 repaid, uint256 remaining);
    event Withdraw(address indexed user, IERC20 indexed token, uint256 amount);

    /// mainnet 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    /// rinkeby 0xDf032Bc4B9dC2782Bb09352007D4C57B75160B15
    IERC20 WETH;

    /// @dev nested mapping for tracking user WETH debt
    mapping(address =>  uint256) public  debt;

    /// @dev nested mapping for tracking user deposits, first address is user address, second is token address
    /// mapping(user => mapping(token => deposit))
    mapping(address => mapping(IERC20 => uint256)) public  deposits;

    mapping(IERC20 => CollateralInfo) public collateralInfos;

    struct CollateralInfo {
        AggregatorV3Interface oracle;
        uint96 ratio;
    }

   /// CollateralInfo collateralInfo;

    IERC20[] public Collaterals;

    ///@param WETH_ address for the WETH contract
    constructor (IERC20 WETH_) {
        WETH = WETH_;
    }

/***
-------------------------------------------------------------------------------------------------------------------------------------------------------------
    Admin Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------
 */

    /// @dev checks to see if a token is currently accepted as collteral and if it has been added but not yet live cause there is no ratio set yet
    function addCollateral(IERC20 token_, AggregatorV3Interface oracle_) external auth {
        require(token_ != IERC20(address(0)), "token cannot be zero address");
        require(oracle_ != AggregatorV3Interface(address(0)), "oracle cannot be zero address");
        if(collateralInfos[token_].oracle == oracle_ && collateralInfos[token_].ratio != 0) {
            revert("token has already been added as collateral");
        } else if(collateralInfos[token_].oracle == oracle_ && collateralInfos[token_].ratio == 0)  {
            revert("token added but ratio not set");
        } else{
            Collaterals.push(token_);
            collateralInfos[token_].oracle = oracle_;
        }
    }

    /// @dev A token must be added to the list of accepted collateral before a ratio can be set for it
    function setRatio(IERC20 token_, uint96 rad) external auth {
        require(token_ != IERC20(address(0)), "token cannot be zero address");
        require(rad > 0, "ratio must be greater than 0");
        require(rad <= 1e27, "ratio must be less than or equal to 1");
        require(collateralInfos[token_].oracle != AggregatorV3Interface(address(0)), "token has not been added as collateral");

        collateralInfos[token_].ratio = rad;
    }

    
    /// @notice allows authorized user to liquidate under collateralized Users
    function liquidate(address user) external auth {
        require(!_isCollateralized(user), "specified user can't be liquidated");
         debt[user] = 0;
        IERC20[] memory _collaterals = Collaterals;
        uint256 _length = _collaterals.length;
        for(uint256 i = 0; i < _length;) {
            uint256 amount =  deposits[user][_collaterals[i]];
            deposits[user][_collaterals[i]] = 0;
            _collaterals[i].safeTransfer(msg.sender, amount);
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
    function price(IERC20 token) public view returns(uint256) {
        return _price(token);
    }

    function freeCollateral(address user, IERC20 token) view external returns(uint256) {
        return _freeCollateral(user, token);
    }

    /// @dev used in testing
    function remainingPower(address user) public view returns(uint256){
        return _remainingPower(user);
    }
    
    function _price(IERC20 token) internal view returns(uint256) {
        AggregatorV3Interface iOracle = collateralInfos[token].oracle;
        (   uint80 roundID,
            int256 price_,
            /*uint startedAt*/,
            uint timeStamp,
            uint80 answeredInRound
        ) = iOracle.latestRoundData();
        require(price_ > 0, "ChainLink: price <= 0");
        require(answeredInRound >= roundID, "ChainLink: Stale price");
        require(timeStamp > 0, "ChainLink: Round not complete");
        return uint256(price_);
    }

    /// @dev calculates the total borrowing power of a users deposits in ETH, and the total value of a users in Deposits in ETH
    function _borrowingPower(address user) internal view returns(uint256 borrowingPower_, uint256 depositsInETH_) {
        IERC20[] memory _collaterals = Collaterals;
        uint256 _length = _collaterals.length;
        uint256 price_;
        uint256 deposit_;
        uint256 valueInETH;
        for(uint256 i = 0; i < _length; ) {
            price_ = _price(_collaterals[i]);
            /// stores a users deposits of a token as a wad
            deposit_ = deposits[user][_collaterals[i]]*10**_decimalsDifference(_collaterals[i]);
            /// calculates the value of a user's deposit for a token in ETH
            valueInETH = WMul.wmul(deposit_, price_);
            /// multiplies the value of user's of a token in ETH by the max ratio for that token and adds it to the total
            borrowingPower_ += RMul.rmul(valueInETH, collateralInfos[_collaterals[i]].ratio);
            /// adds the value of user's deposit in ETH to the total value in ETH of all their deposits
            depositsInETH_ += valueInETH;
            unchecked{i++;}
        }
        return (borrowingPower_, depositsInETH_);
    }

    function _remainingPower(address user) internal view returns(uint256) {
       (uint256 borrowingPower, ) =_borrowingPower(user);
       return borrowingPower - debt[user];
    }

    /// @dev used to calculate how much of a deposited token is not currently being ultilized as collateral
    function _freeCollateral(address user, IERC20 token) internal view returns(uint256) {
        uint256 userDebt =  debt[user];
        IERC20[] memory _collaterals = Collaterals;
        uint256 _length = _collaterals.length;
        uint256 deposit_;
        uint256 price_;
        uint96 ratio_;
        for (uint256 i = 0; i < _length; i++) {
            if(_collaterals[i] != token && userDebt > 0) { 
                deposit_ = deposits[user][_collaterals[i]]*10**_decimalsDifference(_collaterals[i]);
                price_ = _price(_collaterals[i]);
                ratio_ = collateralInfos[_collaterals[i]].ratio;
                uint256 rdep = RMul.rmul(
                    WMul.wmul(
                    deposit_,
                    price_), 
                    ratio_);
                if(userDebt > rdep){
                    userDebt -= rdep;
                } else {
                    userDebt = 0;
                }
                ///unchecked{i++;}
            }
        }
        if(userDebt > 0) {
            return RMul.rmul( deposits[user][token], collateralInfos[token].ratio) - 
                WDiv.wdiv(userDebt, _price(token))/10**_decimalsDifference(token);
        } else{
            return  deposits[user][token];
        }
    }

    function _isCollateralized(address user) internal view returns(bool) {
        (uint256 borrowingPower_, uint256 depositsInETH_) = _borrowingPower(user);
        uint256 ltvRatio_ = WDiv.wdiv(borrowingPower_, debt[user]);
        uint256 maxRatio_ = WDiv.wdiv(borrowingPower_, depositsInETH_);
        bool collateralized;
        if(ltvRatio_ <= maxRatio_){
            collateralized = true;
        } else {
            collateralized = false;
        }
        return collateralized;
    }
/***
-------------------------------------------------------------------------------------------------------------------------------------------------------------
    User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------
 */
    
    /// @notice allows a user to deposit WETH for use as collateral
    /// @dev to ensure that a token is being accepted as collateral we check to ensure that a maximum loan to value ratio has been set since
    /// that is the final step in adding a new token in collateral
    function deposit(IERC20 token, uint256 amount) external {
        require(collateralInfos[token].ratio != 0, "token not currently accepted as collateral");
        deposits[msg.sender][token] += amount;
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, token, amount);
    }

    /// @notice allows a user to borrow WETH
    function borrow(uint256 amount) external {
        require(amount <= _remainingPower(msg.sender), "Insufficient collateral");
        debt[msg.sender] += amount;
        WETH.safeTransfer(msg.sender, amount);
        emit Borrow(msg.sender, amount);
    }

    /// @notice allows a user to withdraw token that are not currently utilized as collateral
    function withdraw(IERC20 token, uint256 amount) external {
        require(amount < _freeCollateral(msg.sender, token), "Position would liquidate");
        deposits[msg.sender][token] -= amount;
        token.safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, token, amount);
    }

    /// @notice allows a user to repay their debts
    function repay(uint256 amount) external {
        require(amount <=  debt[msg.sender], "repayment exceeds debt");
        debt[msg.sender] -= amount;
        IERC20(WETH).safeTransferFrom(msg.sender, address(this), amount);
        emit Repay(msg.sender, amount,  debt[msg.sender]);
    }

/***
-------------------------------------------------------------------------------------------------------------------------------------------------------------
    Helper Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------
 */

    /// @dev returns the number of decimals less than 18 a token uses (ie USDC has 6 decimals returns 12)
    function _decimalsDifference(IERC20 token) internal view returns(uint8){
        return 18 - IERC20Metadata(address(token)).decimals();
    }

}