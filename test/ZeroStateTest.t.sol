// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ZeroState.t.sol";

contract ZeroStateTest is ZeroState {

    function testAddCollateral() public {
        vm.prank(zaku);
        vault.addCollateral(WBTC, oBTC);
        
    }

    function testCannotAddExistingCollateral() public {
        vm.prank(zaku);
        vault.addCollateral(WBTC, oBTC);
        vm.prank(dom);
        vault.setRatio(WBTC, 5e26);
        vm.expectRevert("token has already been added as collateral");
        vm.prank(zaku);
        vault.addCollateral(WBTC, oBTC);

    }

    function testCannotAddZeroAddressAsCollateral() public {
        vm.expectRevert("token cannot be zero address");
        vm.prank(zaku);
        vault.addCollateral(address(0), oZero);
    }

    function testCannotAddZeroAddressAsOracleInterface() public {
        vm.expectRevert("oracle cannot be zero address");
        vm.prank(zaku);
        vault.addCollateral(WBTC, oZero);
    }

    function testCannotAddSameCollateralTwiceRatioNotSet() public {
        vm.startPrank(zaku);
        vault.addCollateral(WBTC, oBTC);
        vm.expectRevert("token added but ratio not set");
        vault.addCollateral(WBTC, oBTC);
        vm.stopPrank();
    }

    function testSetRatioNewToken(uint256 rad) public {
        rad = bound(rad, 1, 1e27-1);
        vm.prank(zaku);
        vault.addCollateral(WBTC, oBTC);
        vm.prank(dom);
        vault.setRatio(WBTC, rad);
        assertEq(vault.Ratios(WBTC), rad);
    }

    function testCannotSetRatioUnapprovedToken(uint256 rad) public {
        rad = bound(rad, 1, 1e27-1);
        ///vm.expectRevert("token has not been added as collateral");
        vm.prank(zaku);
        vault.addCollateral(WBTC, oBTC);
    }
}