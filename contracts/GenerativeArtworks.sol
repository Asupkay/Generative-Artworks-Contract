pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

contract GenerativeArtworks is ERC721Enumerable {
    struct Piece {
        string name;
        string description;
        string license;
        uint256 currentPrints;
        uint256 maxPrints;
        string script;
        bool active;
        bool locked;
        bool paused;
    }

    uint256 constant ONE_MILLION = 1_000_000;
    mapping(uint256 => Piece) pieces;

    mapping(uint256 => uint256) public pieceIdToPricePerPrintInWei;

    mapping(address => bool) public isAdmin;

    mapping(uint256 => uint256) public printIdToPieceId;
    mapping(uint256 => uint256[]) internal pieceIdToPrintIds;
    mapping(uint256 => bytes32) public printIdToHash;
    mapping(uint256 => bytes32) public hashToTokenId;

    modifier onlyValidPrintId(uint256 _printId) {
        require(_exists(_printId), "Print ID does not exist");
        _;
    }

    modifier onlyUnlocked(uint256 _pieceId) {
        require(!pieces[_pieceId].locked, "Only if unlocked");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admin");
        _;
    }

    constructor(string memory _tokenName, string memory _tokenSymbol) ERC721(_tokenName, _tokenSymbol) {
        isAdmin[msg.sender] = true;
    }
}
