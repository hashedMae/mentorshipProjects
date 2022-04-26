// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
@title Simple Name Registry
@author hashedMae
@notice A simple name registry that stores the data on chain
 */
contract Registry {


    ///@notice Mapping of a name to address of currentOwner
     mapping(string => address) public nameToUser;

    ///@dev events for tracking when names are registered or released
    event NameRegistered(string name, address user);
    event NameReleased(string name, address user);

    /**
    @notice checks if a name is currently registered to a user
    @dev for internal use only, not publicly callable
    @param _name string that is being checked if it is registered
    @return true if name is currently registered to a user, otherwise false
     */
     function _isRegistered(string memory _name) internal view returns(bool) {
         if(nameToUser[_name] != address(0x0)){
             return true;
         }
         return false;
     }

     /**
     @notice function to register a name
     @dev emits NameRegistered on success
     @param name string that is being registered
      */
    function registerName(string memory name) public {
        require(_isRegistered(name) == false, "name is already registered");
        nameToUser[name] = msg.sender;
        emit NameRegistered(name, msg.sender);
    }

    /**
    @notice function to release a name from the user
    @dev emits NameReleased on success
    @param name string that is being released from ownership
     */
    function releaseName(string memory name) public {
        require(_isRegistered(name) == true, "name currently isn't registered");
        require(nameToUser[name] == msg.sender, "name can only be released by current owner");
        nameToUser[name] = address(0x0);
        emit NameReleased(name, msg.sender);
    }

    function checkName(string memory name) public view returns(address) {
        return nameToUser[name];
    }
}
