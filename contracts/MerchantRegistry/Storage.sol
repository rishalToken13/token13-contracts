// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.18;

/**
 * @author  Platform, GmbH.
 * @title   Platform Operator Storage Contract.
 * @dev     This contract holds all the storage variables for the Operator contract.
 */

contract MerchantV1Storage {

    /**
     * @dev Struct representing a Operator.
     * @param minFeeCut is the fee cut percentage for delegators.
     * @param maxRewardCut is the reward cut percentage for delegators.
     * @param fileHash is the operator file hash.
     * @param settledAmount is the mapping of Tokens received on settlement.
     */
    struct MerchantConfig {
        address fundReceiver;
        bool active;
        mapping(address => bool) supportedTokens;
    } 

  /// Mapping to store the operators.
  mapping(bytes32 => MerchantConfig) internal merchants_;

  // reserved storage space to allow for layout changes in the future.
  uint256[50] private __gap;
    
}
