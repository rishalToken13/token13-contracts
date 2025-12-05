// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../Goverance/Goverance.sol";

// -------------------------
// INTERFACES
// -------------------------
interface ITRC20 {
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function balanceOf(address _account) external view returns (uint256);
}

interface IMerchantRegistry {
    function isMerchant(address _merchant) external view returns (bool);
    function getMerchantPayoutWallet(address _merchant) external view returns (address);
    function getMerchantCommission(address _merchant) external view returns (uint256);
}

/**
 * @title MerchantStorage
 * @notice Storage-only contract for merchant registry data (Upgradeable).
 */
contract MerchantStorage is Initializable, Governance {

    // Set via PaymentCore
    IMerchantRegistry public merchantRegistry_;

    // -------------------------
    // CONFIG
    // -------------------------
    uint256 public constant MAX_STRING_LENGTH = 128;

    // -------------------------
    // PAUSE
    // -------------------------
    bool public paused_;

    // -------------------------
    // MERCHANTS
    // -------------------------
    // merchantId => payout
    mapping(uint256 => address) public merchantPayout_;

    // highest merchant id seen
    uint256 public maxMerchantId_;

    // -------------------------
    // PAYMENTS
    // -------------------------
    // merchantId => TRX balance
    mapping(uint256 => uint256) public merchantBalances_;

    // merchantId => token => balance
    mapping(uint256 => mapping(address => uint256)) public merchantTokenBalances_;

    // token whitelist
    mapping(address => bool) public allowedTokens_;

    // invoice uniqueness
    mapping(bytes32 => bool) public invoicePaid_;

    // payer address => nonce
    mapping(address => uint256) public payerNonce_;

    // totals for rescue checks
    uint256 public totalMerchantTRXLocked_;
    mapping(address => uint256) public totalMerchantTokenLocked_;

    // -------------------------
    // EVENTS 
    // -------------------------
    event MerchantRegistered(uint256 merchantId, address payout);
    event MerchantPayoutUpdated(uint256 merchantId, address oldPayout, address newPayout);
    event Paused(address by);
    event Unpaused(address by);

    // Payment events
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

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner) public override initializer {
        require(_owner != address(0), "Zero address");
        Governance.initialize(_owner);
        paused_ = false;
    }
}
