pragma solidity ^0.4.11;


import './SafeMathLib.sol';
import './CoreLib2.sol';
import './ColdStorage.sol';

library CoreLib {
  using SafeMathLib for uint256;
  
  event WalletOwnershipChangedEvent(address _wallet, address _from, address _to);
  
  function WalletOwnershipChanged(Types.DataContainer storage self, RemoteWalletLib.RemoteWalletData storage data, address _wallet, address _from, address _to) returns(bool) {
    require(_wallet == msg.sender);
    RemoteWalletInterface remote_wallet = RemoteWalletInterface(_wallet);
    
    if (remote_wallet.APIGetType() == 1) {
      //Virtual wallet
      require(self.find_virtual_wallet[_to] == address(0x0)); //Make sure these wallets don't just disappear
      self.find_virtual_wallet[_from] = address(0x0);
      self.find_virtual_wallet[_to] = _wallet;
      WalletOwnershipChangedEvent(_wallet, _from, _to);
      return true;
    }
    if (remote_wallet.APIGetType() == 2) {
      //Cold Storage
      require(self.find_cold_storage[_to] == address(0x0));
      self.find_cold_storage[_from] = address(0x0);
      self.find_cold_storage[_to] = _wallet;
      WalletOwnershipChangedEvent(_wallet, _from, _to);
      return true;
    }
    if (remote_wallet.APIGetType() == 3) {
      //Token Storage
      require(self.find_token_storage[_to] == address(0x0)); //Make sure these wallets don't just disappear
      self.find_token_storage[_from] = address(0x0);
      self.find_token_storage[_to] = _wallet;
      WalletOwnershipChangedEvent(_wallet, _from, _to);
      return true;
    }
    return false;
  }
  
  function CreateVirtualWallet(Types.DataContainer storage self, address _address) returns(address) {
    
    if (self.find_virtual_wallet[_address] == address(0x0)) {
      
      self.find_virtual_wallet[_address] = new VirtualWallet(address(this), _address);
      self.find_owner_by_smart_wallet_address[self.find_virtual_wallet[_address]] = _address;
      
      self.virtual_wallets.push(self.find_virtual_wallet[_address]);
    }
    return self.find_virtual_wallet[_address];
  }
  
  
  
  

}