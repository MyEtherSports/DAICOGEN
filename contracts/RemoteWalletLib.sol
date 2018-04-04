pragma solidity ^0.4.11;


import './Interfaces.sol';
import './SafeMathLib.sol';

import './RemoteWalletHeaders.sol';

library RemoteWalletLib {
  using SafeMathLib for uint256;
  
  //event DebugAddress(address _address);
  //event DebugString(string _string);
  //event DebugUInt(uint _value);
  //event DebugBytes4(bytes4 _signature);
  
  
  struct RemoteWalletData {
    address root;
    address parent;
    address owner;
    uint256 wallet_type;
    
    mapping(address => bool) known_parents;
    mapping(address => bool) known_owners;
    
    MasterContractInterface master_contract;
    
    mapping(bytes4 => PermissionSet) get_func_permission_set;
    
    mapping(bytes4 => bool) once;
    
    mapping(bytes4 => mapping(address => uint256)) call_sequence_number;
  }
  
  struct Permission {
    bool can_execute;
    bool can_write;
  }
  
  struct Permissions {
    Permission get_public_group_permission;
    mapping(address => Permission) get_permission;
  }
  
  struct ParentPermissionSet {
    mapping(address => Permissions) get_owner_scope;
  }
  
  struct PermissionSet {
    mapping(address => ParentPermissionSet) get_parent_scope;
  }
  
  uint256 constant seconds_in_a_day = 86400;
  function GetSecondsInADay() returns(uint256) {
    return seconds_in_a_day;
  }
  
  function _InitOwnerPermissions(RemoteWalletData storage self) {
    _SetPermissionBySig(self, 0, self.owner, true, true);
    
    _SetPermissionBySig(self, bytes4(sha3("APIDeposit()")), self.owner, true, true);
    _SetPermissionBySig(self, bytes4(sha3("APITransferOwnership(address)")), self.owner, true, true);
    
    _SetPermissionBySig(self, bytes4(sha3("APIChangeParent(address)")), self.owner, true, true);
    _SetPermissionBySig(self, bytes4(sha3("APISetPermissionByName(string,address,bool,bool)")), self.owner, true, true);
    
    _SetPermissionBySig(self, bytes4(sha3("APISetPermissionBySig(bytes4,address,bool,bool)")), self.owner, true, true);
  }
  
  function _InitParentPermissions(RemoteWalletData storage self) {
    _SetPermissionBySig(self, 0, self.parent, true, false);
    
    _SetPermissionBySig(self, bytes4(sha3("APIDeposit()")), self.parent, true, false);
    
    _SetPermissionBySig(self, bytes4(sha3("APISetPermissionBySig(bytes4,address,bool,bool)")), self.parent, true, false);
    
    _SetPermissionBySig(self, bytes4(sha3("APISuperMajorityCall(address,bytes4)")), self.parent, false, true); //Parent must be able to assign who gets to call this function
  }
  
  function GetCallSequence(RemoteWalletData storage self, bytes4 _sig) constant returns(uint256) {
    return self.call_sequence_number[_sig][msg.sender].add(1);
  }
  
  function NextCallSequence(RemoteWalletData storage self, bytes4 _sig) {
    self.call_sequence_number[_sig][msg.sender] = self.call_sequence_number[_sig][msg.sender].add(1);
  }
  
  function _APICall(RemoteWalletData storage self, bytes4 func_signature, address _for) constant returns(bool) {
    if (self.get_func_permission_set[func_signature].get_parent_scope[self.parent].get_owner_scope[self.owner].get_permission[_for].can_execute) return true;
    else {
      if (self.get_func_permission_set[func_signature].get_parent_scope[self.parent].get_owner_scope[self.owner].get_public_group_permission.can_execute) return true;
    }
    return false;
  }
  
  function _APIHasWriteAccess(RemoteWalletData storage self, bytes4 func_signature, address _for) returns(bool) {
    if (self.get_func_permission_set[func_signature].get_parent_scope[self.parent].get_owner_scope[self.owner].get_permission[_for].can_write) return true;
    else {
      if (self.get_func_permission_set[func_signature].get_parent_scope[self.parent].get_owner_scope[self.owner].get_public_group_permission.can_write) return true;
    }
    return false;
  }
  
  
  function _SetPermissionBySig(RemoteWalletData storage self, bytes4 func_signature, address _for, bool _can_execute, bool _can_write) returns(bool) {
    if (_for == address(0x0)) {
      self.get_func_permission_set[func_signature].get_parent_scope[self.parent].get_owner_scope[self.owner].get_public_group_permission.can_execute = _can_execute;
      self.get_func_permission_set[func_signature].get_parent_scope[self.parent].get_owner_scope[self.owner].get_public_group_permission.can_write = _can_write;
    }
    else {
      self.get_func_permission_set[func_signature].get_parent_scope[self.parent].get_owner_scope[self.owner].get_permission[_for].can_execute = _can_execute;
      self.get_func_permission_set[func_signature].get_parent_scope[self.parent].get_owner_scope[self.owner].get_permission[_for].can_write = _can_write;
    }
    return true;
  }
  
  function APIGetPermissionBySig(RemoteWalletData storage self, bytes4 func_signature, address _for) constant returns(bool, bool) {
    bool can_execute = false;
    bool can_write = false;
    if (_for != address(0x0)) {
      can_execute = self.get_func_permission_set[func_signature].get_parent_scope[self.parent].get_owner_scope[self.owner].get_permission[_for].can_execute;
      can_write = self.get_func_permission_set[func_signature].get_parent_scope[self.parent].get_owner_scope[self.owner].get_permission[_for].can_write;
    }
    
    can_execute = can_execute || self.get_func_permission_set[func_signature].get_parent_scope[self.parent].get_owner_scope[self.owner].get_public_group_permission.can_execute;
    can_write = can_write || self.get_func_permission_set[func_signature].get_parent_scope[self.parent].get_owner_scope[self.owner].get_public_group_permission.can_write;
    
    return (can_execute, can_write);
  }


  
  //CAUTION: this will change wallet ownership, resetting permissions to their default.
  function APITransferOwnership(RemoteWalletData storage self, address _new_owner) returns(bool) {
    require(_new_owner != address(0x0));
    
    if (self.owner == _new_owner) {
      return false;
    }
    else {
      
      bool virtual_wallet_transfer = (self.master_contract.GetVirtualWallet(self.owner) == address(this) && !self.master_contract.HasVirtualWallet(_new_owner));
      bool cold_storage_transfer = (self.master_contract.GetColdStorage(self.owner) == address(this) && !self.master_contract.HasColdStorage(_new_owner));
      bool token_storage_transfer = (self.master_contract.GetTokenStorage(self.owner) == address(this) && !self.master_contract.HasTokenStorage(_new_owner));
      
      require(virtual_wallet_transfer || cold_storage_transfer || token_storage_transfer);
      
      address old_owner = self.owner;
      
      self.known_owners[self.owner] = true; //remember
      
      self.owner = _new_owner;
      
      self.master_contract.WalletOwnershipChanged(address(this), old_owner, _new_owner); //Notify parent.
      //Since owner is now different, we send old_owner as an argument, so that master contract can properly reconfigure.
      
      return true;
    }
  }
  
  
  //CAUTION: this will disconnect wallet from the parent contract, as well as change wallet ownership and resetting permissions to their defaults.
  function APIChangeParent(RemoteWalletData storage self, address _new_parent) returns(bool) {
    
    if (self.parent == _new_parent) return false;
    else {
      
      self.known_parents[self.parent] = true; //remember
      
      address old_parent = self.parent;
      
      self.parent = _new_parent;
      
      self.master_contract.WalletParentChanged(address(this), self.owner, _new_parent); //Notify parent
      
      self.master_contract = MasterContractInterface(self.parent);
    
      return true;
    }

    
    return false;
  }
  
}

