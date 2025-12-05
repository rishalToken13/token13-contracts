// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IMerchantRegistry {
    function isMerchant(address merchant) external view returns (bool);
    function getMerchantPayoutWallet(address merchant) external view returns (address);
    function getMerchantCommission(address merchant) external view returns (uint256);
}

/**
 * @title PaymentStorage
 * @notice Upgradeable storage contract for payment-related state.
 */
contract PaymentStorage is Initializable {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Set via PaymentCore
    IMerchantRegistry public merchantRegistry_;

    // -------------------------
    // BALANCES
    // -------------------------
    mapping(uint256 => uint256) public merchantBalances_;                // TRX balances
    mapping(uint256 => mapping(address => uint256)) public merchantTokenBalances_;

    // -------------------------
    // TOKENS / INVOICES
    // -------------------------
    mapping(address => bool) public allowedTokens_;
    mapping(bytes32 => bool) public invoicePaid_;

    mapping(address => uint256) public payerNonce_;

    uint256 public totalMerchantTRXLocked_;
    mapping(address => uint256) public totalMerchantTokenLocked_;

    // -------------------------
    // EVENTS
    // -------------------------
    event PaymentReceived(
        uint256 indexed merchantId,
        bytes32 indexed invoiceHash,
        string invoiceId,
        string orderId,
        address payer,
        address token,
        uint256 amount
    );

    event Withdraw(uint256 indexed merchantId, address indexed payout, address token, uint256 amount);
    event TokenAllowed(address token, bool allowed);
    event RescueTRX(address indexed to, uint256 amount);
    event RescueToken(address indexed token, address indexed to, uint256 amount);

    // -------------------------
    // STORAGE GAP
    // -------------------------
    uint256[50] private __gap;
}
