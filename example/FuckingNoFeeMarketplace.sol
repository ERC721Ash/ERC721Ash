// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.9 < 0.9.0;

import "./ERC721Ash.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error AddressNotAllowlistVerified();

contract FuckingNoFeeMarketplace is Ownable, ERC721Ash {
    uint256 public immutable maxPerAddressDuringMint;
    uint256 public immutable collectionSize;
    uint256 public immutable amountForDevs;

    struct SaleConfig {
        uint32 publicSaleStartTime;
        uint64 publicPriceWei;
    }

    SaleConfig public saleConfig;

    // metadata URI
    string private _baseTokenURI;
    address devAddr;

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        uint256 amountForDevs_
    ) ERC721Ash("Fucking No-Fee Marketplace", "FNM") {
        require(
            maxBatchSize_ < collectionSize_,
            "MaxBarchSize should be smaller than collectionSize"
        );
        devAddr = msg.sender;
        maxPerAddressDuringMint = maxBatchSize_;
        collectionSize = collectionSize_;
        amountForDevs = amountForDevs_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function devMint(uint256 quantity) external onlyOwner {
        require(
            quantity <= amountForDevs,
            "Too many already minted before dev mint"
        );
        require(
            totalSupply() + quantity <= collectionSize,
            "Reached max supply"
        );
        _safeMint(msg.sender, quantity);
    }

    // Public Mint
    // *****************************************************************************
    // Public Functions
    function donateAndMint(uint256 quantity)
    external
    payable
    callerIsUser
    {
        require(isPublicSaleOn(), "Public sale has not begun yet");
        require(
            totalSupply() + quantity <= collectionSize,
            "Reached max supply"
        );
        require(
            numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
            "Reached max quantity that one wallet can mint"
        );
        uint256 priceWei = quantity * saleConfig.publicPriceWei;

        _safeMint(msg.sender, quantity);
        refundIfOver(priceWei);
    }

    function justDonateToDev() external payable {
        (bool donateSuccess, ) = devAddr.call{value: msg.value}("");
        require(donateSuccess, "Donate failed");
    }

    function isPublicSaleOn() public view returns(bool) {
        require(
            saleConfig.publicSaleStartTime != 0,
            "Public Sale Time is TBD."
        );

        return block.timestamp >= saleConfig.publicSaleStartTime;
    }

    // Owner Controls

    // Public Views
    // *****************************************************************************
    function numberMinted(address minter) public view returns(uint256) {
        return _numberMinted(minter);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseTokenURI;
        return string(abi.encodePacked(baseURI, "uri.json"));
        // return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    // Contract Controls (onlyOwner)
    // *****************************************************************************
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawETH() external onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance } ("");
        require(success, "Transfer failed.");
    }

    function setupNonAuctionSaleInfo(
        uint64 publicPriceWei,
        uint32 publicSaleStartTime
    ) public onlyOwner {
        saleConfig = SaleConfig(
            publicSaleStartTime,
            publicPriceWei
        );
    }

    // Internal Functions
    // *****************************************************************************

    function refundIfOver(uint256 price) internal {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function _baseURI() internal view virtual override returns(string memory) {
        return _baseTokenURI;
    }
}
