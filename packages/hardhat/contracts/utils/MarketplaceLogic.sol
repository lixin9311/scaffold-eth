// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "../interfaces/IMarketplace.sol";
import "./MarketplaceStorage.sol";

contract MarketplaceLogic is EIP712Upgradeable, IMarketplace, MarketplaceStorage {
    bytes32 private constant TYPEHASH =
        keccak256(
            "Order(address nftAddress,uint256 tokenId,uint256 nonce,uint8 auctionType,uint256[] tokenIds,address seller,address buyer,uint128 startingPrice,uint128 endingPrice,uint128 startedAt,uint128 endedAt)"
        );

    uint8 private constant MAX_TOKEN_QUANTITY = 100;
    uint128 private constant END_DELAY = 60;
    uint128 private constant DUTCH_INTERVAL = 300;

    address public foundation;
    uint256 public foundationCut;

    address public creator;
    uint256 public creatorCut;

    function __MarketplaceLogic_init(
        string memory name,
        string memory version,
        address _foundation,
        uint256 _foundationCut,
        address _creator,
        uint256 _creatorCut
    ) internal onlyInitializing {
        require(_foundation != address(0), "Marketplace: cannot set 0 as foundation address");
        require(_foundationCut <= 10000, "Marketplace: invalid foundation cut, must <= 10000");
        require(_creator != address(0), "Marketplace: cannot set 0 as creator address");
        require(_creatorCut <= 10000, "Marketplace: invalid creator cut, must <= 10000");
        __EIP712_init_unchained(name, version);
        foundation = _foundation;
        foundationCut = _foundationCut;
        creator = _creator;
        creatorCut = _creatorCut;
    }

    // erc721
    function _owns(
        address nftAddress,
        uint256 tokenId,
        address claimant
    ) internal view virtual returns (bool) {
        return (IERC721Upgradeable(nftAddress).ownerOf(tokenId) == claimant);
    }

    // foundation
    function _computeFoundationCut(uint256 price) internal view virtual returns (uint256) {
        return (price * foundationCut) / 10000;
    }

    function _updateFoundation(address _foundation) internal virtual {
        foundation = _foundation;
    }

    function _updateFoundationCut(uint256 _foundationCut) internal virtual {
        foundationCut = _foundationCut;
    }

    // creator
    function _computeCreatorCut(uint256 price) internal view virtual returns (uint256) {
        return (price * creatorCut) / 10000;
    }

    function _updateCreator(address _creator) internal virtual {
        creator = _creator;
    }

    function _updateCreatorCut(uint256 _creatorCut) internal virtual {
        creatorCut = _creatorCut;
    }

    // order utils
    function _isOnOrder(Order calldata order) internal view virtual returns (bool) {
        if (order.startedAt > block.timestamp) return false;
        return _isValidOrder(order);
    }

    function _isValidOrder(Order calldata order) internal view virtual returns (bool) {
        require(order.tokenIds.length <= MAX_TOKEN_QUANTITY, "Marketplace: token quantity too much");
        require(order.tokenId == order.tokenIds[0], "Marketplace: invalid tokenIds, first must be order.tokenId");
        for (uint8 i = 1; i < order.tokenIds.length; ++i) {
            require(order.tokenIds[i] > order.tokenIds[i - 1], "Marketplace: invalid tokenIds, must be increasing");
        }
        if (order.endedAt < block.timestamp + END_DELAY) return false;
        uint256 nonce = _getNonce(order.nftAddress, order.tokenIds[0]);
        if (nonce != order.nonce) return false;
        bytes32 hash = _hashOrder(order);
        if (_isFinalized(hash)) return false;
        bool valid = true;
        for (uint8 i = 1; i < order.tokenIds.length; ++i) {
            if (!_owns(order.nftAddress, order.tokenIds[i], order.seller)) valid = false;
        }
        return valid;
    }

    function _isValidBuyer(Order calldata order) internal view virtual returns (bool) {
        if (order.buyer == address(0)) return true;
        if (order.buyer == msg.sender) return true;
        return false;
    }

    function _getCurrentPrice(Order calldata order) internal view virtual returns (uint256) {
        (uint256 currentPrice, ) = _allowedMinimumPrice(order);
        return currentPrice;
    }

    function _allowedMinimumPrice(Order memory order) internal view virtual returns (uint256, uint256) {
        (uint128 startingPrice, uint128 endingPrice, uint128 startedAt, uint128 endedAt) = (order.startingPrice, order.endingPrice, order.startedAt, order.endedAt);
        // auctionType 0: Fixed price
        if (order.auctionType == 0) {
            return (startingPrice, startingPrice);
        }
        // auctionType 1: Dutch auction
        if (order.auctionType == 1) {
            if (startingPrice < endingPrice) {
                // price increase
                uint128 intervals = (endedAt - startedAt) / DUTCH_INTERVAL;
                uint128 currentInterval = (uint128(block.timestamp) - startedAt) / DUTCH_INTERVAL + 1;
                uint128 unit = (endingPrice - startingPrice) / intervals;
                uint256 currentPrice = startingPrice + currentInterval * unit;
                return (currentPrice, currentPrice - unit);
            } else {
                // price dicrease
                uint128 intervals = (endedAt - startedAt) / DUTCH_INTERVAL;
                uint128 currentInterval = (uint128(block.timestamp) - startedAt) / DUTCH_INTERVAL;
                uint128 unit = (startingPrice - endingPrice) / intervals;
                uint256 currentPrice = startingPrice - currentInterval * unit;
                return (currentPrice, currentPrice);
            }
        }
        return (startingPrice, startingPrice);
    }

    // utils
    function _hashOrder(Order calldata order) internal pure virtual returns (bytes32 hash) {
        require(order.tokenIds.length <= MAX_TOKEN_QUANTITY, "Marketplace: token quantity too much");
        require(order.tokenId == order.tokenIds[0], "Marketplace: invalid tokenIds, first must be order.tokenId");
        for (uint8 i = 1; i < order.tokenIds.length; ++i) {
            require(order.tokenIds[i] > order.tokenIds[i - 1], "Marketplace: invalid tokenIds, must be increasing");
        }

        return
            keccak256(
                abi.encode(
                    TYPEHASH,
                    order.nftAddress,
                    order.tokenId,
                    order.nonce,
                    order.auctionType,
                    keccak256(abi.encodePacked(order.tokenIds)),
                    order.seller,
                    order.buyer,
                    order.startingPrice,
                    order.endingPrice,
                    order.startedAt,
                    order.endedAt
                )
            );
    }

    function _validateOrderSig(Order calldata order, bytes memory signature) internal view virtual returns (bool) {
        bytes32 digest = _hashTypedDataV4(_hashOrder(order));
        if (ECDSAUpgradeable.recover(digest, signature) == order.seller) {
            return true;
        }
        return false;
    }

    function _finalizeOrder(Order calldata order) internal virtual {
        bytes32 hash = _hashOrder(order);
        _finalize(hash);
        _nonceInc(order.nftAddress, order.tokenId);
    }

    function _bid(Order calldata order) internal virtual returns (uint256) {
        (uint256 currentPrice0, uint256 currentPrice1) = _allowedMinimumPrice(order);
        uint256 bidAmount = msg.value;
        require(bidAmount >= currentPrice1, "Marketplace: bid amount is not enough");

        address seller = order.seller;
        address buyer = msg.sender;
        uint256 price = currentPrice0;
        if (bidAmount < currentPrice0) price = currentPrice1;

        _finalizeOrder(order);
        if (price > 0) {
            uint256 foundationValue = _computeFoundationCut(price);
            uint256 creatorValue = _computeCreatorCut(price);
            uint256 sellerValue = price - foundationValue - creatorValue;
            payable(seller).transfer(sellerValue);
            payable(foundation).transfer(foundationValue);
            payable(creator).transfer(creatorValue);
        }
        if (bidAmount > price) {
            uint256 returnValue = bidAmount - price;
            payable(buyer).transfer(returnValue);
        }

        for (uint8 i = 0; i < order.tokenIds.length; ++i) {
            IERC721Upgradeable(order.nftAddress).safeTransferFrom(order.seller, buyer, order.tokenIds[i]);
        }
        return price;
    }
}
