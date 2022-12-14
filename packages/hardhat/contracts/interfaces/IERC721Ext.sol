// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Ext is IERC721 {
    function counter() external view returns (uint256);

    function mint(address to, uint256 tokenId) external;

    function safeMint(address to, uint256 tokenId) external;

    function burn(uint256 tokenId) external;
}
