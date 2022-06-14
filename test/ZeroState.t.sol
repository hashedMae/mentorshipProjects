// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/CollateralizedVault.sol";
import "yield-utils/contracts/token/IERC20.sol";

contract ZeroState is Test {

    uint256 internal constant UINT256_MAX = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    CollateralizedVault public vault;

    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
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
/** 
contract ZeroStateTest is ZeroState {

    function testOwnerStableDeposit(uint256 daiIn, uint256 usdcIn) public{
        daiIn = bound(daiIn, 1e18, 1000000e18);
        usdcIn = bound(usdcIn, 1e6, 1000000e6);

        vm.startPrank(iceman);
        iDAI.approve(address(vault), 2**256-1);
        iUSDC.approve(address(vault), 2**256-1);
        vault.stableDeposit(daiIn, usdcIn);
        vm.stopPrank;

        assertEq(iDAI.balanceOf(address(vault)), daiIn);
        assertEq(iUSDC.balanceOf(address(vault)), usdcIn);

    }

    function testDeposit(uint256 amount) public {
        amount = bound(amount, 10000, 10000e18);

        vm.startPrank(maverick);
        iWETH.approve(address(vault), 10000e18);
        vault.deposit(amount, maverick);
        vm.stopPrank();
        
        assertEq(vault.Deposits(maverick, WETH), amount);
    }

    function testDepositEmit(uint256 amount) public {
        amount = bound(amount, 10000, 100000e18);

        vm.expectEmit(true, false, false, true);
        emit Deposit(phoenix, amount);

        vm.startPrank(phoenix);
        iWETH.approve(address(vault), 10000e18);
        vault.deposit(amount, phoenix);
        vm.stopPrank();
    }
}

*/