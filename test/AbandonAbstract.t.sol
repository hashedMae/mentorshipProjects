pragma solidity ^0.8.13;

import "./RegisteredAbstract.t.sol";

abstract contract AbandonAbstract is RegisteredAbstract {

    function setUp() public virtual override{
        super.setUp();
        vm.prank(sonic);
        r.releaseName("Bubsy");
    }

}