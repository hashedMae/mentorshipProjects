// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title RMath
/// @author hashedMae
/// Math library for using wads with rads

library RMath {

    
    function rmul(uint256 x, uint256 y) internal pure returns(uint256 z) {
        z = x * y;
        unchecked {z /= 10**27;}
    }

    function rdiv(uint256 x, uint256 y) internal pure returns(uint256 z) {
        z = (x*10**27) / y;
    }


}


pragma solidity ^0.8.13;

import "./Rings.sol";
import "../lib/yield-utils-v2/contracts/token/ERC20.sol";
import "../lib/yield-utils-v2/contracts/token/IERC20.sol";
import "../lib/yield-utils-v2/contracts/math/WDiv.sol";
import "../lib/yield-utils-v2/contracts/math/WMul.sol";
import "../lib/yield-utils-v2/contracts/access/Ownable.sol";
import "../lib/yield-utils-v2/contracts/token/TransferHelper.sol";

/// @title WRings
/// @author hashedMae
/// @notice An ERC20 fractional wrapper for yield bearing tokens
/// @dev Utilizes WMul and WDiv math libraries from Yield-Utils-V2. Will always round down to zero.

contract WRings is ERC20,
                   Ownable {

    using TransferHelper for IERC20;
    using RMath for uint256;


    IERC20 public immutable iRings;
    uint256 public exchangeRate;

    /// @notice Emitted whenever a user wraps tokens
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
    /// @notice Emitted whenever a user unwraps tokens
    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);

    /// @param iRings_ ERC20 Interface for Rings token
    constructor(IERC20 iRings_) ERC20("WRings", "WRNG", 18) {
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
    function _convertToShares(uint256 assets) internal view returns(uint256 shares) {
        shares = assets.rmul(exchangeRate);
    }

    /// @notice Used to calculate the amount of an asset token to transfer to user for vault tokens burned under ideal conditions
    /// @param shares Number of vault tokens to burn
    /// @return assets Number of asset tokens to transfer to the user
    function _convertToAssets(uint256 shares) internal view returns(uint256 assets) {
        assets = shares.rdiv(exchangeRate);
    }

    function convertToShares(uint256 assets) external view returns(uint256 shares) {
        shares = _convertToShares(assets);
    }

    function convertToAssets(uint256 shares) external view returns(uint256 assets) {
       assets = _convertToAssets(shares);
    }

    /// @notice User specifies amount of asset token to deposit in return for vault shares
    /// @param assets Number of asset tokens to deposit
    /// @param receiver Address that vault tokens will be minted to
    /// @return shares Number of vault shares to return to the user
    function deposit(uint256 assets, address receiver) external  returns(uint256) {
        uint256 shares = _convertToShares(assets);
        _mint(receiver, shares);
        iRings.safeTransferFrom(msg.sender, address(this), assets);
        emit Deposit(msg.sender, receiver, assets, shares);
        return shares;
    }

    /// @notice User specifies the desired amount of vault shares in exchange for asset tokens
    /// @param shares Number of vault tokens desired by the user
    /// @param receiver Address that vault Tokens will be minted to
    /// @return assets Number of asset tokens required to mint desired amount of shares
    function mint(uint256 shares, address receiver) external  returns(uint256) {
        uint256 assets = _convertToAssets(shares);
        _mint(receiver, shares);
        iRings.safeTransferFrom(msg.sender, address(this), assets);
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
        uint256 shares = _convertToShares(assets);
        require(_balanceOf[owner] >= shares, "Insufficient shares");
        _burn(owner, shares);
        iRings.safeTransfer(receiver, assets);
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
        require(_balanceOf[owner] >= shares, "Insufficient shares");
        uint256 assets = _convertToAssets(shares);
        _burn(owner, shares);
        iRings.safeTransfer(receiver, assets);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
        return assets;
    }
    
}

