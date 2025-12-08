// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title IMerchantRegistry
 * @notice Interface for querying merchant registration and payout settings.
 */
interface IMerchantRegistry {

    /**
        * @notice Checks whether a given token is supported for the specified merchant.
        * @param merchantId The unique ID of the merchant.
        * @param token The token address to check.
        * @return True if the token is supported, otherwise false.
    */
    function isMerchantTokenSupported(bytes32 merchantId, address token)
        external
        view
        returns (bool);

    /**
        * @notice Returns whether the merchant is currently active.
        * @param merchantId The unique ID of the merchant.
        * @return True if the merchant is active, otherwise false.
    */
    function isMerchantActive(bytes32 merchantId)
        external
        view
        returns (bool);

    /**
        * @notice Retrieves the payout receiver address for the merchant.
        * @param merchantId The unique ID of the merchant.
        * @return The address that receives merchant funds.
    */
    function getMerchantFundReceiver(bytes32 merchantId)
        external
        view
        returns (address);

}
