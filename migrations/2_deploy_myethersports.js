
const Scenario = artifacts.require('Scenario.sol');

const SafeMathLib = artifacts.require('SafeMathLib.sol');
const ERC20Lib = artifacts.require('ERC20Lib.sol');

const BaseLib = artifacts.require('BaseLib.sol');
const BaseLib2 = artifacts.require('BaseLib2.sol');
const BaseLib3 = artifacts.require('BaseLib3.sol');

const CoreLib = artifacts.require('CoreLib.sol');
const CoreLib2 = artifacts.require('CoreLib2.sol');
const CoreLib3 = artifacts.require('CoreLib3.sol');

const RemoteWalletLib = artifacts.require('RemoteWalletLib.sol');
const BaseWalletLib = artifacts.require('BaseWalletLib.sol');
const ColdStorageLib = artifacts.require('ColdStorageLib.sol');

const MyEtherSports = artifacts.require('MyEtherSports.sol');

const SuperMajority = artifacts.require('SuperMajority.sol');
const SuperMajorityLib = artifacts.require('SuperMajorityLib.sol');

const Action = artifacts.require('Action.sol');
const DummyParent = artifacts.require('DummyParent.sol');

async function doDeploy(deployer) {
    await deployer.deploy(Scenario);
    
    await deployer.deploy(SafeMathLib);
  
    await deployer.link(SafeMathLib, ERC20Lib);
    await deployer.deploy(ERC20Lib);
  
    await deployer.link(SafeMathLib, RemoteWalletLib);
    await deployer.deploy(RemoteWalletLib);
    
    await deployer.link(SafeMathLib, BaseWalletLib);
    await deployer.link(RemoteWalletLib, BaseWalletLib);
    await deployer.deploy(BaseWalletLib);
    
    await deployer.link(SafeMathLib, CoreLib2);
    await deployer.link(RemoteWalletLib, CoreLib2);
    await deployer.link(BaseWalletLib, CoreLib2);
    await deployer.deploy(CoreLib2);
    
    await deployer.link(SafeMathLib, CoreLib);
    await deployer.link(RemoteWalletLib, CoreLib);
    await deployer.link(BaseWalletLib, CoreLib);
    await deployer.link(CoreLib2, CoreLib);
    await deployer.deploy(CoreLib);
    
    await deployer.link(SafeMathLib, ColdStorageLib);
    await deployer.link(RemoteWalletLib, ColdStorageLib);
    await deployer.deploy(ColdStorageLib);
    
    await deployer.link(SafeMathLib, CoreLib3);
    await deployer.link(RemoteWalletLib, CoreLib3);
    await deployer.link(ColdStorageLib, CoreLib3);
    await deployer.deploy(CoreLib3);
  
    await deployer.link(SafeMathLib, BaseLib);
    await deployer.link(RemoteWalletLib, BaseLib);
    await deployer.link(BaseWalletLib, BaseLib);
    await deployer.link(CoreLib, BaseLib);
    await deployer.link(CoreLib2, BaseLib);
    await deployer.deploy(BaseLib);
    
    await deployer.link(SafeMathLib, BaseLib2);
    await deployer.link(RemoteWalletLib, BaseLib2);
    await deployer.link(CoreLib, BaseLib2);
    await deployer.link(CoreLib2, BaseLib2);
    await deployer.link(CoreLib3, BaseLib2);
    await deployer.deploy(BaseLib2);
    
    await deployer.link(SafeMathLib, BaseLib3);
    await deployer.link(ERC20Lib, BaseLib3);
    await deployer.link(RemoteWalletLib, BaseLib3);
    await deployer.link(CoreLib, BaseLib3);
    await deployer.link(BaseLib, BaseLib3);
    await deployer.link(BaseLib2, BaseLib3);
    await deployer.deploy(BaseLib3);
    
    await deployer.link(SafeMathLib, MyEtherSports);
    await deployer.link(ERC20Lib, MyEtherSports);
    await deployer.link(RemoteWalletLib, MyEtherSports);
    await deployer.link(BaseLib, MyEtherSports);
    await deployer.link(BaseLib2, MyEtherSports);
    await deployer.link(BaseLib3, MyEtherSports);
    await deployer.link(CoreLib, MyEtherSports);
    await deployer.link(CoreLib2, MyEtherSports);
    await deployer.link(CoreLib3, MyEtherSports);
    await deployer.deploy(MyEtherSports);
    
    const myethersports = await MyEtherSports.deployed();
    
    await deployer.link(SafeMathLib, SuperMajorityLib);
    await deployer.link(RemoteWalletLib, SuperMajorityLib);
    await deployer.deploy(SuperMajorityLib);
    
    await deployer.link(SafeMathLib, SuperMajority);
    await deployer.link(RemoteWalletLib, SuperMajority);
    await deployer.link(SuperMajorityLib, SuperMajority);
    await deployer.deploy(SuperMajority, myethersports.address, 0x0, 40);
    
    await deployer.link(RemoteWalletLib, Action);
    await deployer.deploy(Action);
    
    await deployer.link(RemoteWalletLib, DummyParent);
    await deployer.deploy(DummyParent);
}

module.exports = (deployer) => {
    deployer.then(async () => {
        await doDeploy(deployer);
    });
};
