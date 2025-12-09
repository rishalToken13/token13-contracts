// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title IMerchantRegistry
 * @notice Read-only interface for querying merchant status and payout settings.
 */
interface IMerchantRegistry {
    /**
     * @notice Returns the payout receiver address for a merchant.
     * @param merchantId The unique ID of the merchant.
     * @return fundReceiver The address that receives funds for the merchant.
     */
    function getMerchantFundReceiver(bytes32 merchantId)
        external
        view
        returns (address fundReceiver);

    /**
     * @notice Checks whether a merchant is currently active.
     * @param merchantId The unique ID of the merchant.
     * @return active True if the merchant is active, otherwise false.
     */
    function isMerchantActive(bytes32 merchantId)
        external
        view
        returns (bool active);

    /**
     * @notice Checks whether a token is supported for a given merchant.
     * @param merchantId The unique ID of the merchant.
     * @param token The token address to check (address(0) MAY represent native token).
     * @return supported True if the token is supported, otherwise false.
     */
    function isMerchantTokenSupported(bytes32 merchantId, address token)
        external
        view
        returns (bool supported);
}
