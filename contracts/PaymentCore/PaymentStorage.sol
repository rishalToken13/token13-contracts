// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITRC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IMerchantRegistry {
    function isMerchant(address merchant) external view returns (bool);
    function getMerchantPayoutWallet(address merchant) external view returns (address);
    function getMerchantCommission(address merchant) external view returns (uint256);
}

/**
 * @title PaymentStorage
 * @notice Storage-only contract for payment-related persistent state.
 * @dev Contains NO LOGIC and NO CONSTRUCTOR. Only state variables.
 */
contract PaymentStorage {

    // Set via PaymentCore, not constructor
    IMerchantRegistry public merchantRegistry;

    // -------------------------
    // BALANCES
    // -------------------------

    // merchantId => TRX balance
    mapping(uint256 => uint256) public merchantBalances;

    // merchantId => token => balance
    mapping(uint256 => mapping(address => uint256)) public merchantTokenBalances;

    // -------------------------
    // TOKENS / INVOICES
    // -------------------------

    mapping(address => bool) public allowedTokens;
    mapping(bytes32 => bool) public invoicePaid;

    mapping(address => uint256) public payerNonce;

    uint256 public totalMerchantTRXLocked;
    mapping(address => uint256) public totalMerchantTokenLocked;

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
