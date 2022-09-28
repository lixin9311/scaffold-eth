// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MarketplaceStorage {
    mapping(address => mapping(uint256 => uint256)) private _nonces; // nftAddress => (tokenId => nonce)
    mapping(bytes32 => bool) private _finalized; // offline marketplace

    function _getNonce(address nftAddress, uint256 tokenId) internal view virtual returns (uint256) {
        return _nonces[nftAddress][tokenId];
    }

    function _nonceInc(address nftAddress, uint256 tokenId) internal virtual returns (uint256) {
        uint256 nonce = _nonces[nftAddress][tokenId];
        _nonces[nftAddress][tokenId] = nonce + 1;
        return nonce;
    }

    function _isFinalized(bytes32 hash) internal view virtual returns (bool) {
        return _finalized[hash];
    }

    function _finalize(bytes32 hash) internal virtual {
        _finalized[hash] = true;
    }
}
