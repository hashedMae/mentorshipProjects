// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ZeroState.t.sol";

contract LiveState is ZeroState {

    function setUp() public virtual override {
        super.setUp();

        uint256 rBTC = 65e25;
        uint256 rUSDC = 85e25;

        vm.startPrank(zaku);
        vault.addCollateral(WBTC, oBTC);
        vault.addCollateral(USDC, oUSDC);
        vm.stopPrank();
        
        vm.startPrank(dom);
        vault.setRatio(WBTC, rBTC);
        vault.setRatio(USDC, rUSDC);
        vm.stopPrank();
    }
}