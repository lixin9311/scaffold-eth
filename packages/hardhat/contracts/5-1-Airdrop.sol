// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./interfaces/IERC721Ext.sol";
import "./utils/Counters.sol";

struct BatchBlox {
    address recipient;
    uint256 tokenId;
}

contract Airdrop is AccessControlEnumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public nftAddress;

    constructor(address _nftAddress) {
        require(_nftAddress != address(0), "Airdrop: invalid nft address");

        nftAddress = _nftAddress;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
    }

    function batchMint(BatchBlox[] calldata bloxes) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "Airdrop: not minter");

        for (uint8 i = 0; i < bloxes.length; ++i) {
            IERC721Ext(nftAddress).mint(bloxes[i].recipient, bloxes[i].tokenId);
        }
    }

    function batchSafeMint(BatchBlox[] calldata bloxes) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "Airdrop: not minter");

        for (uint8 i = 0; i < bloxes.length; ++i) {
            IERC721Ext(nftAddress).safeMint(bloxes[i].recipient, bloxes[i].tokenId);
        }
    }

    function resetNftAddress(address _nftAddress) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Airdrop: not admin");
        require(_nftAddress != address(0), "Airdrop: invalid nft address");

        nftAddress = _nftAddress;
    }
}
