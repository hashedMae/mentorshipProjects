// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title RMath
/// @author hashedMae
/// Math library for using wads with rads

library RMath {

    
    /// @dev converts a wad to a rad, multiplies it by a rad, then returns a wad
    function rmul(uint256 x, uint256 y) internal pure returns(uint256 z) {
        z = (x*10**9) * y;
        unchecked {z /= 10**9;}
    }

    /// @dev converts a wad to a rad, divides it by a rad, then returns a wad
    function rdiv(uint256, uint256 y) internal pure returns(uint256 z) {
        z = (x*10**9) / y;
        unchecked {z /= 10**9;}
    }


}