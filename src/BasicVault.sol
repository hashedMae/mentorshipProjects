// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/yield-utils-v2/contracts/token/IERC20.sol";
import "../lib/yield-utils-v2/contracts/token/IERC2612.sol";


/// @title
/// @author
/// @notice
/// @dev

contract BasicVault {

IERC20 iToken;

mapping(address => uint256) public userBalance;

event Deposit(address indexed user, uint256 amount, uint256 balance);
event Withdrawal(address indexed user, uint256 amount, uint256 balance);

/// @param iToken_ The address of the token that the vault will hold
constructor(IERC20 iToken_){
    iToken = iToken_;
}

/// @notice
/// @dev
/// @param amount Number of Tokens to deposit
function depositToken(uint256 amount) public {
    require(iToken.transferFrom(msg.sender, address(this), amount), "failed on tranfer");
    userBalance[msg.sender] += amount;
    emit Deposit(msg.sender, amount, userBalance[msg.sender]);
}

/// @notice
/// @dev
/// @param amount Number of tokens to withdraw
function withdrawToken(uint256 amount) public {
    require(userBalance[msg.sender] >= amount, "requested amount exceeds user balance");
    iToken.transferFrom(address(this), msg.sender, amount);
    userBalance[msg.sender] -= amount;
    emit Withdrawal(msg.sender, amount, userBalance[msg.sender]);
}

}