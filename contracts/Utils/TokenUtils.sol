// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

library TokenUtils {

    error TokenTransferError(string message);

    /**
     * @dev Pull tokens from an address to this contract.
     * @param _token Token to transfer
     * @param _from Address sending the tokens
     * @param _amount Amount of tokens to transfer
     */
    function pullTokens(
        IERC20Upgradeable _token,
        address _from,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            bool success = _token.transferFrom(_from, address(this), _amount);
            if(!success){
                revert TokenTransferError("Tokens: Couldn't transfer");
            }
        }
    }

    /**
     * @dev Push tokens from this contract to a receiving address.
     * @param _token Token to transfer
     * @param _to Address receiving the tokens
     * @param _amount Amount of tokens to transfer
     */
    function pushTokens(
        IERC20Upgradeable _token,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            bool success = _token.transfer(_to, _amount);
            if(!success){
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
