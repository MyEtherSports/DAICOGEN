pragma solidity ^0.4.11;


import './Interfaces.sol';
import './SafeMathLib.sol';
import './RemoteWalletLib.sol';

/*
Base class for a remote wallet that is a smart contract. It gives owner control over it's functionality and allows for automation by giving call privileges to other addresses.
RestrictedCall() and APIHasWriteAccess() modifiers are very important and are the backbone of the entire system. Function permissions are limited within the parent and owner scopes, meaning if ehtier parent or owner change - permissions reset to their defaults.
*/

contract RemoteWallet is RemoteWalletInterface {
  using SafeMathLib for uint256;
  
  //event DebugAddress(address _address);
  //event DebugString(string _string);
  //event DebugUInt(uint _value);
  
  RemoteWalletLib.RemoteWalletData data;
  

  function _APICall(bytes4 func_signature, address _for) internal constant returns(bool) {
    return RemoteWalletLib._APICall(data, func_signature, _for);
  }
  
  
  function _APIHasWriteAccess(bytes4 func_signature, address _for) internal returns(bool) {
    return RemoteWalletLib._APIHasWriteAccess(data, func_signature, _for);
  }
  
  
  //With this modifier user can change permissions, but only if the permission has a write flag bit.
  modifier APIHasWriteAccess(bytes4 func_signature) {
    require(_APIHasWriteAccess(func_signature, msg.sender));
    if(true) {
      _;
    }
  }  
    
  modifier OnlyOnce() {
    require(!data.once[msg.sig]);
    if (true) {
      data.once[msg.sig] = true;
      _;
    }
  }
  
  //By default only owner and parent contract are authorized to call any of the functions with this modifier.
  //That includes SetPermission functions meaning only owner and parent can change permissions.
  modifier RestrictedCall() {
    require(_APICall(msg.sig, msg.sender));
    if(true) {
      _;
    }
  }
  
  modifier TimeLocked(uint256 _unlock_after_timestamp) {
    require(block.timestamp.add(data.master_contract._TMP_get_time_shift()) >= _unlock_after_timestamp);
    if(true) {
      _;
    }
  }
  
  function RemoteWallet(address _parent, address _owner) {
    data.owner = _owner;
    data.parent = _parent;
    
    //DebugString("RemoteWalletConstruct");
    //DebugAddress(_owner);
    //DebugAddress(_parent);
    
    data.root = _parent;
    data.master_contract = MasterContractInterface(data.root);
    
    _InitOwnerPermissions();
    _InitParentPermissions();
  }
  
  //CAUTION: this function executes a delegate call that can mess with the internal state.
  //By default no one can call it, unless granted permission to do so.
  function APISuperMajorityCall(address _code_contract, bytes4 _signature) external RestrictedCall() {
    _code_contract.delegatecall(_signature);
  }
  
  function _InitOwnerPermissions() internal {
    RemoteWalletLib._InitOwnerPermissions(data);
  }
  
  function _InitParentPermissions() internal {
    RemoteWalletLib._InitParentPermissions(data);
  }
  
  
  //Only parent contract can deposit funds, that must come from the owner.
  function() payable RestrictedCall() {}
  function APIDeposit() RestrictedCall() payable external returns(bool) {}
  
  function _SetPermissionBySig(bytes4 func_signature, address _for, bool _can_execute, bool _can_write) internal returns(bool) {
    return RemoteWalletLib._SetPermissionBySig(data, func_signature, _for, _can_execute, _can_write);
  }
  
  function APIGetPermissionBySig(bytes4 func_signature, address _for) public constant returns(bool, bool) {
    return RemoteWalletLib.APIGetPermissionBySig(data, func_signature, _for);
  }
  
  function APIGetPermissionByName(string _function, address _for) public constant returns(bool, bool) {
    return RemoteWalletLib.APIGetPermissionBySig(data, bytes4(sha3(_function)), _for);
  }
  
  function APIGetRoot() public constant returns(address) {
    return data.root;
  }
  
  function APIGetParent() public constant returns(address) {
    return data.parent;
  }
  
  function APIGetOwner() public constant returns(address) {
    return data.owner;
  }
  
  function APIGetType() public constant returns(uint256) {
    return data.wallet_type;
  }
  

  
  function APISetPermissionByName(string _function, address _for, bool _can_execute, bool _can_write) public returns(bool) { //Doesn't need modifiers
    return APISetPermissionBySig(bytes4(sha3(_function)), _for, _can_execute, _can_write);
  }
  
  function APISetPermissionBySig(bytes4 func_signature, address _for, bool _can_execute, bool _can_write) public RestrictedCall() APIHasWriteAccess(func_signature) returns(bool) {
      return RemoteWalletLib._SetPermissionBySig(data, func_signature, _for, _can_execute, _can_write);
  }
  
  //CAUTION: this will change wallet ownership, resetting permissions to their default.
  function APITransferOwnership(address _new_owner) public RestrictedCall() returns(bool) {
    require(RemoteWalletLib.APITransferOwnership(data, _new_owner));
        if(!data.known_owners[data.owner]) {
          _InitOwnerPermissions();
        }
        _InitParentPermissions();
        return true;
  }
  
  //CAUTION: this will disconnect wallet from the parent contract, as well as change wallet ownership and resetting permissions to their defaults.
  function APIChangeParent(address _new_parent) public RestrictedCall() returns(bool) {
    require(RemoteWalletLib.APIChangeParent(data, _new_parent));
        if (!data.known_parents[data.parent]) {
          _InitParentPermissions();
        }
        _InitOwnerPermissions();
        return true;
  }
}

