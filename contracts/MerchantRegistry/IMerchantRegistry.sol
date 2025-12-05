// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IMerchantRegistry
 * @notice Interface for querying merchant registration and payout settings.
 */
interface IMerchantRegistry {

    /**
     * @notice Returns true if the merchant is registered.
     * @param _merchant The merchant address being queried.
     * @return _isRegistered True if the merchant is in the registry.
     */
    function isMerchant(address _merchant)
        external
        view
        returns (bool _isRegistered);

    /**
     * @notice Returns the payout (settlement) wallet for the merchant.
     * @dev SHOULD revert if `_merchant` is not registered.
     * @param _merchant The merchant whose payout wallet is requested.
     * @return _payout The payout wallet address.
     */
    function getMerchantPayoutWallet(address _merchant)
        external
        view
        returns (address _payout);
}
