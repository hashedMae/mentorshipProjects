pragma solidity ^0.8.13;

import "./RegisteredAbstract.t.sol";

contract RegisteredTest is RegisteredAbstract {

    event Released(address user, string name);


    function testCannotRegisterOwnedName() public {
        console.log("attempt to register will fail as Bubsy has already been registered by Sonic");
        vm.startPrank(bubsy);
        vm.expectRevert("name is already registered");
        r.registerName("Bubsy");
        vm.stopPrank();
    }

    function testRelease() public {
        console.log("tests that name can be released after registration");
        vm.expectEmit(true, true, false, true);
        emit Released(sonic, "Bubsy");
        vm.prank(sonic);
        r.releaseName("Bubsy");
        assertEq(r.nameToUser("Bubsy"), address(0x0));
    }

    function testOnlyOwnerCanRelease() public {
        console.log("ensures that only the owner of a name can release ownership");
        vm.startPrank(sonic);
        vm.expectRevert("name can only be released by current owner");
        r.releaseName("Mario");
        vm.stopPrank();
    }
}