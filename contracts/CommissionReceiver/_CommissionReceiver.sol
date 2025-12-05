// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./_CommissionStorage.sol";

/**
 * @title CommissionReceiver
 * @notice Logic contract for handling commission receipts (placeholder)
 */
contract _CommissionReceiver is _CommissionStorage {
    // Placeholder function to receive commission (extend as needed)
    function _creditCommission(address to, uint256 amount) internal {
        commissionBalances[to] += amount;
    }
}
