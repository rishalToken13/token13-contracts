// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


/**
 * @dev Contract module which allows children to implement an Governance
 * mechanism that can be triggered by an authorized account.
 * This Contract also inherits the Bitscrunch Storage.
 *
 * This module is used through inheritance. It Creates a security for address and Token Transfer,
 * When the are addresses and Tokens are restricted to transfer by ADMIN's OR CONTRACT Owners.
 */
abstract contract GovernanceController is Initializable, UUPSUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {

    /**
     * @dev Event emitted when an new owner is added by admin
     * @param currentOwner is the current owner.
     * @param newOwner is the new owner
    */
    event OwnershipSuggested(address indexed currentOwner, address indexed newOwner);

     /**
     * @dev Event emitted when ownership is updated
     * @param owner is the current owner.
    */
    event OwnershipAccepted(address indexed owner);

    // defining manager role
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    address private pendingAdmin;

    address private currentAdmin;

    // initialised for upgradation usage
    uint256[50] private __gap;

    error RevertedWithMessage(string message);

    error RevertedWithCode(uint16 code);


    /**
     * @dev Initializes the Governance contract  .
     */
    function __Governance_init_unchained(address _rootAdmin) internal onlyInitializing {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _rootAdmin);
        _setRoleAdmin(MANAGER_ROLE,DEFAULT_ADMIN_ROLE);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        _checkAndRevertMessage(_newOwner != address(0), "Governance:New Owner Cant be zero");
        _checkAndRevertMessage(_newOwner != msg.sender, "Governance:Admin Exists");
        pendingAdmin = _newOwner;
        currentAdmin = msg.sender;

        emit OwnershipSuggested(currentAdmin,pendingAdmin);
    }

     function acceptOwnership() public onlyPendingAdmin {
        _setupRole(DEFAULT_ADMIN_ROLE, pendingAdmin);

        // Revoke the role for the previous admin if it's not address(0)
        if (currentAdmin != address(0)) {
            _revokeRole(DEFAULT_ADMIN_ROLE, currentAdmin);
        }
        currentAdmin = address(0); // Reset the previous admin's address
        pendingAdmin = address(0);

        emit OwnershipAccepted(msg.sender);
    }

    function addManager(address _manager) external onlyOwner {
        _checkAndRevertMessage(!hasRole(MANAGER_ROLE, _manager),"Governance:Role Exists");
        _grantRole(MANAGER_ROLE, _manager);
    }

    function removeManager(address _manager) external onlyOwner {
        _checkAndRevertMessage(hasRole(MANAGER_ROLE, _manager),"Governance:Role Not Exists");
        _revokeRole(MANAGER_ROLE, _manager);
    }

    function _checkAndRevertMessage(bool condition, string memory message) internal pure {
        if(!condition){
            revert RevertedWithMessage(message);
        }
    }

    function _checkAndRevertCode(bool condition, uint16 errorCode) internal pure {
        if(!condition){
            revert RevertedWithCode(errorCode);
        }
    }

    /// @dev Upgrades the implementation of the proxy to new address.
    function _authorizeUpgrade(address) internal override onlyOwner {}

    modifier onlyOwner() {
        _checkAndRevertMessage(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Governance:RTO"
        );
        _;
    }

    modifier onlyPendingAdmin() {
        _checkAndRevertMessage(_msgSender() == pendingAdmin,"Governance:Caller Not Authorized");
        _;
    }

    modifier onlyManager() {
        _checkAndRevertMessage(
            hasRole(MANAGER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Governance:RTO"
        );
        _;
    }
}

/// Error Messages with error codes
/*
    "Governance:RTO" -> "Restricted to Owner"
*/