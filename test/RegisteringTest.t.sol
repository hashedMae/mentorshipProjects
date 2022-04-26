pragma solidity ^0.8.13;

import "./ZeroState.t.sol";

contract RegisteringTests is ZeroState {

    function testRegister() public {
        console.log("registers a name");
        vm.prank(sonic);
        r.registerName("Sonic");
        assertEq(r.checkName("Sonic"), sonic);
        /*
        had tried using
        assertEq(r.nameToUser("Sonic"), sonic)
        but received  TypeError: Indexed expression has to be a type, mapping or array (is function (string memory) view external returns (address))
        so created getter function *shrug*
        */

    }
}