// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IERC20 iWETH = IERC20(WETH);
    IERC20 iDAI = IERC20(DAI);

     
    IERC20 iUSDC = IERC20(USDC);

    address iceman = address(0x1);
    address maverick = address(0x2);
    address phoenix = address(0x3);
    address rooster = address(0x4);

    address[] fakes = [maverick, phoenix, rooster];

    event Deposit(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 repaid, uint256 remaining);
    event Withdraw(address indexed user, uint256 amount);

    function setUp() public virtual {
        deal(WETH, maverick, 10000 ether);
        deal(WETH, phoenix, 10000 ether);
        deal(WETH, rooster, 10000 ether);

        
        deal(DAI, iceman, 1e30);
        deal(USDC, iceman, 1e18);
        
        vm.startPrank(iceman);
        vault = new CollateralizedVault(DAI, WETH, USDC, AggregatorV3Interface(0x773616E4d11A78F511299002da57A0a94577F1f4), AggregatorV3Interface(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4));
        /**iDAI.approve(address(vault), 2**256-1);
        iUSDC.approve(address(vault), 2**256-1);
        vault.stableDeposit(1000000e18, 1000000e6);*/
        vm.stopPrank();

    }
}
