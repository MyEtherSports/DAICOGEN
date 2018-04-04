pragma solidity ^0.4.11;


import './Interfaces.sol';
import './RemoteWallet.sol';
import './SuperMajorityLib.sol';

/*
A wallet that has permissions to execute anything in foundation owner contracts, but requires enough votes in order to do so.
This contract is assigned to the master contract as supermajority_group and has certain permissions to call certain functions.
It has authority to upgrade itself if supermajority vote is reached, making other proposals in the old one rendered useless.
*/

contract SuperMajority is SuperMajorityInterface, RemoteWallet {
  
  SuperMajorityLib.SuperMajorityData sm_data;
  
  event VoteCasted(uint256 indexed _proposal_id, uint256 _vote_option_id, uint256 _vote_weight);
  event ProposalCreated(uint256 _proposal_id);
  event ProposalExecuted(uint256 indexed _proposal_id);
  
  modifier IsValidProposalID(uint256 _proposal_id) {
    require(_proposal_id > 0 && _proposal_id <= sm_data.proposals.length);
    if (true) {
      _;
    }
  }
  
  modifier IsValidVoteOptionID(uint256 _option_id) {
    require((_option_id > 0 && _option_id <= 2));
    if (true) {
      _;
    }
  }
  
  modifier IsValidReceiptID(uint256 _receipt_id) {
    require(_receipt_id > 0 && _receipt_id <= sm_data.vote_receipts.length);
    if (true) {
      _;
    }
  }
  
  
  function SuperMajority(address _parent, address _owner, uint256 _unlock_in) RemoteWallet(_parent, _owner) {
    sm_data.unlock_timestamp = block.timestamp.add(data.master_contract._TMP_get_time_shift()) + _unlock_in * RemoteWalletLib.GetSecondsInADay(); //TODO: remove timeshift
    data.wallet_type = 4;
  }
  
  function _InitOwnerPermissions() internal {
    super._InitOwnerPermissions();
    
    //Anyone can call these, contract will be self owned
    _SetPermissionBySig(bytes4(sha3("APICastVote(uint256,uint256)")), address(0x0), true, false);
    _SetPermissionBySig(bytes4(sha3("APICreateAction(address,string)")), address(0x0), true, false);
    _SetPermissionBySig(bytes4(sha3("APICreateProposal(string,address,address,string)")), address(0x0), true, false);
    _SetPermissionBySig(bytes4(sha3("APIExecuteProposal(uint256)")), address(0x0), true, false);
  }
  
  function _InitParentPermissions() internal {
    super._InitParentPermissions();
    
    //Anyone can call these, parent is artificial
    _SetPermissionBySig(bytes4(sha3("APICastVote(uint256,uint256)")), address(0x0), true, false);
    _SetPermissionBySig(bytes4(sha3("APICreateAction(address,string)")), address(0x0), true, false);
    _SetPermissionBySig(bytes4(sha3("APICreateProposal(string,address,address,string)")), address(0x0), true, false);
    _SetPermissionBySig(bytes4(sha3("APIExecuteProposal(uint256)")), address(0x0), true, false);
  }
  
  
  function _TMP_GetProposals() external returns(uint256) {
    return sm_data.proposals.length;
  }
  
  //Cold storage required in order to cast a vote.
  function APICastVote(uint256 _proposal_id, uint256 _option_id) external TimeLocked(sm_data.unlock_timestamp) IsValidProposalID(_proposal_id) IsValidVoteOptionID(_option_id) RestrictedCall()  {
    return SuperMajorityLib.APICastVote(sm_data, data, _proposal_id, _option_id);
  }
  
  function APIIsProposalActive(uint256 _proposal_id) external constant returns(bool) {
    return SuperMajorityLib.APIIsProposalActive(sm_data, data, _proposal_id);
  }
  
  function APIGetProposalStatus(uint256 _proposal_id) external constant IsValidProposalID(_proposal_id) returns(uint256, uint256) {
    return SuperMajorityLib.APIGetProposalStatus(sm_data, _proposal_id);
  }
  
  
  function APICreateProposal(string _description, address _target_contract, address _code_contract, string _procedure_name) external RestrictedCall() TimeLocked(sm_data.unlock_timestamp) returns(uint256) {
    return SuperMajorityLib.APICreateProposal(sm_data, data, _description, _target_contract, _code_contract, _procedure_name);
  }
  
  function APIExecuteProposal(uint256 _proposal_id) external IsValidProposalID(_proposal_id) RestrictedCall() returns(bool) {
    return SuperMajorityLib.APIExecuteProposal(sm_data, _proposal_id);
  }
  
  function APIGetProposalProcedure(uint256 _proposal_id) external IsValidProposalID(_proposal_id) constant returns(string) {
    SuperMajorityLib.Proposal storage proposal = sm_data.proposals[_proposal_id-1];
    return proposal.procedure_name;
  }
  
  function APIGetProposalDescription(uint256 _proposal_id) external IsValidProposalID(_proposal_id) constant returns(string) {
    SuperMajorityLib.Proposal storage proposal = sm_data.proposals[_proposal_id-1];
    return proposal.description;
  }
  
  function APIGetProposalStruct1(uint256 _proposal_id) external IsValidProposalID(_proposal_id) constant returns(
        uint256 start_time,
        uint256 end_time,
        uint256 duration,
        address creator,
        bool executed,
        bool passed,
        bool open)
  {
    return SuperMajorityLib.APIGetProposalStruct1(sm_data, _proposal_id);
  }
  
  function APIGetProposalStruct2(uint256 _proposal_id) external IsValidProposalID(_proposal_id) constant returns(
        address code_contract,
        address target_contract,
        bytes4 procedure_signature,
        uint256 max_weight_per_vote,
        uint256 max_weight)
  {
    return SuperMajorityLib.APIGetProposalStruct2(sm_data, _proposal_id);
  }
  
  function APIGetVoteReceiptStruct(uint256 _receipt_id) external IsValidReceiptID(_receipt_id) constant returns(
      address voter,
      uint256 proposal_id,
      uint256 vote_option_id,
      uint256 weight,
      uint256 timestamp)
  {
    return SuperMajorityLib.APIGetVoteReceiptStruct(sm_data, _receipt_id);
  }
  
  
}