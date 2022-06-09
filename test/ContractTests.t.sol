// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/CollateralizedVault.sol";
import "yield-utils/contracts/token/IERC20.sol";

contract ZeroState is Test {

    CollateralizedVault public vault;

    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IERC20 iWETH = IERC20(WETH);
    IERC20 iDAI = IERC20(DAI);
    IERC20 iUSDC = IERC20(USDC);

    address maverick = address(0x1);
    address iceman = address(0x2);
    address phoenix = address(0x3);
    address rooster = address(0x4);

    address[] fakes = [maverick, phoenix, rooster];

    event Deposit(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 repaid, uint256 remaining);
    event Withdraw(address indexed user, uint256 amount);



    function setUp() public {
        vm.prank(iceman);
        vault = new CollateralizedVault(DAI, WETH, USDC, AggregatorV3Interface(0x22B58f1EbEDfCA50feF632bD73368b2FdA96D541), AggregatorV3Interface(0x64EaC61A2DFda2c3Fa04eED49AA33D021AeC8838));

        deal(WETH, maverick, 10000e18);
        deal(WETH, phoenix, 10000e18);
        deal(WETH, rooster, 10000e18);

        
        deal(DAI, iceman, 1000000*10*18);
        deal(USDC, iceman, 1000000*10*6);
    }
}

contract ZeroStateTest is ZeroState {

    function testBalance() public {
        assertEq(iWETH.balanceOf(maverick), 10000e18);
    }

    function testDeposit(uint256 amount) public {
        vm.startPrank(maverick);
        vm.assume(amount <= 100e18);
        iWETH.approve(address(vault), 2^255);
        vault.deposit(amount);
        
        assertEq(vault.Deposits(maverick, WETH), amount);
    }

    function testDepositEmit(uint256 amount) public {
        vm.startPrank(phoenix);
        vm.assume(amount <= 1e18);
        iWETH.approve(address(vault), 2^255);
        vm.expectEmit(true, false, false, true);
        emit Deposit(phoenix, amount);
        vault.deposit(amount);
    }
}

