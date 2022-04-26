pragma solidity ^0.8.13;

import "./ZeroState.t.sol";

contract RegisteringTests is ZeroState {

    event Registered(address user, string name);

    function testRegister() public {
        console.log("registers a name");
        vm.expectEmit(true, true, false, true);
        emit Registered(sonic, "Sonic");
        vm.prank(sonic);
        r.registerName("Sonic");
        assertEq(r.nameToUser("Sonic"), sonic);
    }
}