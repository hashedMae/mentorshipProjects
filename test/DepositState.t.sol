// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./LiveState.t.sol";

contract DepositState is LiveState {

    function setUp() public virtual override {
        super.setUp();

        for(uint256 i = 0; i < users.length; i++) {
            vm.startPrank(users[i]);
            iWBTC.approve(address(vault), 2**256-1);
            iUSDC.approve(address(vault), 2**256-1);
            vault.deposit(WBTC, 1e19);
            vault.deposit(USDC, 1e12);
            vm.stopPrank();
        }
    }

}