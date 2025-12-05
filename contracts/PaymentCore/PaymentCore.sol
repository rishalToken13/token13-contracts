// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../MerchantRegistry/MerchantStorage.sol";


/**
* @title PaymentCore
* @notice Payment logic. Inherits storage contracts. (Upgradeable)
*/
contract PaymentCore is MerchantStorage, ReentrancyGuardUpgradeable {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner) public override initializer {
        MerchantStorage.initialize(_owner);
        __ReentrancyGuard_init();
    }


// -------------------------
// MODIFIERS
// -------------------------
modifier notPaused() {
require(!paused_, "Paused");
_;
}


modifier onlyMerchantPayout(uint256 merchantId) {
require(msg.sender == merchantPayout[merchantId], "Not merchant payout");
_;
}


// -------------------------
// ADMIN
// -------------------------
function allowToken(address token, bool allowed) external onlyOwner {
    require(token != address(0), "Zero");
    require(_isContract(token), "Not contract");
    allowedTokens[token] = allowed;
    emit TokenAllowed(token, allowed);
}


// -------------------------
// PAYMENTS (TRX)
// -------------------------
function payTRX(
uint256 merchantId,
string calldata invoiceId,
string calldata orderId
) external payable notPaused nonReentrant {
    _validateStrings(invoiceId, orderId);
    require(merchantPayout[merchantId] != address(0), "Not merchant");
    require(msg.value > 0, "Zero TRX");


    payerNonce[msg.sender]++;

    bytes32 _hash = _invoiceHash(merchantId, invoiceId, orderId);
    require(!invoicePaid[_hash], "Paid");

    invoicePaid[_hash] = true;
    merchantBalances[merchantId] += msg.value;
    totalMerchantTRXLocked += msg.value;

    emit PaymentReceived(merchantId, _hash, invoiceId, orderId, msg.sender, address(0), msg.value);
}


// -------------------------
// PAYMENTS (TRC20)
// -------------------------
function payToken(
address token,
uint256 merchantId,
string calldata invoiceId,
string calldata orderId,
uint256 amount
) external notPaused nonReentrant {
    _validateStrings(invoiceId, orderId);
    require(allowedTokens[token], "Token NA");
    require(merchantPayout[merchantId] != address(0), "Not merchant");
    require(amount > 0, "Zero amount");


    payerNonce[msg.sender]++;

    bytes32 _hash = _invoiceHash(merchantId, invoiceId, orderId);
    require(!invoicePaid[_hash], "Paid");

    uint256 _received = _transferExact(token, msg.sender, amount);

    invoicePaid[_hash] = true;
    merchantTokenBalances[merchantId][token] += _received;
    totalMerchantTokenLocked[token] += _received;

    emit PaymentReceived(merchantId, _hash, invoiceId, orderId, msg.sender, token, _received);
}


// -------------------------
// WITHDRAWALS
// -------------------------
function withdrawTRX(uint256 merchantId, uint256 amount)
external
nonReentrant
onlyMerchantPayout(merchantId)
{
    uint256 _bal = merchantBalances[merchantId];

    if (amount == 0) amount = _bal;


    require(amount > 0, "Zero");
    require(_bal >= amount, "Insufficient");

    merchantBalances[merchantId] = _bal - amount;
    totalMerchantTRXLocked -= amount;

    (bool _ok, ) = msg.sender.call{value: amount}("");
    require(_ok, "Transfer fail");

    emit Withdraw(merchantId, msg.sender, address(0), amount);
}


function withdrawToken(address token, uint256 merchantId, uint256 amount)
external
    nonReentrant
    onlyMerchantPayout(merchantId)
    {
    uint256 _bal = merchantTokenBalances[merchantId][token];
    if (amount == 0) amount = _bal;

    require(amount > 0, "Zero");
    require(_bal >= amount, "Insufficient");

    merchantTokenBalances[merchantId][token] = _bal - amount;
    totalMerchantTokenLocked[token] -= amount;
    _safeTransfer(token, msg.sender, amount);

    emit Withdraw(merchantId, msg.sender, token, amount);
}

// -------------------------
// RESCUE
// -------------------------
function rescueTRX(address payable to, uint256 amount)
external
onlyOwner
nonReentrant
{
    require(to != address(0), "Zero");
    require(amount > 0, "Zero");

    uint256 _bal = address(this).balance;
    require(_bal >= totalMerchantTRXLocked, "Inconsistent balances");

    uint256 _free = _bal - totalMerchantTRXLocked;
    require(amount <= _free, "Merchant TRX locked");

    (bool _ok, ) = to.call{value: amount}("");
    require(_ok, "Fail");

    emit RescueTRX(to, amount);
}


function rescueToken(address token, address to, uint256 amount)
external
onlyOwner
nonReentrant
{
    require(token != address(0), "Zero");
    require(to != address(0), "Zero");
    require(amount > 0, "Zero");


    uint256 bal = ITRC20(token).balanceOf(address(this));
    uint256 locked = totalMerchantTokenLocked[token];
    require(bal >= locked, "Inconsistent");
    uint256 free = bal - locked;
    require(amount <= free, "Locked to merchants");


    _safeTransfer(token, to, amount);


    emit RescueToken(token, to, amount);
}

// -------------------------
// HELPERS
// -------------------------
function _validateStrings(string calldata invoiceId, string calldata orderId) internal pure {
require(bytes(invoiceId).length > 0 && bytes(invoiceId).length <= MAX_STRING_LENGTH, "Bad invoiceId");
require(bytes(orderId).length > 0 && bytes(orderId).length <= MAX_STRING_LENGTH, "Bad orderId");
}


function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
(bool _ok, bytes memory _data) =
token.call(abi.encodeWithSelector(ITRC20.transferFrom.selector, from, to, amount));
require(_ok && (_data.length == 0 || abi.decode(_data, (bool))), "transferFrom fail");
}


function _safeTransfer(address token, address to, uint256 amount) internal {
(bool _ok, bytes memory _data) =
token.call(abi.encodeWithSelector(ITRC20.transfer.selector, to, amount));
require(_ok && (_data.length == 0 || abi.decode(_data, (bool))), "transfer fail");
}


function _transferExact(address token, address from, uint256 amount)
internal
returns (uint256 received)
{
    uint256 _beforeBal = ITRC20(token).balanceOf(address(this));
    _safeTransferFrom(token, from, address(this), amount);
    uint256 _afterBal = ITRC20(token).balanceOf(address(this));
    received = _afterBal - _beforeBal;
    require(received == amount, "Fee token not allowed");
}


function _invoiceHash(
uint256 merchantId,
string memory invoiceId,
string memory orderId
) internal pure returns (bytes32) {
    return keccak256(abi.encode(merchantId, invoiceId, orderId));
}


function _isContract(address a) internal view returns (bool) {
    return a.code.length > 0;
}
}