// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract GenerativeArtworksERC721 {
    mapping(uint256 => uint256) public pieceIdToPricePerPrintInWei;
    mapping(address => bool) public isAdmin;
    uint256 public nextPieceId = 0;

    function getAdditionalPayeesForPieceId(uint256 pieceId) external view returns (address[] memory) {}
    function getAdditionalPayeePercentageForPieceIdAndAdditionalPayeeAddress(uint256 pieceId, address additionalPayeeAddress) external view returns (uint256) {}

    function mint(address to, uint256 pieceId, address by) external returns (uint256) {}
}

contract GenerativeArtworksPayable {

    GenerativeArtworksERC721 internal mintContract;
    address payable public generativeArtworksWallet;
    mapping(uint256 => mapping(address => bool)) public hasMinted;
    mapping(uint256 => bool) public isLimited;
    mapping(uint256 => address[]) public pieceIdToAdditionalPayees;
    mapping(uint256 => mapping(address => uint256)) public pieceIdToAdditionalPayeeToPercentage;

    modifier onlyAdmin() {
        require(mintContract.isAdmin(msg.sender), "Only admin");
        _;
    }

    modifier onlyValidPieceId(uint256 pieceId) {
        require(pieceId >= 0 && pieceId < mintContract.nextPieceId(), "Piece ID does not exist");
        _;
    }

    constructor(address mintContractAddress) {
        mintContract = GenerativeArtworksERC721(mintContractAddress);
        generativeArtworksWallet = payable(msg.sender);
    }

    function purchase(address mintTo, uint256 pieceId, address by) payable external returns (uint256) {
        // Check if piece is limited to one mint per wallet address
        if (isLimited[pieceId]) {
            // require that user has not minted this piece or user is an admin
            require(!hasMinted[pieceId][by] || mintContract.isAdmin(by), "Limited to one mint per address");
        }

        // Check if the right value was sent with the transaction
        require(msg.value == mintContract.pieceIdToPricePerPrintInWei(pieceId), "Incorrect payment amount or invalid piece ID");

        // Mint on other contract
        uint256 newPrintId = mintContract.mint(mintTo, pieceId, by);

        // Track that "by" has minted "pieceId"
        hasMinted[pieceId][by] = true;

        // Pay to additional payees
        uint256 amountPaidOut = 0;
        uint256 amountToPay = 0;
        uint256 i = 0;
        address[] memory additionalPayees = mintContract.getAdditionalPayeesForPieceId(pieceId);
        for (i = 0; i < additionalPayees.length; i++) {
            amountToPay = msg.value / 100 * mintContract.getAdditionalPayeePercentageForPieceIdAndAdditionalPayeeAddress(pieceId, additionalPayees[i]);
            payable(additionalPayees[i]).transfer(amountToPay);
            amountPaidOut = amountPaidOut + amountToPay;
        }

        // Pay to generative artworks wallet
        generativeArtworksWallet.transfer(msg.value - amountPaidOut);

        return newPrintId;
    }

    function toggleIsLimited(uint256 pieceId) external onlyAdmin {
        isLimited[pieceId] = !isLimited[pieceId];
    }

    function changeMintContract(address mintContractAddress) external onlyAdmin {
        mintContract = GenerativeArtworksERC721(mintContractAddress);
    }

    function changePayableAddress(address payable payableAddress) external onlyAdmin {
        generativeArtworksWallet = payableAddress;
    }

    function updateAdditionalPayee(uint256 pieceId, address additionalPayeeAddress, uint256 additionalPayeePercentage) external onlyValidPieceId(pieceId) onlyAdmin {
        require(additionalPayeePercentage <= 100, "Percentage must be <= 100");
        uint i;
        bool found;
        uint totalPercentage = 0;
        address currentPayeeAddress;
        for (i = 0; i < pieceIdToAdditionalPayees[pieceId].length; i++) {
            currentPayeeAddress = pieceIdToAdditionalPayees[pieceId][i];
            if (currentPayeeAddress == additionalPayeeAddress) {
                found = true;
            } else {
                totalPercentage += pieceIdToAdditionalPayeeToPercentage[pieceId][currentPayeeAddress];
            }
        }
        require(totalPercentage + additionalPayeePercentage <= 100, "Total percentage must be <= 100");
        if (!found) {
            pieceIdToAdditionalPayees[pieceId].push(additionalPayeeAddress);
        }
        pieceIdToAdditionalPayeeToPercentage[pieceId][additionalPayeeAddress] = additionalPayeePercentage;
    }

    function getAdditionalPayeesForPieceId(uint256 pieceId) external view onlyValidPieceId(pieceId) returns (address[] memory) {
        return pieceIdToAdditionalPayees[pieceId];
    }

    function getAdditionalPayeePercentageForPieceIdAndAdditionalPayeeAddress(uint256 pieceId, address additionalPayeeAddress) external view onlyValidPieceId(pieceId) returns (uint256) {
        return pieceIdToAdditionalPayeeToPercentage[pieceId][additionalPayeeAddress];
    }

}
