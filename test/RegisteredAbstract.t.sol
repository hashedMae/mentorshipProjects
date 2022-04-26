pragma solidity ^0.8.13;

import "./ZeroState.t.sol";

abstract contract RegisteredAbstract is ZeroState {

    function setUp() public virtual override {
        super.setUp();
        vm.startPrank(sonic);
        r.registerName("Sonic");
        r.registerName("Bubsy");
        vm.stopPrank();
        vm.prank(mario);
        r.registerName("Mario");
    }
}