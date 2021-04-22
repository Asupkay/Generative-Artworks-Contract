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
});
