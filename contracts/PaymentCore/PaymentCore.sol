// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "../MerchantRegistry/MerchantStorage.sol";

/**
 * @title PaymentCore
 * @notice Payment logic (Upgradeable)
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

    modifier onlyMerchantPayout(uint256 _merchantId) {
        require(msg.sender == merchantPayout_[_merchantId], "Not merchant payout");
        _;
    }

    // -------------------------
    // ADMIN
    // -------------------------
    function allowToken(address _token, bool _allowed)
        external
        onlyOwner
    {
        require(_token != address(0), "Zero");
        require(_isContract(_token), "Not contract");

        allowedTokens_[_token] = _allowed;
        emit TokenAllowed(_token, _allowed);
    }

    // -------------------------
    // PAYMENTS (TRX)
    // -------------------------
    function payTRX(
        uint256 _merchantId,
        string calldata _invoiceId,
        string calldata _orderId
    )
        external
        payable
        notPaused
        nonReentrant
    {
        _validateStrings(_invoiceId, _orderId);
        require(merchantPayout_[_merchantId] != address(0), "Not merchant");
        require(msg.value > 0, "Zero TRX");

        payerNonce_[msg.sender]++;

        bytes32 _hash = _invoiceHash(_merchantId, _invoiceId, _orderId);
        require(!invoicePaid_[_hash], "Paid");

        invoicePaid_[_hash] = true;
        merchantBalances_[_merchantId] += msg.value;
        totalMerchantTRXLocked_ += msg.value;

        emit PaymentReceived(
            _merchantId,
            _hash,
            _invoiceId,
            _orderId,
            msg.sender,
            address(0),
            msg.value
        );
    }

    // -------------------------
    // PAYMENTS (TRC20)
    // -------------------------
    function payToken(
        address _token,
        uint256 _merchantId,
        string calldata _invoiceId,
        string calldata _orderId,
        uint256 _amount
    )
        external
        notPaused
        nonReentrant
    {
        _validateStrings(_invoiceId, _orderId);
        require(allowedTokens_[_token], "Token NA");
        require(merchantPayout_[_merchantId] != address(0), "Not merchant");
        require(_amount > 0, "Zero amount");

        payerNonce_[msg.sender]++;

        bytes32 _hash = _invoiceHash(_merchantId, _invoiceId, _orderId);
        require(!invoicePaid_[_hash], "Paid");

        uint256 _received = _transferExact(_token, msg.sender, _amount);

        invoicePaid_[_hash] = true;
        merchantTokenBalances_[_merchantId][_token] += _received;
        totalMerchantTokenLocked_[_token] += _received;

        emit PaymentReceived(
            _merchantId,
            _hash,
            _invoiceId,
            _orderId,
            msg.sender,
            _token,
            _received
        );
    }

    // -------------------------
    // WITHDRAWALS
    // -------------------------
    function withdrawTRX(uint256 _merchantId, uint256 _amount)
        external
        nonReentrant
        onlyMerchantPayout(_merchantId)
    {
        uint256 _bal = merchantBalances_[_merchantId];

        if (_amount == 0) {
            _amount = _bal;
        }

        require(_amount > 0, "Zero");
        require(_bal >= _amount, "Insufficient");

        merchantBalances_[_merchantId] = _bal - _amount;
        totalMerchantTRXLocked_ -= _amount;

        (bool _ok, ) = msg.sender.call{value: _amount}("");
        require(_ok, "Transfer fail");

        emit Withdraw(_merchantId, msg.sender, address(0), _amount);
    }

    function withdrawToken(
        address _token,
        uint256 _merchantId,
        uint256 _amount
    )
        external
        nonReentrant
        onlyMerchantPayout(_merchantId)
    {
        uint256 _bal = merchantTokenBalances_[_merchantId][_token];

        if (_amount == 0) {
            _amount = _bal;
        }

        require(_amount > 0, "Zero");
        require(_bal >= _amount, "Insufficient");

        merchantTokenBalances_[_merchantId][_token] = _bal - _amount;
        totalMerchantTokenLocked_[_token] -= _amount;

        _safeTransfer(_token, msg.sender, _amount);

        emit Withdraw(_merchantId, msg.sender, _token, _amount);
    }

    // -------------------------
    // RESCUE
    // -------------------------
    function rescueTRX(address payable _to, uint256 _amount)
        external
        onlyOwner
        nonReentrant
    {
        require(_to != address(0), "Zero");
        require(_amount > 0, "Zero");

        uint256 _bal = address(this).balance;
        require(_bal >= totalMerchantTRXLocked_, "Inconsistent balances");

        uint256 _free = _bal - totalMerchantTRXLocked_;
        require(_amount <= _free, "Merchant TRX locked");

        (bool _ok, ) = _to.call{value: _amount}("");
        require(_ok, "Fail");

        emit RescueTRX(_to, _amount);
    }

    function rescueToken(address _token, address _to, uint256 _amount)
        external
        onlyOwner
        nonReentrant
    {
        require(_token != address(0), "Zero");
        require(_to != address(0), "Zero");
        require(_amount > 0, "Zero");

        uint256 _bal = ITRC20(_token).balanceOf(address(this));
        uint256 _locked = totalMerchantTokenLocked_[_token];
        require(_bal >= _locked, "Inconsistent");

        uint256 _free = _bal - _locked;
        require(_amount <= _free, "Locked to merchants");

        _safeTransfer(_token, _to, _amount);

        emit RescueToken(_token, _to, _amount);
    }

    // -------------------------
    // HELPERS
    // -------------------------
    function _validateStrings(
        string calldata _invoiceId,
        string calldata _orderId
    ) internal pure {
        require(
            bytes(_invoiceId).length > 0 &&
            bytes(_invoiceId).length <= MAX_STRING_LENGTH,
            "Bad invoiceId"
        );
        require(
            bytes(_orderId).length > 0 &&
            bytes(_orderId).length <= MAX_STRING_LENGTH,
            "Bad orderId"
        );
    }

    function _safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        (bool _ok, bytes memory _data) = _token.call(
            abi.encodeWithSelector(
                ITRC20.transferFrom.selector,
                _from,
                _to,
                _amount
            )
        );
        require(_ok && (_data.length == 0 || abi.decode(_data, (bool))), "transferFrom fail");
    }

    function _safeTransfer(address _token, address _to, uint256 _amount)
        internal
    {
        (bool _ok, bytes memory _data) = _token.call(
            abi.encodeWithSelector(
                ITRC20.transfer.selector,
                _to,
                _amount
            )
        );
        require(_ok && (_data.length == 0 || abi.decode(_data, (bool))), "transfer fail");
    }

    function _transferExact(address _token, address _from, uint256 _amount)
        internal
        returns (uint256 _received)
    {
        uint256 _before = ITRC20(_token).balanceOf(address(this));
        _safeTransferFrom(_token, _from, address(this), _amount);
        uint256 _after = ITRC20(_token).balanceOf(address(this));

        _received = _after - _before;
        require(_received == _amount, "Fee token not allowed");
    }

    function _invoiceHash(
        uint256 _merchantId,
        string memory _invoiceId,
        string memory _orderId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(_merchantId, _invoiceId, _orderId));
    }

    function _isContract(address _a) internal view returns (bool) {
        return _a.code.length > 0;
    }

}