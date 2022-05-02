// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Rings.sol";
import "../lib/yield-utils-v2/contracts/mocks/ERC20Mock.sol";
import "../lib/yield-utils-v2/contracts/token/IERC20.sol";

contract WRings is ERC20Mock {

    
    IERC20 public immutable iRings;

    event Wrapped(address indexed wrapper, uint256 amount);
    event Unwrapped(address indexed unwrapper, uint256 amount);

    constructor(IERC20 iRings_) ERC20Mock("WRings", "WRNG") {
        iRings = iRings_;
    }

    function wrap(uint256 amount) external {
        iRings.transferFrom(msg.sender, address(this), amount);
        mint(msg.sender, amount);
        emit Wrapped(msg.sender, amount);
    }

    function unwrap(uint256 amount) external {
        burn(msg.sender, amount);
        iRings.transferFrom(address(this), msg.sender, amount);
        emit Unwrapped(msg.sender, amount);
    }
}

