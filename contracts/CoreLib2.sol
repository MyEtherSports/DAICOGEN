pragma solidity ^0.4.11;


import './Interfaces.sol';
import './SafeMathLib.sol';
import './TokenStorage.sol';

library CoreLib2 {
  using SafeMathLib for uint256;
  
    //Since libraries can't derive from other contracts, events must be declared twice and have to match in order for them to get triggered.
    
    event RefundedNotificationEvent(address _from, uint256 _amount_burned, uint256 _amount_refunded);
    
    event WalletParentChangedEvent(address _wallet, address _from, address _new_parent);
    
    event WalletWithdrewEvent(address _from, address _to, uint256 _amount);
  

  function CreateTokenStorage(Types.DataContainer storage self, uint256 _daily_amount) returns(address) {
    //require(_daily_amount > 0);
    require(!HasTokenStorage(self, msg.sender));
    
    self.find_token_storage[msg.sender] = new TokenStorage(address(this), msg.sender, _daily_amount);
    return GetTokenStorage(self, msg.sender);
  }
  
  function WalletParentChanged(Types.DataContainer storage self, address _wallet, address _from, address _new_parent) {
    //Disconnect walllet from this organization, meaning user will have to set parent manually.
    WalletParentChangedEvent(_wallet, _from, _new_parent);
  }
  
  function WalletWithdrewCallback(Types.DataContainer storage self, address _from, address _to, uint256 _amount) {
    //A user withdrew from their virtual wallet.
    WalletWithdrewEvent(_from, _to, _amount);
  }
  
  function RefundedNotification(Types.DataContainer storage self, address _from, uint256 _amount_burned, uint256 _amount_refunded) {
    self.locked_ether_amount = self.locked_ether_amount.sub(_amount_refunded);
    self.tracker.tokens_burned += _amount_burned;
    
    RefundedNotificationEvent(_from, _amount_burned, _amount_refunded);
  }
  
  function GetFoundationTokenStorage(Types.DataContainer storage self) constant returns(address) {
    return self.foundation_token_storage;
  }
  
  //----------------
  function HasTokenStorage(Types.DataContainer storage self, address _address) constant returns(bool) {
    return self.find_token_storage[_address] != address(0x0);
  }
  
  function HasVirtualWallet(Types.DataContainer storage self, address _address) constant returns(bool) {
    return self.find_virtual_wallet[_address] != address(0x0);
  }

  
  function HasColdStorage(Types.DataContainer storage self, address _address) constant returns(bool) {
    return self.find_cold_storage[_address] != address(0x0);
  }
  
  
  function GetSuperMajorityWallet(Types.DataContainer storage self) constant returns(address) {
    return self.supermajority_group;
  }
  
  function GetVirtualWallet(Types.DataContainer storage self, address _address) constant returns(address) {
    return self.find_virtual_wallet[_address];
  }
  
  function GetColdStorage(Types.DataContainer storage self, address _address) constant returns(address) {
    return self.find_cold_storage[_address];
  }
  
  function GetTokenStorage(Types.DataContainer storage self, address _address) constant returns(address) {
    return self.find_token_storage[_address];
  }

}