// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/// @title NFT Marketplace
/// @author Parthasarathy
/// @notice You can use this contract for buying and selling NFTs
contract MyNFTMarket is Ownable{

using Counters for Counters.Counter;
Counters.Counter private _NFTCount;
uint public listingFee = 0.01 ether;


mapping(uint256 => MarketNFT) private MarketItemID;
mapping(address => uint ) public balances;

struct MarketNFT {
      uint256 id;
      address NFTcontract;
      uint256 tokenId;
      address payable seller;
      uint256 price;
      bool sold;
    }

/// @notice  emited when a NFT is added to Marketplace
/// @dev Emitted at AddNFTToMarket function
event MarketItemCreated (
     uint256 id,
      address NFTcontract,
      uint256 tokenId,
      address payable seller,
      uint256 price,
      bool sold
    );

constructor(){}

/// @notice Updates the listing price of the marketplace
function updateListingPrice(uint _listingPrice) public {
      require(owner() == msg.sender, "Only marketplace owner can update listing price.");
      listingFee = _listingPrice;
    }

/// @notice Adds user's NFT to the marketplace
/// Seller -> NFT Marketplace
function AddNFTToMarket(address Contract, uint tokenID, uint price) public payable {
    require(price > 0, "Price should be more than 0 wei");
    require(msg.value == listingFee, "Send the exact listing fee");
    //require(IERC721(Contract).getApproved(tokenID) == address(this), "NFT must be approved to market");
    IERC721(Contract).transferFrom(msg.sender,address(this),tokenID);

    _NFTCount.increment();
    uint ID = _NFTCount.current();

    MarketItemID[tokenID] = MarketNFT(
        ID,
        Contract,
        tokenID,
        payable(msg.sender),
        price,
        false
    );

    emit MarketItemCreated(
        ID,
        Contract,
        tokenID,
        payable(msg.sender),
        price,
        false
    );

}

/// @dev Transfers(Sell) the NFT to the buyer and recieves the fixed price.
///  NFT Marketplace -> Buyer
function BuyNFT(uint ID) public payable{
    require(MarketItemID[ID].sold == true, "The NFT is already sold");
    uint price = MarketItemID[ID].price;
    address seller = MarketItemID[ID].seller;
    address Contract = MarketItemID[ID].NFTcontract;
    uint tokenID = MarketItemID[ID].tokenId;
    require(msg.value == price, "Please send the exact amount");
    MarketItemID[ID].seller = payable(msg.sender);
    MarketItemID[ID].sold = true;
    IERC721(Contract).transferFrom(address(this),msg.sender,tokenID);
    uint sellerBalance = balances[seller];
    balances[seller] = msg.value + sellerBalance;
    _NFTCount.decrement();
}

/// @notice Function to withdraw ETH for User
/// @dev The user can withdraw the ETH from selling thier NFTs
function UserWithdrawETH() public payable{
    require(balances[msg.sender] > 0, "Balance should be more than 0");
    (bool success,) = msg.sender.call{value: balances[msg.sender]}("");
}

/// @notice Function to view the balance of the contract
function contractBalance() public view returns(uint){
    return address(this).balance;
}

/// @notice Function to view the NFTs owned by the user
/// @dev Returns array of stucts
function MyNFTs() public view returns(MarketNFT[] memory){
    uint totalItemCount = _NFTCount.current();
    uint itemCount = 0;
    uint currentIndex = 0;
    for (uint i = 0; i < totalItemCount; i++) {
        if (MarketItemID[i + 1].seller == msg.sender) {
          itemCount += 1;
        }
      }
      MarketNFT[] memory items = new MarketNFT[](itemCount);
      for (uint i = 0; i < totalItemCount; i++) {
        if (MarketItemID[i + 1].seller == msg.sender) {
          uint currentId = i + 1;
          MarketNFT storage currentItem = MarketItemID[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
}
/// @notice Function to resell the NFTs bought in this marketplace
function resellNFT(uint TokenID, uint price) public payable{
    require(MarketItemID[TokenID].seller == msg.sender, "Only owner of NFT can access this function");
    require(msg.value == listingFee, "Send the exact listing fee");
    MarketItemID[TokenID].sold = false;
    MarketItemID[TokenID].price = price;
    address Contract = MarketItemID[TokenID].NFTcontract;
    uint tokenId = MarketItemID[TokenID]. tokenId;
    require(IERC721(Contract).getApproved(tokenId) == address(this), "NFT must be approved to market");
    IERC721(Contract).transferFrom(msg.sender,address(this),tokenId);
    _NFTCount.increment();
}

}