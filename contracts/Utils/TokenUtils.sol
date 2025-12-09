// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

library TokenUtils {
    error TokenTransferError(string message);

    /**
     * @dev Pull TRC20 tokens from an address to this contract.
     *      Native token (TRX) should be handled via msg.value in the caller.
     * @param _token TRC20 token address (must not be address(0))
     * @param _from Address sending the tokens
     * @param _amount Amount of tokens to transfer
     */
    function pullTokens(
        address _token,
        address _from,
        uint256 _amount
    ) internal {
        if (_amount == 0) return;
        if (_token == address(0)) {
            revert TokenTransferError("Native token must use msg.value");
        }

        bool success = IERC20Upgradeable(_token).transferFrom(
            _from,
            address(this),
            _amount
        );
        if (!success) {
            revert TokenTransferError("Tokens: Couldn't transferFrom");
        }
    }

    /**
     * @dev Push native or TRC20 tokens from this contract to a receiving address.
     *      - address(0)  => native TRX
     *      - non-zero    => TRC20 token
     * @param _token Token address (address(0) for native)
     * @param _to Address receiving the tokens
     * @param _amount Amount of tokens to transfer
     */
    function pushTokens(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) return;

        if (_token == address(0)) {
            // Native TRX
            (bool success, ) = _to.call{value: _amount}("");
            if (!success) {
                revert TokenTransferError("Native: Couldn't transfer");
            }
        } else {
            // TRC20
            bool success = IERC20Upgradeable(_token).transfer(_to, _amount);
            if (!success) {
                revert TokenTransferError("Tokens: Couldn't transfer");
            }
        }
    }

    /**
     * @dev Pull ERC721 tokens from an address to this contract.
     * @param _token ERC721 token contract address
     * @param _from Address sending the tokens
     * @param _tokenId ID of the token to transfer
     */
    function pullNFT(
        IERC721Upgradeable _token,
        address _from,
        uint256 _tokenId
    ) internal {
        _token.safeTransferFrom(_from, address(this), _tokenId);
    }

    /**
     * @dev Push ERC721 tokens from this contract to a receiving address.
     * @param _token ERC721 token contract address
     * @param _to Address receiving the tokens
     * @param _tokenId ID of the token to transfer
     */
    function pushNFT(
        IERC721Upgradeable _token,
        address _to,
        uint256 _tokenId
    ) internal {
        _token.safeTransferFrom(address(this), _to, _tokenId);
    }
}
