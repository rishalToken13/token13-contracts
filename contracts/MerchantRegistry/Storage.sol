// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @author  token13 Platform
 * @title   token13 Platform Merchant Storage Contract.
 * @dev     This contract defines the storage structure for Merchant Registry.  
 */

contract MerchantV1Storage {

    /**
      * @notice Configuration for a merchant.
      * @dev 
      * - `fundReceiver` is the address where collected funds are forwarded.  
      * - `registered` indicates whether the merchant is registered in the system.
      * - `active` indicates whether the merchant is enabled.  
      * - `supportedTokens` maps token addresses to a boolean indicating whether the merchant accepts that token.
    */
    struct MerchantConfig {
        address fundReceiver;
        bool registered;
        bool active;
        mapping(address => bool) supportedTokens;
    } 

  // Stores all merchant configurations by merchant ID.
  mapping(bytes32 => MerchantConfig) internal merchants_;

  // reserved storage space to allow for layout changes in the future.
  uint256[50] private __gap;
    
}


