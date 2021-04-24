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
});
