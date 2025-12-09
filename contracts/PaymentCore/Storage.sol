// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import { IMerchantRegistry } from  "../MerchantRegistry/IMerchantRegistry.sol";


/**
 * @author  token13 Platform.
 * @title   token13 Platform Payment Storage Contract.
 * @dev     This contract holds all the storage variables for the Payment Core module.
 */

contract PaymentV1Storage {
    
    /**
     * @notice Reference to MerchantRegistry contract.
     * @dev Used to read merchant status, fund address, and supported tokens.
    */
    IMerchantRegistry internal merchantRegistry_;

    /**
     * @notice Platform-wide commission configuration.
     * @dev
     *  - `receiver`: Address where commissions are collected.
     *  - `percentage`: Commission rate (uses percentageMultiplier_ from logic).
    */
    struct CommissionConfig{
        address receiver;
        uint256 percentage;
    }

    /// @notice Stores current commission configuration.
    CommissionConfig internal platformCommissionConfig_;

    /**
     * @notice Tracks commission balances per token.
     * @dev 
     *  - `balance` : Amount accumulated but not yet withdrawn.
     *  - `claimed` : Total amount already withdrawn.
    */
    struct CommissionBalance{
        uint256 balance;
        uint256 claimed;
    }

    /// @notice Mapping of token address to CommissionBalance.
    mapping(address => CommissionBalance) internal commissionBalances_;
    
    /**
     * @notice Payment settlement data for each invoice.
     * @dev 
     *  - Keyed by merchantId => invoiceId.
     *  - Stores the payment token used, order linkage, amount, and timestamp.
    */
    struct SettlementDetails{
        address paymentToken;
        uint256 orderId;
        uint256 amount;
        uint256 timestamp;
        bool active;
    }

    /// @notice Mapping of merchantId to invoiceId to SettlementDetails.
    mapping(bytes32 => mapping(uint256 => SettlementDetails)) internal settlements_;

    /// @notice Tracks total funds received by each merchant per token.
    mapping(bytes32 => mapping(address => uint256)) internal fundReceived_;

    // reserved storage space to allow for layout changes in the future.
    uint256[50] private __gap;
    
}
