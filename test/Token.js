const { expect } = require("chai");

describe("Token contract", () => {
  let tokenContract;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async () => {
    const Token = await ethers.getContractFactory("GenerativeArtworks");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    tokenContract = await Token.deploy("Generative Artworks", "GA");
    
  });

  describe("Deploy", () => {
    it("Should assign deployer as admin", async () => {
      expect(await tokenContract.isAdmin(owner.address)).to.be.true;
    });

    it("Should not assign anyone else as admin on deploy", async () => {
      expect(await tokenContract.isAdmin(addr1.address)).to.be.false;
    });
  });

  describe("isMintWhitelisted", () => {
    describe("toggleMintAllowlisted", () => {
      it("toggleMintAllowlisted should add an address to isMintAllowlisted", async () => {
        expect(await tokenContract.isMintAllowlisted(owner.address)).to.be.false;
        tokenContract.toggleMintAllowlisted(owner.address);
        expect(await tokenContract.isMintAllowlisted(owner.address)).to.be.true;
      });

      it("toggleMintWhitelisted should throw on non admin calls", async () => {
        await expect(
          tokenContract.connect(addr1).toggleMintAllowlisted(addr1.address)
        ).to.be.revertedWith("Only admin");
      });
    })
  })

  describe("isAdmin", () => {
    describe("toggleAdmin", () => {
      it("toggleAdmin should add an address to isAdmin", async () => {
        expect(await tokenContract.isAdmin(addr1.address)).to.be.false;
        tokenContract.toggleAdmin(addr1.address);
        expect(await tokenContract.isAdmin(addr1.address)).to.be.true;
      });

      it("ToggleAdmin should throw on non admin calls", async () => {
        await expect(
          tokenContract.connect(addr1).toggleAdmin(addr1.address)
        ).to.be.revertedWith("Only admin");
      });
    });
  })

  describe("Piece CRUD", () => {
    beforeEach(async () => {
      const name = "Piece1";
      const description = "This is piece one";
      const license = "NIFTY";
      const baseURI = "http://test.com";
      const maxPrints = ethers.BigNumber.from(64);
      const script = "nice";
      const pricePerPrintInWei = ethers.BigNumber.from(100);
      await tokenContract.addPiece(name, description, license, baseURI, maxPrints, script, pricePerPrintInWei);
    });

    describe("Creating a piece", () => {
      it("should iterate the next piece id", async () => {
        expect(await tokenContract.nextPieceId()).to.equal(1);
      });
    });

    describe("PieceDetails", () => {
      it("should be able to get the added piece", async () => {
        expect((await tokenContract.connect(addr1).pieceDetails(0)).toString()).to.equal("Piece1,This is piece one,NIFTY,100,0,64,false,true,false");
      });

      it("should not be able to get an invalid piece id", async () => {
        await expect(tokenContract.connect(addr1).pieceDetails(1)).to.be.revertedWith("Piece ID does not exist");
      });
    });

    describe("PieceScript", () => {
      it("should be able to get the piece script", async () => {
        expect((await tokenContract.connect(addr1).pieceScript(0)).toString()).to.equal("nice");
      });

      it("should not be able to get an invalid piece id", async () => {
        await expect(tokenContract.connect(addr1).pieceScript(1)).to.be.revertedWith("Piece ID does not exist");
      });
    });

    describe("UpdatePieceScript", () => {
      it("should be able to update the piece script", async () => {
        expect((await tokenContract.pieceScript(0)).toString()).to.equal("nice");
        await tokenContract.updatePieceScript(0, "test")
        expect((await tokenContract.pieceScript(0)).toString()).to.equal("test");
      });

      it("should revert on not admin", async () => {
        await expect(
          tokenContract.connect(addr1).updatePieceScript(0, "test")
        ).to.be.revertedWith("Only admin");
      });
    });
  })
});
