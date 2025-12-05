// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../Goverance/Goverance.sol";

// -------------------------
// INTERFACES
// -------------------------
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
* @title MerchantStorage
* @notice Storage-only contract for merchant registry data (Upgradeable).
*/
contract MerchantStorage is Initializable, Governance {
    // Set via PaymentCore, not constructor
    IMerchantRegistry public merchantRegistry;
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
// merchantId => payout address
mapping(uint256 => address) public merchantPayout;

// highest merchant id seen (bookkeeping only)
uint256 public maxMerchantId;

// -------------------------
// PAYMENTS
// -------------------------
// merchantId => TRX balance
mapping(uint256 => uint256) public merchantBalances;

// merchantId => token => balance
mapping(uint256 => mapping(address => uint256)) public merchantTokenBalances;

// token whitelist
mapping(address => bool) public allowedTokens;

// invoice uniqueness
mapping(bytes32 => bool) public invoicePaid;

// payer tracking
mapping(address => uint256) public payerNonce;

// totals for rescue checks
uint256 public totalMerchantTRXLocked;
mapping(address => uint256) public totalMerchantTokenLocked;


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
// STORAGE GAP for future variables
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