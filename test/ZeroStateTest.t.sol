// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ZeroState.t.sol";

contract ZeroStateTest is ZeroState {

    function testAddCollateral() public {
        vm.prank(zaku);
        vault.addCollateral(0x6B175474E89094C44Da98b954EedeAC495271d0F, 0x6B175474E89094C44Da98b954EedeAC495271d0F);
        assertEq(vault.Collaterals(2), 0x6B175474E89094C44Da98b954EedeAC495271d0F);
    }

    function testCannotAddExistingCollateral() public {
        vm.expectRevert("token has already been added as collateral");
        vm.prank(zaku);
        vault.addCollateral(WBTC, 0xdeb288F737066589598e9214E782fa5A8eD689e8);
    }

    function testCannotAddZeroAddressAsCollateral() public {
        vm.expectRevert("token cannot be zero address");
        vm.prank(zaku);
        vault.addCollateral(address(0), address(0));
    }

    function testCannotAddZeroAddressAsOracleInterface() public {
        vm.expectRevert("oracle cannot be zero address");
        vm.prank(zaku);
        vault.addCollateral(WBTC, address(0));
    }

    function testCannotAddCollateralNotAuthed() public {
        vm.expectRevert("Access denied");
        vm.prank(rickdom);
        vault.addCollateral(0x6B175474E89094C44Da98b954EedeAC495271d0F, 0x6B175474E89094C44Da98b954EedeAC495271d0F);
    }

    function testCannotAddSameCollateralTwiceRatioNotSet() public {
        vm.expectRevert("token added but ratio not set");
        vm.startPrank(zaku);
        vault.addCollateral(0x6B175474E89094C44Da98b954EedeAC495271d0F, 0x6B175474E89094C44Da98b954EedeAC495271d0F);
        vault.addCollateral(0x6B175474E89094C44Da98b954EedeAC495271d0F, 0x6B175474E89094C44Da98b954EedeAC495271d0F);
        vm.stopPrank();
    }

    function testSetRatioNewToken(uint256 rad) public {
        rad = bound(rad, 1, 1e27-1);
        vm.prank(zaku);
        vault.addCollateral(0x6B175474E89094C44Da98b954EedeAC495271d0F, 0x6B175474E89094C44Da98b954EedeAC495271d0F);
        vm.prank(dom);
        vault.setRatio(0x6B175474E89094C44Da98b954EedeAC495271d0F, rad);
        assertEq(vault.Ratios(0x6B175474E89094C44Da98b954EedeAC495271d0F), rad);
    }

    function testCannotSetRatioUnapprovedToken(uint256 rad) public {
        rad = bound(rad, 1, 1e27-1);
        vm.expectRevert("token has not been added as collateral");
        vm.prank(zaku);
        vault.addCollateral(0x6B175474E89094C44Da98b954EedeAC495271d0F, 0x6B175474E89094C44Da98b954EedeAC495271d0F);
    }

    function testDepositWBTC(uint256 amount) public {
        amount = bound(amount, 1e9, 1000e18);
        vm.startPrank(rickdom);
        iWBTC.approve(address(vault), 2^256-1);
        vault.deposit(WBTC, amount);
        vm.stopPrank();
    }

}