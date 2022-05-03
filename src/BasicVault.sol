// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/yield-utils-v2/contracts/token/IERC20.sol";
import "../lib/yield-utils-v2/contracts/token/IERC2612.sol";


/// @title Basic Vault
/// @author hashedMae
/// @notice A simple vault that tracks the amount of tokens a user has deposited and allows them to withdraw at any time
/// @dev 

contract BasicVault {

    IERC20 iToken;

    mapping(address => uint256) public balances;

    /// @notice Emitted when a user deposits token to the contract
    event Deposit(address indexed user, uint256 amount, uint256 balance);
    /// @notice Emitted when a user withdraws tokens from the contract
    event Withdrawal(address indexed user, uint256 amount, uint256 balance);

    /// @param iToken_ The address of the token that the vault will hold
    constructor(IERC20 iToken_){
      iToken = iToken_;
    }

    /// @notice Allows a user to deposit tokens to the vault
    /// @dev Tracks user vault balance via mapping of address => uint
    /// @param amount Number of Tokens to deposit
    function deposit(uint256 amount) public {
        balances[msg.sender] += amount;
        require(iToken.transferFrom(msg.sender, address(this), amount), "failed on tranfer");
        emit Deposit(msg.sender, amount, balances[msg.sender]);
    }

    /// @notice Allows a user to withdraw tokens they've previously deposited
    /// @dev ensures that a user can't withdraw more tokens than they've deposited, subtracts from user's balance after succesful withdrawal
    /// @param amount Number of tokens to withdraw
    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "requested amount exceeds user balance");
        balances[msg.sender] -= amount;
        require(iToken.transferFrom(address(this), msg.sender, amount), "failed on withdrawal");
    
        emit Withdrawal(msg.sender, amount, balances[msg.sender]);
    }

}