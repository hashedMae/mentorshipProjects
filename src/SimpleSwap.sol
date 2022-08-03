// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "yield-utils-v2/token/ERC20.sol";
import "yield-utils-v2/token/IERC20.sol";
import "yield-utils-v2/token/TransferHelper.sol";
import "yield-utils-v2/math/WDiv.sol";
import "yield-utils-v2/math/WMul.sol";

/// @title SimpleSwapLP 
/// @author hashedMae
/// @notice A simple AMM with no fees
contract SimpleSwap is ERC20{

    using TransferHelper for IERC20;

    /// @dev reserves of token X
    uint256 public x_0;
    /// @dev reserves of token Y
    uint256 public y_0;

    /// @dev reserve token X
    IERC20 public immutable tokenX;
    /// @dev reserve token Y
    IERC20 public immutable tokenY;


    /// @notice emitted when a user contributes liquidity to the pool
    /// @param user address of user that is providing liquidity to the pool
    /// @param xIn amount of token X that is being provided as liquidity
    /// @param yIn amount of token Y that is being provided as liquidity 
    /// @param zOut amount of LP tokens that are being minted to the user
    event LiquidityProvided(address indexed user, uint256 xIn, uint256 yIn, uint256 zOut);

    /// @notice emitted when a user removes liquidity from the pool
    /// @param user address of user that is removing liquidity from the pool
    /// @param xOut amount of token X that is being removed from liquidity
    /// @param yOut amount of token Y that is being removed from liquidity
    /// @param zIn amount of LP tokens that are being burned from the user
    event LiquidityRemoved(address indexed user, uint256 xOut, uint256 yOut, uint256 zIn);

    /// @notice emitted when a usere swaps tokens within the pool
    /// @param user address of user that is swapping tokens
    /// @param xIn amount of token X that is being swapped into the pool
    /// @param yIn amount of token Y that is being swapped into the pool
    /// @param xOut amount of token X that is being swapped out of the pool
    /// @param yOut amount of token Y that is being swapped out of the pool
    event Swap(address indexed user, uint256 xIn, uint256 yIn, uint256 xOut, uint256 yOut);

    constructor(IERC20 tokenX_, IERC20 tokenY_) ERC20("SimpleSwapLP", "SSLP", 18) {
        tokenX = tokenX_;
        tokenY = tokenY_;
    }

    /// @notice used to intiate a liquidity pool, can only be done once
    /// @param xIn the amount of token X that'll be added to the pool 
    /// @param yIn the amount of token Y that'll be added to the pool
    /// @return zOut the amount of LP tokens that'll be minted to the user
    function init(uint256 xIn, uint256 yIn) external returns(uint256 zOut){
        require(_totalSupply == 0, "SimpleSwap:Pool already initiated");
        require(xIn > 0 && yIn > 0, "SimpleSwap: Can't provide 0 tokens");
        x_0 += xIn;
        y_0 += yIn;
        zOut = xIn * yIn;
        tokenX.safeTransferFrom(msg.sender, address(this), xIn);
        tokenY.safeTransferFrom(msg.sender, address(this), yIn);
        _mint(msg.sender, zOut);
        emit LiquidityProvided(msg.sender, xIn, yIn, zOut);
        }

    /// @notice used to add liquidity to an existing pool
    /// @param xIn the amount of token X that'll be added to the pool
    /// @return zOut the amount of LP tokens that'll be minted to the user
    function addLiquidity(uint256 xIn) external returns(uint256 zOut){
        require(_totalSupply > 0, "SimpleSwap:Pool not intiated");
        uint256 _x_0 = x_0;
        uint256 _y_0 = y_0;
        uint256 yIn = _y_0 * xIn / _x_0;
        zOut = xIn * _totalSupply / _x_0;
        x_0 += xIn;
        y_0 += yIn;
        tokenX.safeTransferFrom(msg.sender, address(this), xIn);
        tokenY.safeTransferFrom(msg.sender, address(this), yIn);
        _mint(msg.sender, zOut);
        emit LiquidityProvided(msg.sender, xIn, yIn, zOut);
    }

    /// @notice used to remove tokens from the liquidity pool
    /// @param zIn the amount of LP tokens to burn
    /// @return xOut the amount of token X returned to the user 
    /// @return yOut the amount of token Y returned to the user
    function removeLiquidity(uint256 zIn) external returns(uint256 xOut, uint256 yOut) {
        uint256 zOwnership = WDiv.wdiv(zIn, _totalSupply);
        xOut = WMul.wmul(x_0, zOwnership);
        yOut = WMul.wmul(y_0, zOwnership);
        _burn(msg.sender, zIn);
        tokenX.safeTransfer(msg.sender, xOut);
        tokenY.safeTransfer(msg.sender, yOut);
        emit LiquidityRemoved(msg.sender, xOut, yOut, zIn);
    }

    /// @notice used to swap an amount of token X for token Y
    /// @param xIn the amount of token X being sold to the pool
    /// @return yOut the amount of token Y being bought from the pool
    function swapXForY(uint256 xIn) external returns(uint256 yOut){
        yOut = _price(xIn, x_0, y_0);
        x_0 += xIn;
        y_0 -= yOut;
        tokenX.safeTransferFrom(msg.sender, address(this), xIn);
        tokenY.safeTransfer(msg.sender, yOut);
        emit Swap(msg.sender, xIn, 0, 0, yOut);
    }

    /// @notice used to swap amount of token Y for token X
    /// @param yIn the amount of token Y being sold to the pool
    /// @param xOut the amount of token X being bought from the pool
    function swapYForX(uint256 yIn) external returns(uint256 xOut){
        xOut = _price(yIn, y_0, x_0);
        y_0 += yIn;
        x_0 -= xOut;
        tokenY.safeTransferFrom(msg.sender, address(this), yIn);
        tokenX.safeTransfer(msg.sender, xOut);
        emit Swap(msg.sender, 0, yIn, xOut, 0);
    }

    function swapXforExactY(uint256 yOut) external returns(uint256 xIn){
        xIn = _priceOut(yOut, x_0, y_0);
        x_0 += xIn;
        y_0 -= yOut;
        tokenX.safeTransferFrom(msg.sender, address(this), xIn);
        tokenY.safeTransfer(msg.sender, yOut);
        emit Swap(msg.sender, xIn, 0, 0, yOut);
    }

    function swapYforExactX(uint256 xOut) external returns(uint256 yIn){
        yIn = _priceOut(xOut, y_0, x_0);
        y_0 += yIn;
        x_0 -= xOut;
        tokenY.safeTransferFrom(msg.sender, address(this), yIn);
        tokenX.safeTransfer(msg.sender, xOut);
        emit Swap(msg.sender, 0, yIn, xOut, 0);
    }

    function swapForExactXPreview(uint256 xOut) external view returns(uint256 yIn){
        yIn = _priceOut(xOut, y_0, x_0);
    }

    /// @notice internal function used for pricing token swaps
    /// @param aIn amount of token that is being sold to the pool
    /// @param aReserves reserves for the token that is being sold to the pool
    /// @param bReserves rerserves for the token that is being bought from the pool
    /// @param bOut amount of token that is being bought from the pool
    function _price(uint256 aIn, uint256 aReserves, uint256 bReserves) internal view returns(uint256 bOut) {
        uint256 numerator = aIn * bReserves;
        uint256 denominator = aIn + aReserves;
        bOut = numerator / denominator;
    }

    function _priceOut(uint256 bOut, uint256 aReserves, uint256 bReserves) internal view returns(uint256 aIn) {
        uint256 numerator = aReserves * bReserves;
        uint256 denominator = bReserves - bOut;
        aIn = (numerator / denominator) - aReserves;
    }
}