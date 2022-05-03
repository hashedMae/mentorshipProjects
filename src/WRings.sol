// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Rings.sol";
import "../lib/yield-utils-v2/contracts/mocks/ERC20Mock.sol";
import "../lib/yield-utils-v2/contracts/token/IERC20.sol";

/// @title WRings
/// @author hashedMae
/// @notice An ERC20 wrapper for Rings token

contract WRings is ERC20Mock {

    IERC20 public immutable iRings;

    /// @notice Emitted whenever a user wraps tokens
    event Wrapped(address indexed wrapper, uint256 amount);
    /// @notice Emitted whenever a user unwraps tokens
    event Unwrapped(address indexed unwrapper, uint256 amount);

    /// @param iRings_ ERC20 Interface for Rings token
    constructor(IERC20 iRings_) ERC20Mock("WRings", "WRNG") {
        iRings = iRings_;
    }

    /// @notice Allows a user to wrap Rings tokens to WRings
    /// @dev
    /// @param amount Number of Rings tokens to deposit to the contract and wrapped tokens to mint to the user
    function wrap(uint256 amount) external {
        require(iRings.balanceOf(msg.sender) >= amount, "Insufficent Rings in wallet");
        require(iRings.allowance(msg.sender, address(this)) >= amount, "Insufficent token approval");
        mint(msg.sender, amount);
        iRings.transferFrom(msg.sender, address(this), amount);
        emit Wrapped(msg.sender, amount);
    }

    ///@notice Allows a user to unwrap WRings tokens and receive Rings tokens in return
    ///@dev 
    ///@param amount Number of WRings tokens to burn and unwrapped tokens to transfer to user
    function unwrap(uint256 amount) external {
        require(this.balanceOf(msg.sender) >= amount, "Not Enough WRings to unwrap");
        burn(msg.sender, amount);
        iRings.transferFrom(address(this), msg.sender, amount);
        emit Unwrapped(msg.sender, amount);
    }
    
}

