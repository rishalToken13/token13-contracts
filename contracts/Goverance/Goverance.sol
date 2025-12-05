// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title Governance
 * @notice Base governance contract with role-based access control (Upgradeable)
 * @dev Uses OpenZeppelin's upgradeable AccessControl with UUPS proxy pattern
 */
contract Governance is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // -------------------------
    // EVENTS
    // -------------------------
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // -------------------------
    // MODIFIERS
    // -------------------------
    modifier onlyOwner() {
        require(hasRole(OWNER_ROLE, msg.sender), "Not owner");
        _;
    }

    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, msg.sender), "Not manager");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Not operator");
        _;
    }

    // -------------------------
    // INITIALIZATION (for proxy)
    // -------------------------
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner) public initializer {
        require(_owner != address(0), "Zero address");
        
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        // Grant OWNER_ROLE to the owner
        _grantRole(OWNER_ROLE, _owner);
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(UPGRADER_ROLE, _owner);
    }

    // -------------------------
    // ROLE MANAGEMENT
    // -------------------------
    function grantOwnerRole(address _account) external onlyOwner {
        require(_account != address(0), "Zero address");
        grantRole(OWNER_ROLE, _account);
    }

    function revokeOwnerRole(address _account) external onlyOwner {
        require(_account != address(0), "Zero address");
        revokeRole(OWNER_ROLE, _account);
    }

    function grantManagerRole(address _account) external onlyOwner {
        require(_account != address(0), "Zero address");
        grantRole(MANAGER_ROLE, _account);
    }

    function revokeManagerRole(address _account) external onlyOwner {
        require(_account != address(0), "Zero address");
        revokeRole(MANAGER_ROLE, _account);
    }

    function grantOperatorRole(address _account) external onlyManager {
        require(_account != address(0), "Zero address");
        grantRole(OPERATOR_ROLE, _account);
    }

    function revokeOperatorRole(address _account) external onlyManager {
        require(_account != address(0), "Zero address");
        revokeRole(OPERATOR_ROLE, _account);
    }

    // -------------------------
    // OWNERSHIP TRANSFER
    // -------------------------
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Zero address");
        
        address _currentOwner = msg.sender;
        
        // Grant role to new owner
        grantRole(OWNER_ROLE, _newOwner);
        grantRole(DEFAULT_ADMIN_ROLE, _newOwner);
        grantRole(UPGRADER_ROLE, _newOwner);
        
        // Revoke from old owner
        revokeRole(OWNER_ROLE, _currentOwner);
        revokeRole(DEFAULT_ADMIN_ROLE, _currentOwner);
        revokeRole(UPGRADER_ROLE, _currentOwner);
        
        emit OwnershipTransferred(_currentOwner, _newOwner);
    }

    // -------------------------
    // VIEW FUNCTIONS
    // -------------------------
    function isOwner(address _account) external view returns (bool) {
        return hasRole(OWNER_ROLE, _account);
    }

    function isManager(address _account) external view returns (bool) {
        return hasRole(MANAGER_ROLE, _account);
    }

    function isOperator(address _account) external view returns (bool) {
        return hasRole(OPERATOR_ROLE, _account);
    }

    // -------------------------
    // UPGRADE AUTHORIZATION
    // -------------------------
    function _authorizeUpgrade(address _newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    // -------------------------
    // STORAGE GAP (for future upgrades)
    // -------------------------
    uint256[50] private __gap;
}
