// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "yield-utils-v2/token/ERC20.sol";
import "yield-utils-v2/token/IERC20.sol";
import "yield-utils-v2/math/WDiv.sol";
import "yield-utils-v2/math/WMul.sol";
import "yield-utils-v2/access/Ownable.sol";
import "yield-utils-v2/token/TransferHelper.sol";
import "yield-utils-v2/cast/CastU256U128.sol";

import "./interfaces/IERC3156FlashBorrower.sol";
import "./interfaces/IERC3156FlashLender.sol";




/// @title FlashVault
/// @author hashedMae
/// @notice A Yield Bearing Flash Loan Vault
/// @dev Utilizes WMul and WDiv math libraries from Yield-Utils-V2. Will always round down to zero.

contract FlashVault is ERC20, IERC3156FlashLender {

    using TransferHelper for IERC20;
    using CastU256U128 for uint256;
    
    /// @notice Emitted whenever a user wraps tokens
    /// @param caller address of user that is submitting the transaction
    /// @param receiver address of the user that'll receive the share tokens
    /// @param assets amount of tokens to deposit
    /// @param shares amount of shares that will be minted
    event Deposit(address indexed caller, address indexed receiver, uint256 assets, uint256 shares);

    /// @notice Emitted whenever a user unwraps tokens
    /// @param caller address of the user submitting the transaction
    /// @param receiver address of the user that'll receive the withdrawn tokens
    /// @param owner address of the user that owns the share tokens
    /// @param assets amount of tokens that are being withdrawn
    /// @param shares amount of shares that are being burned
    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);

    IERC20 public immutable asset;
    uint256 public constant fee = 1e16;
    uint256 public constant maxSupply = 2**128-1;
    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
   

    /// @param asset_ ERC20 Interface for Rings token
    constructor(IERC20 asset_) ERC20("WRings", "WRNG", 18) {
        asset = asset_;
    }

    /// @return totalManagedAssets Balance of the asset token within the vault
    function totalAssets() external view returns(uint256 totalManagedAssets) {
        totalManagedAssets = _totalAssets();
    }

    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns(uint256) {
        require(token == address(asset), "Token not available");
        return _totalAssets();
    }

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns(uint256) {
        require(token == address(asset), "WRings: Unsupported token");
        return _flashFee(amount);
    }
    
    /// @notice the amount of shares the Vault would exchange for the amount of assets provided under ideal conditions
    /// @param assets the amount of assets to send to the vault
    /// @return shares the amount of shares received under ideal conditions
    function convertToShares(uint128 assets) external view returns(uint256 shares){
        shares = _convertToShares(assets);
    }

    /// @notice the amount of assets the Vault would exchange for stated shares under ideal conditions
    /// @param shares the amount of shares being exchanged
    /// @return assets the amount of assets received under ideal conditions
    function convertToAssets(uint128 shares) external view returns(uint256 assets){
        assets = _convertToAssets(shares);
    }

    /// @notice shows the max amount of assets that can be deposited for or by a user
    /// @param receiver address of user that would receive the tokens
    /// @return maxAssets max amount of assets that can be deposited
    function maxDeposit(address receiver) external view returns(uint256 maxAssets) {
        maxAssets = _convertToAssets(uint128(maxSupply) - uint128(_totalSupply));
    }
    
    /// @notice shows the max amount of shares that can be minted for or by a user
    /// @param receiver address of user that would receive the shares
    /// @return maxShares max amount of shares a user can receive
    function maxMint(address receiver) external view returns(uint256 maxShares) {
        maxShares = maxSupply - _totalSupply;
    }

    /// @notice max amount of tokens that could be withdrawn by a user
    /// @param owner address for the owner of the shares being redeemed
    /// @return maxAssets maximum number of assets owner is able to withdraw
    function maxWithdraw(address owner) external view returns(uint256 maxAssets) {
        uint256 _bal = _balanceOf[owner];
        maxAssets = _convertToAssets(uint128(_bal));
    }

    /// @notice max amout of shares a user could redeem
    /// @param owner address for the owner of the shares being redeemed
    /// @return maxShares 
    function maxRedeem(address owner) external view returns(uint256 maxShares) {
        maxShares = _balanceOf[owner];
    }

    /// @notice used to simulate a deposit at the current block
    /// @param assets amount of assets being deposited
    /// @return shares amount of shares minted in exchange for assets
    function previewDeposit(uint128 assets) external view returns(uint256 shares) {
        shares = _convertToShares(assets);
    }

    /// @notice used to simulate a deposit at the current block
    /// @param shares desired amount of shares to mint
    /// @return assets amount of asset token required for desired shares
    function previewMint(uint128 shares) external view returns(uint256 assets) {
        assets = _convertToAssets(shares);
    }

    /// @notice used to simulate a withdrawal and the shares required
    /// @param assets desired amount of asset token to receive
    /// @return shares amount of shares required to redeem
    function previewWithdraw(uint128 assets) external view returns(uint256 shares) {
        shares = _convertToShares(assets);
    }

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
        ) external override returns (bool) {
        require(token == address(asset), "WRings: Unsupported token");
        uint256 fee_ = _flashFee(amount);
        require(
            asset.transfer(address(receiver), amount),
            "WRings: Transfer failed"
        );
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee_, data) == CALLBACK_SUCCESS,
            "IERC3156: Callback failed"
        );
        
        
        require(
            asset.transferFrom(address(receiver), address(this), amount + fee_),
            "WRings: Repay failed"
        );
        return true;
    }

    function init(uint128 assets, address receiver) external returns(uint256) {
        _mint(receiver, assets);
        asset.safeTransferFrom(msg.sender, address(this), assets);
        return assets;
    }

     /// @notice User specifies amount of asset token to deposit in return for vault shares
    /// @param assets Number of asset tokens to deposit
    /// @param receiver Address that vault tokens will be minted to
    /// @return shares Number of vault shares to return to the user
    function deposit(uint128 assets, address receiver) external  returns(uint256 shares) {
        shares = _convertToShares(assets);
        require(_totalSupply + shares <= maxSupply, "WRings:request would exceed max shares");
        _mint(receiver, shares);
        asset.safeTransferFrom(msg.sender, address(this), assets);
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @notice User specifies the desired amount of vault shares in exchange for asset tokens
    /// @param shares Number of vault tokens desired by the user
    /// @param receiver Address that vault Tokens will be minted to
    /// @return assets Number of asset tokens required to mint desired amount of shares
    function mint(uint128 shares, address receiver) external  returns(uint256 assets) {
        require(_totalSupply + shares <= maxSupply, "WRings:request would exceed max shares");
        assets = _convertToAssets(shares);
        _mint(receiver, shares);
        asset.safeTransferFrom(msg.sender, address(this), assets);
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @notice User specifies amount of asset tokens to withdraw from the vault
    /// @dev
    /// @param assets Number of asset token that user desires to withdraw from the vault
    /// @param receiver Address that will receive the withdrawn tokens
    /// @param owner Address that currently owns the vault tokens
    /// @return shares Number of shares required to be exchange for desired amount of asset tokens
    function withdraw(uint128 assets, address receiver, address owner) external  returns(uint256 shares){
        shares = _convertToShares(assets);
        require(_balanceOf[owner] >= shares, "Insufficient shares");
        _burn(owner, shares);
        asset.safeTransfer(receiver, assets);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
        return shares;
    }

    /// @notice User specifies amount of share tokens to exchange for asset tokens held in the vault
    /// @dev
    /// @param shares Number of vault tokens to be exchanged
    /// @param receiver Address that will receive withdrawn tokens
    /// @param owner Address that currently owns the vault tokens
    /// @return assets Number of asset tokens received in exchange for the specified vault tokens
    function redeem(uint128 shares, address receiver, address owner) external returns(uint256 assets) {
        require(_balanceOf[owner] >= shares, "Insufficient shares");
        assets = _convertToAssets(shares);
        _burn(owner, shares);
        asset.safeTransfer(receiver, assets);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /// @notice The amount of shares to mint to a user for the asset token deposited under ideal conditions
    /// @param assets Number of Rings tokens to deposit to the contract 
    /// @return shares Number of vault shares minted to the user based on the exchange rate
    function _convertToShares(uint128 assets) internal view returns(uint256 shares) {
        uint256 _reserves = asset.balanceOf(address(this));
        uint256 _assets = uint256(assets);
        shares = _assets * _totalSupply / _reserves;    }

    /// @notice Used to calculate the amount of an asset token to transfer to user for vault tokens burned under ideal conditions
    /// @param shares Number of vault tokens to burn
    /// @return assets Number of asset tokens to transfer to the user
    function _convertToAssets(uint128 shares) internal view returns(uint256 assets) {
       uint256 _reserves = asset.balanceOf(address(this));
       uint256 _shares = uint256(shares);
       assets = _shares * _reserves / _totalSupply;    }

    function _totalAssets() internal view returns(uint256) {
        return asset.balanceOf(address(this));
    }

    function _flashFee(uint256 amount) internal view returns(uint256) {
        return WMul.wmul(amount, fee);
    }
}