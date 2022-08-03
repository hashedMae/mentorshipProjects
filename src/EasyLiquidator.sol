// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "yield-utils-v2/token/IERC20.sol";
import "yield-utils-v2/token/TransferHelper.sol";
import "./interfaces/IERC3156FlashBorrower.sol";
import "./interfaces/IERC3156FlashLender.sol";
import "./interfaces/ISimpleSwap.sol";
import "./interfaces/ICollateralizedVault.sol";


contract EasyLiquidator is IERC3156FlashBorrower {

    using TransferHelper for IERC20;

    enum Action {NORMAL, OTHER}

    IERC3156FlashLender public immutable lDAI;
    ///IERC3156FlashLender public immutable lUSDC;
    
    ISimpleSwap public immutable sDAI;
   /// ISimpleSwap public immutable sUSDC;

    /// @notice contract targeted for liquidations, can carry multiple user vaults, deposits in WETH, debts in DAI and USDC
    ICollateralizedVault public vault;

    IERC20 public immutable WETH;
    IERC20 public immutable DAI;

    event Liquidation(address indexed liquidator, 
        address indexed liquidatee,
        uint256 debtDAI,
        uint256 profitWETH);

    constructor(IERC3156FlashLender lDAI_, 
        ISimpleSwap sDAI_,
        ICollateralizedVault vault_,
        IERC20 WETH_,
        IERC20 DAI_
    ){
        lDAI = lDAI_;
        sDAI = sDAI_;
        vault = vault_;
        WETH = WETH_;
        DAI = DAI_;
    }

    ///@notice function for liquidating a undercollateralized vault of a specific user
    ///@param user address of the user being targeted
    function liquidate(address user) external {
        (uint256 dDAI, ) = vault.tokenDebts(user);
        uint256 balWETH = WETH.balanceOf(address(this));

        uint256 aDAI = DAI.allowance(address(this), address(lDAI));
        uint256 fDAI = lDAI.flashFee(address(DAI), dDAI);
        uint256 rDAI = dDAI + fDAI;

        bytes memory data = abi.encode(Action.NORMAL, user, rDAI);
        DAI.approve(address(lDAI), aDAI + rDAI);
        lDAI.flashLoan(this, address(DAI), dDAI, data);
        WETH.safeTransfer(msg.sender, WETH.balanceOf(address(this)) - balWETH);

        

        
    }
        
    

    /// @dev ERC-3156 Flash loan callback
    function onFlashLoan(
        address initiator,
        address token,

        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns(bytes32) {
        require(
            msg.sender == address(lDAI),
            "FlashBorrower: Untrusted lender"
        );
        require(
            initiator == address(this),
            "FlashBorrower: Untrusted loan initiator"
        );
        (Action action, address user, uint256 rDAI) = abi.decode(data, (Action, address, uint256));
        if (action == Action.NORMAL) {
            (uint256 dDAI, ) = vault.tokenDebts(user);
            DAI.approve(address(vault), dDAI);
        

            uint256 pWETH = vault.liquidate(user);
            WETH.approve(address(sDAI), pWETH);

            pWETH -= sDAI.swapYforExactX(rDAI);
        

            WETH.safeTransfer(initiator, pWETH);
            emit Liquidation(initiator, user, dDAI, pWETH);
            
        } else if (action == Action.OTHER) {
            // do another
        }
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}