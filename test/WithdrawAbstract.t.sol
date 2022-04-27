/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./DepositAbstract.t.sol";

abstract contract WithdrawAbstract is DepositAbstract {

    function setUp() public override virtual {
        super.setUp();

        vm.prank(sonic);
        vault.depositToken(1000);
        vm.prank(tails);
        vault.depositToken(1000);
        vm.prank(knuckles);
        vault.depositToken(1000);

    }
}