pragma solidity ^0.4.11;


import './Interfaces.sol';
import './SafeMathLib.sol';

import './CoreLib.sol';
import './CoreLib2.sol';
import './CoreLib3.sol';

import './TokenStorage.sol';



library BaseLib {
  using SafeMathLib for uint256;
  
  //event DebugAddress(address _address);
  //event DebugString(string _string);
  //event DebugUInt(uint _value);
  
  
  function _InitOwnerPermissions(RemoteWalletLib.RemoteWalletData storage self) {
    RemoteWalletLib._SetPermissionBySig(self, 0, address(0x0), true, false); //Anyone can send ether
    RemoteWalletLib._SetPermissionBySig(self, bytes4(sha3("PlaceOrder(bytes8)")), address(0x0), true, false);
    
    RemoteWalletLib._SetPermissionBySig(self, bytes4(sha3("ForceMajeure()")), self.owner, true, true);
    
    //Owner can call and change permissions for following functions:
    RemoteWalletLib._SetPermissionBySig(self, 0, self.owner, true, true); //Owner should be able to turn it off in an emergency situation.
    RemoteWalletLib._SetPermissionBySig(self, bytes4(sha3("PlaceOrder(bytes8)")), self.owner, true, true); //Owner should be able to turn it off in an emergency situation.
    RemoteWalletLib._SetPermissionBySig(self, bytes4(sha3("SetSuperMajorityAddress(address)")), self.owner, true, false);
    RemoteWalletLib._SetPermissionBySig(self, bytes4(sha3("Distribute(uint256,bool,uint256,uint256,uint256,bytes32)")), self.owner, true, false);
    RemoteWalletLib._SetPermissionBySig(self, bytes4(sha3("SetBurnRequired(bool)")), self.owner, true, true);
    
    //RemoteWalletLib._SetPermissionBySig(self, bytes4(sha3("_TMP_forward_time(uint256)")), self.owner, true, true); //TODO: remove
    
    RemoteWalletLib._SetPermissionBySig(self, bytes4(sha3("PostInit()")), self.owner, true, true);
    RemoteWalletLib._SetPermissionBySig(self, bytes4(sha3("AddAngelInvestors()")), self.owner, true, true);
  }
  
  function Deposit(Types.DataContainer storage self) {
    require(msg.value > 0);
    if(!CoreLib2.HasVirtualWallet(self, msg.sender)) CoreLib.CreateVirtualWallet(self, msg.sender);
    
    VirtualWalletInterface virtual_wallet = VirtualWalletInterface(CoreLib2.GetVirtualWallet(self, msg.sender));
    virtual_wallet.APIDeposit.value(msg.value)();
  }
  
  //TMP
  function Withdraw(Types.DataContainer storage self, uint256 _amount) returns(uint256) {
    require(CoreLib2.HasVirtualWallet(self, msg.sender));
    
    VirtualWalletInterface virtual_wallet = VirtualWalletInterface(CoreLib2.GetVirtualWallet(self, msg.sender));
    return virtual_wallet.APIWithdraw(_amount);
  }
  
  function TransferWalletOwnership(address _address, address _new_owner) returns(bool) {
    RemoteWalletInterface remote_wallet = RemoteWalletInterface(_address);
    return remote_wallet.APITransferOwnership(_new_owner);
  }

  function _CreateTokenStorage(Types.DataContainer storage self, address _address, uint256 _amount, uint256 _divider) returns(address) {
    require(_amount > 0);
    
    if (CoreLib2.HasTokenStorage(self, _address)) return CoreLib2.GetTokenStorage(self, _address);
    
    uint256 daily = 0;
    if (_divider == 0) daily = 0; //No limit
    else daily = _amount / _divider;
    
    TokenStorage token_storage = new TokenStorage(address(this), _address, daily);
    
    token_storage.APISetTokenAmount(_amount);
    self.find_token_storage[_address] = address(token_storage);
    
    self.locked_token_amount = self.locked_token_amount.add(_amount); //Not used
    
    return address(token_storage);
  }
  
  function _GetRefund(Types.DataContainer storage self, address _addr) returns(address, uint256) {
    require(CoreLib2.HasColdStorage(self, _addr));
    
    ColdStorageInterface cold_storage = ColdStorageInterface(CoreLib2.GetColdStorage(self, _addr));
    uint256 tokens_to_burn = cold_storage.APIGetTokensBought();
      
    return (address(cold_storage), tokens_to_burn);
  }
  
  //Allow ICO participants to get full refund at any given time outside of distribution hours (won't work during ICO period)
  function GetRefund(Types.DataContainer storage self) returns(address, uint256) {
    uint256 distributions = self.dist_periods.length;
    uint256 current_timestamp = block.timestamp.add(self._tmp_timeshift);
    
    //Only allow refunds outside of a distribution period. 
    for (uint256 i = 0; i < distributions; i++) {
      Types.DistPeriod storage tmp_dist_period = self.dist_periods[i];
      bool inside_distribution = current_timestamp < tmp_dist_period.end_time && current_timestamp >= tmp_dist_period.start_time;
      require(!inside_distribution);
    }
    
    return _GetRefund(self, msg.sender);
  }
}