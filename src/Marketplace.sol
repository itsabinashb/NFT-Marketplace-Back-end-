//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/utils/Counters.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

contract Marketplace is ERC721, IERC721Receiver {
    using Counters for Counters.Counter;
    Counters.Counter public tokenId;
    Counters.Counter public soldTokenId;
    string public baseUri;
    uint256 listPrice = 0.01 ether;
    address public owner;

    struct Item {
        uint256 _tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => Item) public IdToItem;
    mapping(uint256 => bool) public readyToSell;
    mapping(uint256 => bool) public sold;

    constructor(string memory _baseUri) ERC721("GOOD_TOKEN", "GT") {
        baseUri = _baseUri;
        owner = msg.sender;
    }

    /**
     * @dev token creator function
     */
    function mint() public payable returns (uint256) {
        require(msg.value == listPrice, "Pay 0.01 ether to create a token");
        tokenId.increment();
        uint256 currentTokenId = tokenId.current();
        _safeMint(msg.sender, currentTokenId);

        return currentTokenId;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 _tokenId,
        bytes calldata data
    ) external view override returns (bytes4) {
        require(msg.sender == address(this));

        return this.onERC721Received.selector;
    }

    /**
     * @dev set the token in marketplace contract
     * @param _tokenId tokenId of token which is going to be submitted in contract
     * @param _price  price of the token set by caller
     */
    function createMarketItem(uint256 _tokenId, uint256 _price) public {
        require(
            IdToItem[_tokenId].owner == msg.sender,
            "You are not the owner of this token"
        );
        require(_tokenId > 0, "Invalid tokenId");
        safeTransferFrom(msg.sender, address(this), _tokenId);
        IdToItem[_tokenId] = Item(
            _tokenId,
            payable(msg.sender),
            payable(address(this)),
            _price,
            false
        );
        readyToSell[_tokenId] = true;
    }

    /**
     * @notice function for buying token by anyone
     * @param _tokenId  tokenId of token
     */
    function buyItem(uint256 _tokenId) public payable {
        require(readyToSell[_tokenId], "tokenId is not ready to sell yet");
        require(msg.value == IdToItem[_tokenId].price);
        safeTransferFrom(address(this), msg.sender, _tokenId);
        (bool sent, ) = owner.call{value: listPrice}("");
        require(sent);
        (bool success, ) = IdToItem[_tokenId].seller.call{value: msg.value}("");
        require(success);
        sold[_tokenId] = true;
        IdToItem[_tokenId].sold = true;
        readyToSell[_tokenId] = false; // tracking unsold tokens
        soldTokenId.increment();
    }

    function getUnsoldItems() public view returns (Item[] memory) {
        uint256 totalTokenNumber = tokenId.current();

        uint256 arrayIndex = 0;
        Item[] memory items;
        for (uint256 i = 1; i <= totalTokenNumber; i++) {
            if (readyToSell[i] == true) {
                require(IdToItem[i].owner == address(this));
                Item storage currentId = IdToItem[i];
                items[arrayIndex] = currentId;
                arrayIndex++;
            }
        }

        return items;
    }

    function getYourItems() public view returns (Item[] memory) {
        uint256 totalTokenNumber = tokenId.current();

        uint256 arrayIndex = 0;
        Item[] memory yourItems;
        for (uint i = 1; i < totalTokenNumber; i++) {
            if (IdToItem[i].owner == msg.sender) {
                Item storage items = IdToItem[i];
                yourItems[arrayIndex] = items;
                arrayIndex++;
            }
        }
        return yourItems;
    }
}
