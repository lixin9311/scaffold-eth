// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract BatchTransfer {
    function batchTransfer(
        address nftAddress,
        uint256[] calldata tokenIds,
        address recipient
    ) public virtual {
        for (uint8 i = 0; i < tokenIds.length; ++i) {
            IERC721(nftAddress).transferFrom(msg.sender, recipient, tokenIds[i]);
        }
    }

    function batchSafeTransfer(
        address nftAddress,
        uint256[] calldata tokenIds,
        address recipient
    ) public virtual {
        for (uint8 i = 0; i < tokenIds.length; ++i) {
            IERC721(nftAddress).safeTransferFrom(msg.sender, recipient, tokenIds[i]);
        }
    }
}
