pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

contract GenerativeArtworks is ERC721Enumerable {

    event Mint(
        address indexed _to,
        uint256 indexed _printId,
        uint256 indexed _pieceId 
    );

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
    mapping(bytes32 => uint256) public hashToPrintId;
    
    mapping(address => bool) public isMintWhitelisted;

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
    
    function mint(address _to, uint256 _pieceId, address _by) external returns (uint256 _tokenId) {
        require(isMintWhitelisted[msg.sender], "Must be whitelisted to mint directly.");
        require(pieces[_pieceId].currentPrints + 1 <= pieces[_pieceId].maxPrints, "Must not exceed max invocations");
        require(pieces[_pieceId].active || isAdmin[_by], "Piece must exist and be active");
        require(pieces[_pieceId].paused || isAdmin[_by], "Purchasing prints of this piece are paused");

        uint256 tokenId = _mintToken(_to, _pieceId);

        return tokenId;
    }

    function _mintToken(address _to, uint256 _pieceId) internal returns (uint256 _tokenId) {
        uint256 printIdToBe = (_pieceId * ONE_MILLION) + pieces[_pieceId].currentPrints;
        pieces[_pieceId].currentPrints = pieces[_pieceId].currentPrints + 1;

        bytes32 hash = keccak256(abi.encodePacked(pieces[_pieceId].currentPrints, block.number, blockhash(block.number - 1), msg.sender));
        printIdToHash[printIdToBe] = hash;
        hashToPrintId[hash] = printIdToBe;

        emit Mint(_to, printIdToBe, _pieceId);

        return printIdToBe;
    }
}
