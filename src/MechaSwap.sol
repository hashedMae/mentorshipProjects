// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "yield-utils-v2/token/ERC20.sol";
import "yield-utils-v2/token/IERC20.sol";
import "yield-utils-v2/token/TransferHelper.sol";
import "yield-utils-v2/math/WDiv.sol";
import "yield-utils-v2/math/WMul.sol";

/// @title MechaSwapLP 
/// @author hashedMae
/// @notice A simple AMM with no fees
contract MechaSwap is ERC20{

    using TransferHelper for IERC20;

    /// @dev reserves of token X
    uint256 public x_0;
    /// @dev reserves of token Y
    uint256 public y_0;

    /// @dev reserve token X
    IERC20 public immutable tokenX;
    /// @dev reserve token Y
    IERC20 public immutable tokenY;

    /// @notice emitted on pool initiation
    /// @param user address of user that is intializing the pool
    /// @param amountX amount of token X that is being contributed to the new pool
    /// @param amountY amount of token Y that is being contributed to the new pool
    /// @param amountZ amount of LP tokens that are being minted to the user
    event Init(address indexed user, uint256 amountX, uint256 amountY, uint256 amountZ);

    /// @notice emitted when a user contributes liquidity to the pool
    /// @param user address of user that is providing liquidity to the pool
    /// @param amountX amount of token X that is being provided as liquidity
    /// @param amountY amount of token Y that is being provided as liquidity 
    /// @param amountZ amount of LP tokens that are being minted to the user
    event LiquidityProvided(address indexed user, uint256 amountX, uint256 amountY, uint256 amountZ);

    /// @notice emitted when a user removes liquidity from the pool
    /// @param user address of user that is removing liquidity from the pool
    /// @param amountX amount of token X that is being removed from liquidity
    /// @param amountY amount of token Y that is being removed from liquidity
    /// @param amountZ amount of LP tokens that are being burned from the user
    event LiquidityRemoved(address indexed user, uint256 amountX, uint256 amountY, uint256 amountZ);

    /// @notice emitted when a usere swaps tokens within the pool
    /// @param user address of user that is swapping tokens
    /// @param xIn amount of token X that is being swapped into the pool
    /// @param yIn amount of token Y that is being swapped into the pool
    /// @param xOut amount of token X that is being swapped out of the pool
    /// @param yOut amount of token Y that is being swapped out of the pool
    event Swap(address indexed user, uint256 xIn, uint256 yIn, uint256 xOut, uint256 yOut);

    constructor(IERC20 tokenX_, IERC20 tokenY_) ERC20("MechaSwapLP", "MSLP", 18) {
        tokenX = tokenX_;
        tokenY = tokenY_;
    }

    /// @notice used to intiate a liquidity pool, can only be done once
    /// @param amountX the amount of token X that'll be added to the pool 
    /// @param amountY the amount of token Y that'll be added to the pool
    /// @return z the amount of LP tokens that'll be minted to the user
    function init(uint256 amountX, uint256 amountY) external returns(uint256 z){
        require(x_0 == 0 && y_0 == 0, "MechaSwap:Pool already initiated");
        x_0 += amountX;
        y_0 += amountY;
        z = amountX * amountY;
        tokenX.safeTransferFrom(msg.sender, address(this), amountX);
        tokenY.safeTransferFrom(msg.sender, address(this), amountY);
        _mint(msg.sender, z);
        emit Init(msg.sender, amountX, amountY, z);
    }

    /// @notice used to add liquidity to an existing pool
    /// @param amountX the amount of token X that'll be added to the pool
    /// @return z the amount of LP tokens that'll be minted to the user
    function addLiquidity(uint256 amountX) external returns(uint256 z){
        require(x_0 > 0, "MechaSwap:Pool not intiated");
        uint256 amountY = amountX * y_0 / x_0;
        x_0 += amountX;
        y_0 += amountY;
        z = amountX / x_0;
        tokenX.safeTransferFrom(msg.sender, address(this), amountX);
        tokenY.safeTransferFrom(msg.sender, address(this), amountY);
        _mint(msg.sender, z);
        emit LiquidityProvided(msg.sender, amountX, amountY, z);
    }

    /// @notice used to remove tokens from the liquidity pool
    /// @param amountZ the amount of LP tokens to burn
    /// @return xOut the amount of token X returned to the user 
    /// @return yOut the amount of token Y returned to the user
    function removeLiquidity(uint256 amountZ) external returns(uint256 xOut, uint256 yOut) {
        uint256 zOwnership = amountZ / _totalSupply;
        xOut = WMul.wmul(x_0, zOwnership);
        yOut = WMul.wmul(y_0, zOwnership);
        _burn(msg.sender, amountZ);
        tokenX.safeTransfer(msg.sender, xOut);
        tokenY.safeTransfer(msg.sender, yOut);
        emit LiquidityRemoved(msg.sender, xOut, yOut, amountZ);
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

    /// @notice internal function used for pricing token swaps
    /// @param aIn amount of token that is being sold to the pool
    /// @param aReserves reserves for the token that is being sold to the pool
    /// @param bReserves rerserves for the token that is being bought from the pool
    /// @param bOut amount of token that is being bought from the pool
    function _price(uint256 aIn, uint256 aReserves, uint256 bReserves) internal view returns(uint256 bOut) {
        require(x_0 > 0, "MechaSwap:Pool not intiated");
        require(aIn > 0, "MechaSwap: Insufficient Tokens In");
        uint256 numerator = aIn * bReserves;
        uint256 denominator = aIn + aReserves;
        bOut = numerator / denominator;
    }
}
