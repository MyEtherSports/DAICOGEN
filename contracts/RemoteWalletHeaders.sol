pragma solidity ^0.4.11;


contract RemoteWalletInterface {
  function _APICall(bytes4 func_signature, address _for) internal constant returns(bool);
  function _APIHasWriteAccess(bytes4 func_signature, address _for) internal returns(bool);
  //CAUTION: this function executes a delegate call that can mess with the internal state.
  //By default no one can call it, unless granted permission to do so.
  function APISuperMajorityCall(address _code_contract, bytes4 _signature) external;
  function _InitOwnerPermissions() internal;
  function _InitParentPermissions() internal;
  //Only parent contract can deposit funds, that must come from the owner.
  function() payable;
  function APIDeposit() payable external returns(bool);
  function _SetPermissionBySig(bytes4 func_signature, address _for, bool _can_execute, bool _can_write) internal returns(bool);
  function APIGetPermissionBySig(bytes4 func_signature, address _for) public constant returns(bool, bool);
  function APIGetPermissionByName(string _function, address _for) public constant returns(bool, bool);
  function APIGetRoot() public constant returns(address);
  function APIGetParent() public constant returns(address);
  function APIGetOwner() public constant returns(address);
  function APIGetType() public constant returns(uint256);
  function APISetPermissionByName(string _function, address _for, bool _can_execute, bool _can_write) public returns(bool);
  function APISetPermissionBySig(bytes4 func_signature, address _for, bool _can_execute, bool _can_write) public returns(bool);
  function APITransferOwnership(address _new_owner) public returns(bool);
  function APIChangeParent(address _new_parent) public returns(bool);
}


contract ColdStorageInterface is RemoteWalletInterface {
  function _APIAddRefundableTokenAmount(uint256 _amount) external;
  function APIGetTimeCreated() public constant returns(uint256);
  function APIGetTokensBought() public constant returns(uint256);
  function APIGetEtherAmount() public constant returns(uint256);
  function APIGetRefundedAmount() public constant returns(uint256);
  function APIGetRefund() external returns(uint256);
}




contract BaseWalletInterface is RemoteWalletInterface {
  function APIGetUnlockedAmount() public constant returns(uint256);
  function APIGetAmount() public constant returns(uint256);
  function APIGetDailyAmount() public constant returns(uint256);
  function APILowerDailyAmount(uint256 _new_daily_amount) external;
  function APISetDailyAmount(uint256 _daily_amount) public returns(bool);
  function APIUnlock(uint256 _amount) public returns(uint256);
  function APIWithdraw(uint256 _amount) public returns(uint256);
  function APIWithdrawTo(uint256 _amount, address _to) public returns(uint256);
}

contract VirtualWalletInterface is BaseWalletInterface {

}


contract TokenStorageInterface is BaseWalletInterface {
  function APISetTokenAmount(uint256 _amount) public returns(bool);
  function APIUpdateTokenAmount() public returns(bool);
}



//A wallet that has permissions to execute a few functions in the master contract, but requires enough votes in order to do so.
contract SuperMajorityInterface is RemoteWalletInterface {
  function _InitOwnerPermissions() internal;
  function _InitParentPermissions() internal;
  function _TMP_GetProposals() external returns(uint256);
  //Cold storage required in order to cast a vote.
  function APICastVote(uint256 _proposal_id, uint256 _option_id) external;
  function APIIsProposalActive(uint256 _proposal_id) external constant returns(bool);
  function APIGetProposalStatus(uint256 _proposal_id) external constant returns(uint256, uint256);
  function APIExecuteProposal(uint256 _proposal_id) external returns(bool);
  function APICreateProposal(string _description, address _target_contract, address _code_contract, string _procedure_name) external returns(uint256);
  function APIGetProposalProcedure(uint256 _proposal_id) external constant returns(string);
  function APIGetProposalDescription(uint256 _proposal_id) external constant returns(string);
  function APIGetProposalStruct1(uint256 _proposal_id) external constant returns(
        uint256 start_time,
        uint256 end_time,
        uint256 duration,
        address creator,
        bool executed,
        bool passed,
        bool open);
  function APIGetProposalStruct2(uint256 _proposal_id) external constant returns(
        address code_contract,
        address target_contract,
        bytes4 procedure_signature,
        uint256 max_weight_per_vote,
        uint256 max_weight);
  function APIGetVoteReceiptStruct(uint256 _receipt_id) external constant returns(
      address voter,
      uint256 proposal_id,
      uint256 vote_option_id,
      uint256 weight,
      uint256 timestamp);
}
  