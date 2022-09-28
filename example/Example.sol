// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.9 < 0.9.0;

import "ERC721Ash/contracts/ERC721Ash.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Example is Ownable, ERC721Ash {
    address devAddr;
    constructor() ERC721A("Example", "EXP") { devAddr = msg.sender; }

    function mint(uint256 quantity) external payable {
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(msg.sender, quantity);
    }

    function purchaseTicket(uint256 quantity) external payable {
        require(quantity > 0, "Cannot buy 0 tickets");
        require(_ticketPrice > 0, "Ticket price is not set");
        require(_ticketPrice * quantity <= msg.value, "Not enough Ether to buy tickets");

        (bool purchaseSuccess, ) = devAddr.call{value: msg.value}("");
        require(purchaseSuccess, "Purchase failed");
        _purchaseTicket(quantity);
    }

    function setupTicketPrice(uint256 ticketPriceWei) public onlyOwner {
        _ticketPrice = ticketPriceWei;
    }
}