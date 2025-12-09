// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.18;
import { IMerchantRegistry } from  "../MerchantRegistry/IMerchantRegistry.sol";


/**
 * @author  Platform, GmbH.
 * @title   Platform Operator Storage Contract.
 * @dev     This contract holds all the storage variables for the Operator contract.
 */

contract PaymentV1Storage {

  IMerchantRegistry internal merchantRegistry_;

  struct CommissionConfig{
      address receiver;
      uint256 percentage;
  }

  CommissionConfig internal platformCommissionConfig_;

  struct CommissionBalance{
      uint256 balance;
      uint256 claimed;
  }

  /// Mapping to store the operators.
  mapping(address => CommissionBalance) internal commissionBalances_;
  
  struct SettlementDetails{
      address paymentToken;
      uint256 orderId;
      uint256 amount;
      uint256 timestamp;
      bool active;
  }

  /// Mapping to store the operators.
mapping(bytes32 => mapping(uint256 => SettlementDetails)) internal settlements_;

mapping(bytes32 => mapping(address => uint256)) internal fundReceived_;

// reserved storage space to allow for layout changes in the future.
uint256[50] private __gap;
    
}
