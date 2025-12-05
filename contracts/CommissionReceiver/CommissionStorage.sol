// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./_CommissionStorage.sol";

/**
 * Compatibility wrapper: exposes the original `CommissionStorage` name
 * while delegating implementation to `_CommissionStorage`.
 */
contract CommissionStorage is _CommissionStorage {}