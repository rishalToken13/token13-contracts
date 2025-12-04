// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Merchant Payment Collection Contract (TRX + TRC20)
 * @notice Handles secure invoice payments using TRX or approved TRC20 tokens
 * @dev Production-grade: reentrancy-safe, pausable, strong merchant separation,
 *      rescue protection, exact token transfer validation, strict input controls.
 */

interface ITRC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ReentrancyGuard {
    uint256 private constant _ENTERED = 2;
    uint256 private constant _NOT_ENTERED = 1;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "Reentrancy");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract MerchantCollection is ReentrancyGuard {

    // -----------------------------------------------------------------------
    // CONFIG
    // -----------------------------------------------------------------------

    uint256 public constant MAX_STRING_LENGTH = 128;

    // -----------------------------------------------------------------------
    // STATE VARIABLES
    // -----------------------------------------------------------------------

    address public owner;
    bool public paused;

    // merchantID => payoutAddress
    mapping(uint256 => address) public merchantPayout;

    // merchantID => TRX balance
    mapping(uint256 => uint256) public merchantBalances;

    // merchantID => token => balance
    mapping(uint256 => mapping(address => uint256)) public merchantTokenBalances;

    // token whitelist
    mapping(address => bool) public allowedTokens;

    // invoice uniqueness
    mapping(bytes32 => bool) public invoicePaid;

    // payer tracking (optional)
    mapping(address => uint256) public payerNonce;

    uint256 public maxMerchantId;

    // totals for quick rescue checks (prevents expensive loops)
    uint256 public totalMerchantTRXLocked;
    mapping(address => uint256) public totalMerchantTokenLocked;

    // -----------------------------------------------------------------------
    // EVENTS
    // -----------------------------------------------------------------------

    event MerchantRegistered(uint256 merchantId, address payout);
    event MerchantPayoutUpdated(uint256 merchantId, address oldPayout, address newPayout);

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

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event Paused(address by);
    event Unpaused(address by);
    event TokenAllowed(address token, bool allowed);

    event RescueTRX(address indexed to, uint256 amount);
    event RescueToken(address indexed token, address indexed to, uint256 amount);

    // -----------------------------------------------------------------------
    // MODIFIERS
    // -----------------------------------------------------------------------

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier notPaused() {
        require(!paused, "Paused");
        _;
    }

    modifier onlyMerchantPayout(uint256 merchantId) {
        require(msg.sender == merchantPayout[merchantId], "Not merchant payout");
        _;
    }

    // -----------------------------------------------------------------------
    // CONSTRUCTOR
    // -----------------------------------------------------------------------

    constructor() {
        owner = msg.sender;
        paused = false;
    }


    // -----------------------------------------------------------------------
    // ADMIN CONTROLS
    // -----------------------------------------------------------------------

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero");
        address old = owner;
        owner = newOwner;
        emit OwnershipTransferred(old, newOwner);
    }

    function setPaused(bool p) external onlyOwner {
        paused = p;
        if (p) emit Paused(msg.sender);
        else emit Unpaused(msg.sender);
    }

    function allowToken(address token, bool allowed) external onlyOwner {
        require(token != address(0), "Zero");
        require(_isContract(token), "Not contract");
        allowedTokens[token] = allowed;
        emit TokenAllowed(token, allowed);
    }


    // -----------------------------------------------------------------------
    // MERCHANT MANAGEMENT
    // -----------------------------------------------------------------------

    function registerMerchant(uint256 merchantId, address payoutAddress)
        external
        onlyOwner
    {
        require(merchantId != 0, "merchantId zero");
        require(payoutAddress != address(0), "Zero payout");

        if (merchantPayout[merchantId] == address(0)) {
            // New merchant
            if (merchantId > maxMerchantId) {
                maxMerchantId = merchantId;
            }
            merchantPayout[merchantId] = payoutAddress;
            emit MerchantRegistered(merchantId, payoutAddress);
        } else {
            // Updating payout address
            emit MerchantPayoutUpdated(merchantId, merchantPayout[merchantId], payoutAddress);
            merchantPayout[merchantId] = payoutAddress;
        }
    }

    // -----------------------------------------------------------------------
    // PAYMENT (TRX)
    // -----------------------------------------------------------------------

    function payTRX(
        uint256 merchantId,
        string calldata invoiceId,
        string calldata orderId
    ) external payable notPaused nonReentrant {

        _validateStrings(invoiceId, orderId);
        require(merchantPayout[merchantId] != address(0), "Not merchant");
        require(msg.value > 0, "Zero TRX");

        payerNonce[msg.sender]++;

        bytes32 h = _invoiceHash(merchantId, invoiceId, orderId);
        require(!invoicePaid[h], "Paid");

        invoicePaid[h] = true;
        merchantBalances[merchantId] += msg.value;
        totalMerchantTRXLocked += msg.value;

        emit PaymentReceived(merchantId, h, invoiceId, orderId, msg.sender, address(0), msg.value);
    }


    // -----------------------------------------------------------------------
    // PAYMENT (TRC20)
    // -----------------------------------------------------------------------

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

        bytes32 h = _invoiceHash(merchantId, invoiceId, orderId);
        require(!invoicePaid[h], "Paid");

        uint256 received = _transferExact(token, msg.sender, amount);

        invoicePaid[h] = true;
        merchantTokenBalances[merchantId][token] += received;
        totalMerchantTokenLocked[token] += received;

        _emitPaymentEvent(merchantId, h, invoiceId, orderId, msg.sender, token, received);
    }


    // -----------------------------------------------------------------------
    // WITHDRAWALS
    // -----------------------------------------------------------------------

    function withdrawTRX(uint256 merchantId, uint256 amount)
        external
        nonReentrant
        onlyMerchantPayout(merchantId)
    {
        uint256 bal = merchantBalances[merchantId];

        if (amount == 0) amount = bal;

        require(amount > 0, "Zero");
        require(bal >= amount, "Insufficient");

        merchantBalances[merchantId] = bal - amount;
        totalMerchantTRXLocked -= amount;

        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "Transfer fail");

        emit Withdraw(merchantId, msg.sender, address(0), amount);
    }

    function withdrawToken(address token, uint256 merchantId, uint256 amount)
        external
        nonReentrant
        onlyMerchantPayout(merchantId)
    {
        uint256 bal = merchantTokenBalances[merchantId][token];
        if (amount == 0) amount = bal;

        require(amount > 0, "Zero");
        require(bal >= amount, "Insufficient");

        merchantTokenBalances[merchantId][token] = bal - amount;
        totalMerchantTokenLocked[token] -= amount;
        _safeTransfer(token, msg.sender, amount);

        emit Withdraw(merchantId, msg.sender, token, amount);
    }


    // -----------------------------------------------------------------------
    // RESCUE (admin-only) — O(1) checks using totals
    // -----------------------------------------------------------------------

    function rescueTRX(address payable to, uint256 amount)
        external
        onlyOwner
        nonReentrant
    {
        require(to != address(0), "Zero");
        require(amount > 0, "Zero");

        uint256 bal = address(this).balance;
        require(bal >= totalMerchantTRXLocked, "Inconsistent balances");

        uint256 free = bal - totalMerchantTRXLocked;
        require(amount <= free, "Merchant TRX locked");

        (bool ok, ) = to.call{value: amount}("");
        require(ok, "Fail");

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


    // -----------------------------------------------------------------------
    // INTERNAL HELPERS
    // -----------------------------------------------------------------------

    function _validateStrings(string calldata invoiceId, string calldata orderId) internal pure {
        require(bytes(invoiceId).length > 0 && bytes(invoiceId).length <= MAX_STRING_LENGTH, "Bad invoiceId");
        require(bytes(orderId).length > 0 && bytes(orderId).length <= MAX_STRING_LENGTH, "Bad orderId");
    }

    function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        (bool ok, bytes memory data) =
            token.call(abi.encodeWithSelector(ITRC20.transferFrom.selector, from, to, amount));
        require(ok && (data.length == 0 || abi.decode(data, (bool))), "transferFrom fail");
    }

    function _safeTransfer(address token, address to, uint256 amount) internal {
        (bool ok, bytes memory data) =
            token.call(abi.encodeWithSelector(ITRC20.transfer.selector, to, amount));
        require(ok && (data.length == 0 || abi.decode(data, (bool))), "transfer fail");
    }

    function _transferExact(address token, address from, uint256 amount)
        internal
        returns (uint256 received)
    {
        uint256 beforeBal = ITRC20(token).balanceOf(address(this));
        _safeTransferFrom(token, from, address(this), amount);
        uint256 afterBal = ITRC20(token).balanceOf(address(this));
        received = afterBal - beforeBal;
        require(received == amount, "Fee token not allowed");
    }

    function _isRescuableToken(address token, uint256 amount) internal view returns (bool) {
        // Kept for parity but not used by rescueToken anymore.
        uint256 bal = ITRC20(token).balanceOf(address(this));
        uint256 locked = totalMerchantTokenLocked[token];
        require(bal >= locked, "Inconsistent");
        uint256 free = bal - locked;
        return amount <= free;
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
    
    /// @notice Internal helper to emit the PaymentReceived event (kept for parity)
    function _emitPaymentEvent(
        uint256 merchantId,
        bytes32 invoiceHash,
        string memory invoiceId,
        string memory orderId,
        address payer,
        address token,
        uint256 amount
    ) internal {
        emit PaymentReceived(
            merchantId,
            invoiceHash,
            invoiceId,
            orderId,
            payer,
            token,
            amount
        );
    }
    
    

    // -----------------------------------------------------------------------
    // RECEIVE / FALLBACK
    // -----------------------------------------------------------------------

    receive() external payable {
        revert("Use payTRX");
    }

    fallback() external payable {
        revert("Use payTRX");
    }
}
