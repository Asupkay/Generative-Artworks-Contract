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
    describe("AddMintWhitelisted", () => {
      it("AddMintWhitelisted should add an address to isMintWhitelisted", async () => {
        expect(await tokenContract.isMintWhitelisted(owner.address)).to.be.false;
        tokenContract.addMintWhitelisted(owner.address);
        expect(await tokenContract.isMintWhitelisted(owner.address)).to.be.true;
      });

      it("AddMintWhitelisted should throw on non admin calls", async () => {
        await expect(
          tokenContract.connect(addr1).addMintWhitelisted(addr1.address)
        ).to.be.revertedWith("Only admin");
      });
    })

    describe("RemoveMintWhitelisted", () => {
      it("RemoveMintWhitelisted should remove an address from isMintWhitelisted", async () => {
        tokenContract.addMintWhitelisted(owner.address);
        tokenContract.removeMintWhitelisted(owner.address);
        expect(await tokenContract.isMintWhitelisted(owner.address)).to.be.false;
      });

      it("RemoveMintWhitelisted should throw on non admin calls", async () => {
        await expect(
          tokenContract.connect(addr1).removeMintWhitelisted(addr1.address)
        ).to.be.revertedWith("Only admin");
      });
    });
  })

  describe("isAdmin", () => {
    describe("addAdmin", () => {
      it("AddAdmin should add an address to isAdmin", async () => {
        expect(await tokenContract.isAdmin(addr1.address)).to.be.false;
        tokenContract.addAdmin(addr1.address);
        expect(await tokenContract.isAdmin(addr1.address)).to.be.true;
      });

      it("AddAdmin should throw on non admin calls", async () => {
        await expect(
          tokenContract.connect(addr1).addAdmin(addr1.address)
        ).to.be.revertedWith("Only admin");
      });
    });

    describe("removeAdmin", () => {
      it("RemoveAdmin should remove an address from isAdmin", async () => {
        tokenContract.addAdmin(addr1.address);
        tokenContract.removeAdmin(addr1.address);
        expect(await tokenContract.isMintWhitelisted(addr1.address)).to.be.false;
      });

      it("RemoveAdmin should throw on non admin calls", async () => {
        await expect(
          tokenContract.connect(addr1).removeAdmin(addr1.address)
        ).to.be.revertedWith("Only admin");
      });
    });
  })
});
