// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title RMath
/// @author hashedMae

library RMath {

    function rmul(uint256 x, uint256 y) internal pure returns(uint256 z) {
        z = x * y;
        unchecked {z /= 10**27;}
    }

    function rdiv(uint256 x, uint256 y) internal pure returns(uint256 z) {
        z = (x*10**27) / y;
    }


}