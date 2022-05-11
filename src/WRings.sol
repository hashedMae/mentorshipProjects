// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Rings.sol";
import "../lib/yield-utils-v2/contracts/mocks/ERC20Mock.sol";
import "../lib/yield-utils-v2/contracts/token/IERC20.sol";
import "../lib/yield-utils-v2/contracts/math/WDiv.sol";
import "../lib/yield-utils-v2/contracts/math/WMul.sol";
import "../lib/yield-utils-v2/contracts/access/Ownable.sol";

/// @title WRings
/// @author hashedMae
/// @notice An ERC20 fractional wrapper for yield bearing tokens
/// @dev Utilizes WMul and WDiv math libraries from Yield-Utils-V2. Will always round down to zero.

contract WRings is ERC20Mock,
                   Ownable {

    IERC20 public immutable iRings;
    uint256 public exchangeRate;

    /// @notice Emitted whenever a user wraps tokens
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
    /// @notice Emitted whenever a user unwraps tokens
    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);

    /// @param iRings_ ERC20 Interface for Rings token
    constructor(IERC20 iRings_) ERC20Mock("WRings", "WRNG") {
        iRings = iRings_;
    }

    /// @return assetTokenAddress Contract address of token utilized by the vault
    function asset() public view returns(address){
        address assetTokenAddress = address(iRings);
        return assetTokenAddress;
    }

    /// @return totalManagedAssets Balance of the asset token within the vault
    function totalAssets() public view returns(uint256) {
        uint256 totalManagedAssets = iRings.balanceOf(address(this));
        return totalManagedAssets;
    }

    /// @notice Allows the owner to set the exchange rate
    /// @dev uses 27 decimals of precision, and can be no greater than 1000000000000000000
    /// @param exchangeRate_ New exchange rate
    function setExchangeRate(uint256 exchangeRate_) external onlyOwner {
        require(exchangeRate_ <= 100000000000000000 * 10 ** 27, "New rate is outside bounds");
        exchangeRate = exchangeRate_;
    }

    /// @notice The amount of shares to mint to a user for the asset token deposited under ideal conditions
    /// @param assets Number of Rings tokens to deposit to the contract 
    /// @return shares Number of vault shares minted to the user based on the exchange rate
    function convertToShares(uint256 assets) external view returns(uint256) {
        uint256 shares = WMul.wmul(assets * 10**9, exchangeRate) / 10**9;
        
        return shares;
    }

    /// @notice Used to calculate the amount of an asset token to transfer to user for vault tokens burned under ideal conditions
    /// @param shares Number of vault tokens to burn
    /// @return assets Number of asset tokens to transfer to the user
    function convertToAssets(uint256 shares) external view returns(uint256) {
        uint256 assets = WDiv.wdiv(shares * 10**9, exchangeRate) / 10**9;
        return assets;
    }

    /// @notice User specifies amount of asset token to deposit in return for vault shares
    /// @param assets Number of asset tokens to deposit
    /// @param receiver Address that vault tokens will be minted to
    /// @return shares Number of vault shares to return to the user
    function deposit(uint256 assets, address receiver) external  returns(uint256) {
        uint256 shares = WMul.wmul(assets * 10**9, exchangeRate) / 10**9;
        mint(receiver, shares);
        iRings.transferFrom(msg.sender, address(this), assets);
        emit Deposit(msg.sender, receiver, assets, shares);
        return shares;
    }

    /// @notice User specifies the desired amount of vault shares in exchange for asset tokens
    /// @param shares Number of vault tokens desired by the user
    /// @param receiver Address that vault Tokens will be minted to
    /// @return assets Number of asset tokens required to mint desired amount of shares
    function mint(uint256 shares, address receiver) external  returns(uint256) {
        uint256 assets = WDiv.wdiv(shares * 10**9, exchangeRate) / 10**9;
        mint(receiver, shares);
        iRings.transferFrom(msg.sender, address(this), assets);
        emit Deposit(msg.sender, receiver, assets, shares);
        return assets;
    }

    /// @notice User specifies amount of asset tokens to withdraw from the vault
    /// @dev
    /// @param assets Number of asset token that user desires to withdraw from the vault
    /// @param receiver Address that will receive the withdrawn tokens
    /// @param owner Address that currently owns the vault tokens
    /// @return shares Number of shares required to be exchange for desired amount of asset tokens
    function withdraw(uint256 assets, address receiver, address owner) external  returns(uint256){
        uint256 shares = WMul.wmul(assets * 10**9, exchangeRate) / 10**9;
        require(_balanceOf[owner] >= shares, "Owner holds less than required amount of vault shares for requested assets");
        burn(owner, shares);
        iRings.transfer(receiver, assets);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
        return shares;
    }

    /// @notice User specifies amount of share tokens to exchange for asset tokens held in the vault
    /// @dev
    /// @param shares Number of vault tokens to be exchanged
    /// @param receiver Address that will receive withdrawn tokens
    /// @param owner Address that currently owns the vault tokens
    /// @return assets Number of asset tokens received in exchange for the specified vault tokens
    function redeem(uint256 shares, address receiver, address owner) external returns(uint256) {
        require(_balanceOf[owner] >= shares, "Owner holds less than specified amount of vault shares");
        uint256 assets = WDiv.wdiv(shares * 10**9, exchangeRate) / 10**9;
        burn(owner, shares);
        iRings.transfer(receiver, assets);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
        return assets;
    }
    
}

