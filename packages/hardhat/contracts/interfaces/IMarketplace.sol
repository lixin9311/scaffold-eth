// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMarketplace {
    // auctionType 0: Fixed price
    // auctionType 1: Dutch auction
    struct Order {
        address nftAddress;
        uint256 tokenId;
        uint256 nonce;
        uint8 auctionType;
        uint256[] tokenIds;
        address seller;
        address buyer;
        uint128 startingPrice; // ETH price (in wei)
        uint128 endingPrice; // ETH price (in wei)
        uint128 startedAt;
        uint128 endedAt;
    }

    event OrderDone(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 nonce,
        uint8 auctionType,
        uint256[] tokenIds,
        address seller,
        address buyer,
        uint256 price
    );
    event OrderCanceled(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 nonce,
        uint8 auctionType,
        uint256[] tokenIds,
        address seller
    );
}
