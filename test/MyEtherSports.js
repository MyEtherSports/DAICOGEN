var MyEtherSports = artifacts.require("./MyEtherSports.sol");
var SuperMajority = artifacts.require("./SuperMajority.sol");

const run = exports.run = async(accounts) => {

  const myethersports = await MyEtherSports.deployed();
  const supermajority = await SuperMajority.deployed();
  it("MyEtherSports should deploy", () => {
    assert(myethersports !== undefined, "MyEtherSports is deployed");
    assert(supermajority !== undefined, "SuperMajority is deployed");
  });
  return { myethersports, supermajority }
};

contract('MyEtherSports', run);