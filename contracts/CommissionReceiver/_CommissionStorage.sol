// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CommissionStorage
 * @notice Storage-only contract for commission receiver data (Upgradeable)
 */
contract _CommissionStorage {
    // Example placeholder state for commissions. Extend as needed.
    mapping(address => uint256) public commissionBalances;

    // Storage gap for future upgrades
    uint256[50] private __gap;
}
