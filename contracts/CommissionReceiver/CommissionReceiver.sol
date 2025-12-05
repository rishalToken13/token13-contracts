// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./_CommissionReceiver.sol";

/**
 * Compatibility wrapper: exposes the original `CommissionReceiver` name
 * while delegating implementation to `_CommissionReceiver`.
 */
contract CommissionReceiver is _CommissionReceiver {}