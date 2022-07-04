// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./LiveState.t.sol";

contract LiveStateTest is LiveState {

    using stdStorage for StdStorage;
    
    function testDeposit(uint256 amount) public {
        amount = bound(amount, 1e9, 1e21);
        vm.startPrank(rickdom);
        iWBTC.approve(address(vault), 2**256-1);
        vault.deposit(WBTC, amount);
        assertEq(vault.Deposits(rickdom, WBTC), amount);
    }


function testLiquidate() public {
        
        stdstore
            .target(address(vault))
            .sig(vault.Debt.selector)
            .with_key(zaku)
            .checked_write(1*10**18);
        stdstore
            .target(address(vault))
            .sig(vault.Deposits.selector)
            .with_key(zaku)
            .with_key(USDC)
            .checked_write(60*10**6);
        vm.prank(rx78);
        vault.liquidate(zaku); 
    }
}