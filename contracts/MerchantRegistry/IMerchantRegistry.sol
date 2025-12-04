// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IMerchantRegistry
 * @notice Interface to fetch merchant details
 */
interface IMerchantRegistry {

    /**
     * @notice Returns TRUE if merchant is registered
     * @param merchant The merchant's identifier (wallet or merchant ID)
     */
    function isMerchant(address merchant) external view returns (bool);

    /**
     * @notice Fetch merchant payout/settlement address
     * @param merchant The merchant wallet/ID used during payment
     * @return payout Wallet where funds must be sent
     */
    function getMerchantPayoutWallet(address merchant)
        external
        view
        returns (address payout);
    
}
