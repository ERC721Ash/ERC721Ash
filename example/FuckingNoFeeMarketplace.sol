// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.9 < 0.9.0;

import "contract/ERC721Ash.sol";

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

    mapping(address => uint256) public donateReceipts;

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
        donateReceipts[msg.sender] = 0;
        _safeMint(msg.sender, quantity);
    }

    // Public Mint
    // *****************************************************************************
    // Public Functions
    // function donateToDev(uint256 quantity) // Multiple NFT are allowed
    function donateToDev() // Multiple NFT are not allowed
    external payable callerIsUser
    {
        uint256 quantity = 1; // If multiple NFT are allowed, this line should be removed

        (bool donateSuccess, ) = devAddr.call{value: msg.value}("");
        require(donateSuccess, "Donate failed");
        
        if (balanceOf(msg.sender) == 0) {
            require(isPublicSaleOn(), "Public sale has not begun yet");
            require(
                totalSupply() + quantity <= collectionSize,
                "Reached max supply"
            );
            require(
                numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
                "Reached max quantity that one wallet can mint"
            ); _safeMint(msg.sender, quantity);
            donateReceipts[msg.sender] = msg.value;
        } else {
            donateReceipts[msg.sender] += msg.value;
        }
    }

    function purchaseTicket(uint256 quantity) external payable callerIsUser {
        require(quantity > 0, "Cannot buy 0 tickets");
        require(_ticketPrice > 0, "Ticket price is not set");
        require(_ticketPrice * quantity <= msg.value, "Not enough Ether to buy tickets");

        (bool purchaseSuccess, ) = devAddr.call{value: msg.value}("");
        require(purchaseSuccess, "Purchase failed");
        _purchaseTicket(quantity);
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
        return string(abi.encodePacked(baseURI, tokenLevel(ownerOf(tokenId)), ".json"));
    }

    function tokenLevel(address owner) public view virtual returns (string memory) {
        string memory level;
        if (donateReceipts[owner] >= 1000000000000000000) {
            level = "gold";
        } else if (donateReceipts[owner] >= 100000000000000000) {
            level = "silver";
        } else if (donateReceipts[owner] >= 10000000000000000) {
            level = "copper";
        } else {
            level = "green";
        } return level;
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

    function setupTicketPrice(uint256 ticketPriceWei) public onlyOwner {
        _ticketPrice = ticketPriceWei;
    }

    function setupDevAddress(address devAddr_) public onlyOwner {
        devAddr = devAddr_;
    }

    // Internal Functions
    // *****************************************************************************

    function _baseURI() internal view virtual override returns(string memory) {
        return _baseTokenURI;
    }
}
