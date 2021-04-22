// SPDX-License-Identifier: UNLICENSED
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

    mapping(uint256 => address[]) public pieceIdToAdditionalPayees;
    mapping(uint256 => mapping(address => uint256)) public pieceIdToAdditionalPayeeToPercentage;
    
    uint256 public nextPieceId = 0;

    modifier onlyValidPrintId(uint256 printId) {
        require(_exists(printId), "Print ID does not exist");
        _;
    }

    modifier onlyUnlocked(uint256 pieceId) {
        require(!pieces[pieceId].locked, "Only if unlocked");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admin");
        _;
    }

    constructor(string memory tokenName, string memory tokenSymbol) ERC721(tokenName, tokenSymbol) {
        isAdmin[msg.sender] = true;
    }
    
    function mint(address to, uint256 pieceId, address by) external returns (uint256) {
        require(isMintWhitelisted[msg.sender] || isAdmin[msg.sender], "Must be whitelisted to mint directly.");
        require(pieces[pieceId].currentPrints + 1 <= pieces[pieceId].maxPrints, "Must not exceed max invocations");
        require(pieces[pieceId].active || isAdmin[by], "Piece must exist and be active");
        require(pieces[pieceId].paused || isAdmin[by], "Purchasing prints of this piece are paused");

        return _mintPrint(to, pieceId);
    }

    function _mintPrint(address to, uint256 pieceId) internal returns (uint256) {
        uint256 printIdToBe = (pieceId * ONE_MILLION) + pieces[pieceId].currentPrints;
        pieces[pieceId].currentPrints = pieces[pieceId].currentPrints + 1;

        bytes32 hash = keccak256(abi.encodePacked(pieces[pieceId].currentPrints, block.number, blockhash(block.number - 1), msg.sender));
        printIdToHash[printIdToBe] = hash;
        hashToPrintId[hash] = printIdToBe;

        _safeMint(to, printIdToBe);

        printIdToPieceId[printIdToBe] = pieceId;
        pieceIdToPrintIds[pieceId].push(printIdToBe);

        emit Mint(to, printIdToBe, pieceId);

        return printIdToBe;
    }

    function addMintWhitelisted(address _address) external onlyAdmin {
        isMintWhitelisted[_address] = true;
    }

    function removeMintWhitelisted(address _address) external onlyAdmin {
        isMintWhitelisted[_address] = false;
    }

    function lockPiece(uint256 pieceId) external onlyAdmin onlyUnlocked(pieceId) {
        pieces[pieceId].locked = true;
    }

    function togglePieceIsActive(uint256 pieceId) external onlyAdmin {
        pieces[pieceId].active = !pieces[pieceId].active;
    }

    function togglePieceIsPaused(uint256 pieceId) external onlyAdmin {
        pieces[pieceId].paused = !pieces[pieceId].paused;
    }

    function addPiece(string memory pieceName) external onlyAdmin {
        uint256 pieceId = nextPieceId;
        pieces[pieceId].name = pieceName;
        pieces[pieceId].paused = true;
        
        nextPieceId = nextPieceId + 1;
    }

    function updatePiecePricePerPrintInWei(uint256 pieceId, uint256 pricePerPrintInWei) external onlyAdmin {
        pieceIdToPricePerPrintInWei[pieceId] = pricePerPrintInWei;
    }

    function updatePieceName(uint256 pieceId, string memory pieceName) external onlyAdmin onlyUnlocked(pieceId) {
        pieces[pieceId].name = pieceName;    
    }

    function updatePieceDescription(uint256 pieceId, string memory pieceDescription) external onlyAdmin {
        pieces[pieceId].description = pieceDescription;    
    }

    function updatePieceMaxPrints(uint256 pieceId, uint256 maxPrints) external onlyAdmin {
        require(!pieces[pieceId].locked || maxPrints < pieces[pieceId].maxPrints, "Can only increase max prints if piece is unlocked");
        require(maxPrints > pieces[pieceId].currentPrints, "Max prints must be more than current prints");
        require(maxPrints <= ONE_MILLION, "Max prints cannot exceed 1 million");
        pieces[pieceId].maxPrints = maxPrints;    
    }

    function updatePieceScript(uint256 pieceId, string memory script) external onlyUnlocked(pieceId) onlyAdmin {
        pieces[pieceId].script = script; 
    }

    function updatePieceLicense(uint256 pieceId, string memory pieceLicense) external onlyUnlocked(pieceId) onlyAdmin {
        pieces[pieceId].license = pieceLicense;
    }
    
    function pieceDetails(uint256 pieceId) view external returns (string memory pieceName_, string memory description_, string memory license_, uint256 pricePerPrintInWei_, uint256 currentPrints_, uint256 maxPrints_, bool active_, bool paused_, bool locked_) {
        pieceName_ = pieces[pieceId].name;
        description_ = pieces[pieceId].description;
        license_ = pieces[pieceId].license;
        pricePerPrintInWei_ = pieceIdToPricePerPrintInWei[pieceId];
        currentPrints_ = pieces[pieceId].currentPrints;
        maxPrints_ = pieces[pieceId].maxPrints;
        locked_ = pieces[pieceId].locked;
        active_ = pieces[pieceId].active;
        paused_ = pieces[pieceId].paused;
    }

    function pieceScript(uint256 pieceId) view external returns (string memory) {
        return pieces[pieceId].script;
    }

    function pieceShowAllPrints(uint pieceId) external view returns (uint256[] memory) {
        return pieceIdToPrintIds[pieceId];
    }

    function updateAdditionalPayee(uint256 pieceId, address additionalPayeeAddress, uint256 additionalPayeePercentage) external onlyAdmin {
        require(additionalPayeePercentage <= 100, "Percentage must be <= 100");
        uint i;
        bool found;
        uint totalPercentage = 0;
        for (i = 0; i < pieceIdToAdditionalPayees[pieceId].length; i++) {
            if (pieceIdToAdditionalPayees[pieceId][i] == additionalPayeeAddress) {
                found = true;
            } else {
                totalPercentage += pieceIdToAdditionalPayeeToPercentage[pieceId][pieceIdToAdditionalPayees[pieceId][i]];
            }
        }
        require(totalPercentage + additionalPayeePercentage <= 100, "Total additional payee percentage must be <= 100");
        if (!found) {
            pieceIdToAdditionalPayees[pieceId].push(additionalPayeeAddress);
        }
        pieceIdToAdditionalPayeeToPercentage[pieceId][additionalPayeeAddress] = additionalPayeePercentage;
    }

    function getAdditionalPayeesForPieceId(uint256 pieceId) external view returns (address[] memory) {
        return pieceIdToAdditionalPayees[pieceId];
    }

    function getAdditionalPayeePercentageForPieceIdAndAdditionalPayeeAddress(uint256 pieceId, address additionalPayeeAddress) external view returns (uint256) {
        return pieceIdToAdditionalPayeeToPercentage[pieceId][additionalPayeeAddress];
    }
    
}
