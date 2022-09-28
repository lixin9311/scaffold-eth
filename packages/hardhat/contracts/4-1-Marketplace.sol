// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./utils/MarketplaceLogic.sol";

// marketplace offline version
contract Marketplace is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, MarketplaceLogic {
    function initialize(
        string memory name,
        string memory version,
        address _foundation,
        uint256 _foundationCut,
        address _creator,
        uint256 _creatorCut
    ) public virtual initializer {
        __MarketplaceLogic_init(name, version, _foundation, _foundationCut, _creator, _creatorCut);
        __Pausable_init_unchained();
        __Ownable_init_unchained();
    }

    // order
    function getCurrentPrice(Order calldata order) external view virtual returns (uint256) {
        require(_isOnOrder(order), "Marketplace: order status is invalid");
        return _getCurrentPrice(order);
    }

    function getNonce(address nftAddress, uint256 tokenId) external view virtual returns (uint256 nonce) {
        return _getNonce(nftAddress, tokenId);
    }

    function cancelOrder(Order calldata order) external virtual {
        require(_isValidOrder(order), "Marketplace: order status is invalid");
        address owner = _msgSender();
        for (uint8 i = 0; i < order.tokenIds.length; ++i) {
            require(_owns(order.nftAddress, order.tokenIds[i], owner), "Marketplace: must be NFT owner to cancel order");
        }
        _finalizeOrder(order);
        emit OrderCanceled(order.nftAddress, order.tokenId, order.nonce, order.auctionType, order.tokenIds, order.seller);
    }

    function bid(Order calldata order, bytes calldata signature) external payable whenNotPaused {
        require(_isOnOrder(order), "Marketplace: order status is invalid");
        require(_validateOrderSig(order, signature), "Marketplace: invalid order signature");
        address buyer = _msgSender();
        require(_isValidBuyer(order), "Marketplace: you are not allowed to bid this order");
        for (uint8 i = 0; i < order.tokenIds.length; ++i) {
            require(!_owns(order.nftAddress, order.tokenIds[i], buyer), "Marketplace: cannot bid nft to yourself");
        }
        uint256 price = _bid(order);
        emit OrderDone(order.nftAddress, order.tokenId, order.nonce, order.auctionType, order.tokenIds, order.seller, buyer, price);
    }

    // foundation
    function updateFoundation(address _foundation) external virtual onlyOwner {
        require(_foundation != address(0), "Marketplace: cannot set 0 as foundation address");
        _updateFoundation(_foundation);
    }

    function updateFoundationCut(uint256 _foundationCut) external virtual onlyOwner {
        require(_foundationCut <= 10000, "Marketplace: invalid foundation cut, must <= 10000");
        _updateFoundationCut(_foundationCut);
    }

    // creator
    function updateCreator(address _creator) external virtual onlyOwner {
        require(_creator != address(0), "Marketplace: cannot set 0 as creator address");
        _updateCreator(_creator);
    }

    function updateCreatorCut(uint256 _creatorCut) external virtual onlyOwner {
        require(_creatorCut <= 10000, "Marketplace: invalid creator cut, must <= 10000");
        _updateCreatorCut(_creatorCut);
    }

    // admin
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
