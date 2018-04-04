pragma solidity ^0.4.11;


import './Interfaces.sol';
import './SafeMathLib.sol';
import './RemoteWalletLib.sol';


library SuperMajorityLib {
  using SafeMathLib for uint256;
    
  event VoteCasted(uint256 indexed _proposal_id, uint256 _vote_option_id, uint256 _vote_weight);
  event ProposalCreated(uint256 _proposal_id);
  event ProposalExecuted(uint256 indexed _proposal_id);
  
  struct VoteReceipt {
    uint256 id;
    address voter;
    uint256 proposal_id;
    uint256 vote_option_id;
    uint256 weight;
    uint256 timestamp;
  }
  
  struct VoteOption {
    uint256 id;
    bytes32 caption;
    uint256 total_weight;
  }
  
    struct Proposal {
        uint256 id;
        uint256 start_time;
        uint256 end_time;
        address creator;
        uint256 duration;
        bool open;
        address code_contract;
        address target_contract;
        string procedure_name;
        bytes4 procedure_signature;
        bool executed;
        bool passed;
    
        uint256 max_weight_per_vote;
        uint256 max_weight;
    
        mapping(address => uint256) get_vote_receipt;
    
        VoteOption[] vote_options;
    
        string description;
    }
    
    struct SuperMajorityData {
        mapping(uint256 => Proposal) find_proposal_by_id;
      
        VoteReceipt[] vote_receipts;
        Proposal[] proposals;
      
        uint256 unlock_timestamp;
    }
    
  //Credit to Tjaden Hess
  //https://ethereum.stackexchange.com/a/30168
  function log2(uint256 x) returns (uint256 y) {
     assembly {
          let arg := x
          x := sub(x,1)
          x := or(x, div(x, 0x02))
          x := or(x, div(x, 0x04))
          x := or(x, div(x, 0x10))
          x := or(x, div(x, 0x100))
          x := or(x, div(x, 0x10000))
          x := or(x, div(x, 0x100000000))
          x := or(x, div(x, 0x10000000000000000))
          x := or(x, div(x, 0x100000000000000000000000000000000))
          x := add(x, 1)
          let m := mload(0x40)
          mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
          mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
          mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
          mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
          mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
          mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
          mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
          mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
          mstore(0x40, add(m, 0x100))
          let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
          let shift := 0x100000000000000000000000000000000000000000000000000000000000000
          let a := div(mul(x, magic), shift)
          y := div(mload(add(m,sub(255,a))), shift)
          y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
      }
  }
  
  
  function APIExecuteProposal(SuperMajorityData storage self, uint256 _proposal_id) returns(bool) {
    Proposal storage proposal = self.proposals[_proposal_id-1];
    
    require(!proposal.executed);
    require(proposal.passed);
    require(proposal.creator == msg.sender);
    
    RemoteWalletInterface(proposal.target_contract).APISuperMajorityCall(proposal.code_contract, proposal.procedure_signature);
    proposal.executed = true;
    ProposalExecuted(proposal.id);
    
    return proposal.executed;
  }
    
  //Cold storage required in order to cast a vote.
  function APICastVote(SuperMajorityData storage self, RemoteWalletLib.RemoteWalletData storage data, uint256 _proposal_id, uint256 _option_id) {
    require(data.master_contract.HasTokenStorage(msg.sender) || data.master_contract.HasColdStorage(msg.sender)); //Only people with cold storage wallets can vote
    
    Proposal storage proposal = self.proposals[_proposal_id-1];
    require(block.timestamp.add(data.master_contract._TMP_get_time_shift()) < proposal.end_time);
    require(proposal.open);
    require(proposal.get_vote_receipt[msg.sender] == 0);  //Already voted
    require(!proposal.executed);
    require(!proposal.passed);
    
    VoteOption storage vote_option = proposal.vote_options[_option_id-1];
    
    
    uint256 vote_weight = 0;
    uint256 token_amount = 0;
    
    if (data.master_contract.HasTokenStorage(msg.sender)) {
      TokenStorageInterface token_storage = TokenStorageInterface(data.master_contract.GetTokenStorage(msg.sender));
      
      uint256 daily_amount = token_storage.APIGetDailyAmount();
      require(daily_amount > 0);
      token_amount = token_storage.APIGetAmount();
      
      //This algorithm gives more voting weight to those who lock their tokens longer.
      vote_weight = token_amount * (1 + log2(token_amount * token_amount) * log2(token_amount.div(daily_amount)));
      
      if (token_storage.APIGetOwner() == data.master_contract.APIGetOwner()) vote_weight = vote_weight.mul(2); //Foundation token storage wallet
    }
    
    if (data.master_contract.HasColdStorage(msg.sender)) {
      ColdStorageInterface cold_storage = ColdStorageInterface(data.master_contract.GetColdStorage(msg.sender));
      token_amount = cold_storage.APIGetTokensBought();
      
      uint256 lifespan = block.timestamp.add(data.master_contract._TMP_get_time_shift()) - cold_storage.APIGetTimeCreated();
      require(lifespan > 0);
      
      //This algorithm gives more voting weight to those who have been around longer.
      vote_weight = token_amount * (1 + log2(token_amount * token_amount) * (log2(token_amount) - log2(token_amount.div(lifespan))));
    }
    
    proposal.get_vote_receipt[msg.sender] = _Vote(self, data, proposal.id, vote_option.id, vote_weight);
    vote_option.total_weight += vote_weight;
    
    if (!proposal.executed && !proposal.passed && proposal.vote_options[0].total_weight >= proposal.max_weight_per_vote * 75 / 100 && proposal.vote_options[1].total_weight*2 < proposal.vote_options[0].total_weight) {
      proposal.passed = true;
    }
    
    VoteCasted(proposal.id, vote_option.id, vote_weight);
  }
  
  //internal
  function _Vote(SuperMajorityData storage self, RemoteWalletLib.RemoteWalletData storage data, uint256 _proposal_id, uint256 _vote_option_id, uint256 _weight) returns(uint256) {
    self.vote_receipts.length++;
    uint256 new_receipt_id = self.vote_receipts.length;
    VoteReceipt storage receipt = self.vote_receipts[new_receipt_id-1];
    receipt.id = new_receipt_id;
    receipt.voter = msg.sender;
    receipt.proposal_id = _proposal_id;
    receipt.vote_option_id = _vote_option_id;
    receipt.weight = _weight;
    receipt.timestamp = block.timestamp.add(data.master_contract._TMP_get_time_shift());
    return receipt.id;
  }
  
   function APIGetProposalStatus(SuperMajorityData storage self, uint256 _proposal_id) constant returns(uint256, uint256) {
    Proposal storage proposal = self.proposals[_proposal_id-1];
    
    uint256[] memory ret = new uint256[](2);
    ret[0] = proposal.vote_options[0].total_weight;
    ret[1] = proposal.vote_options[1].total_weight;
    
    return (proposal.vote_options[0].total_weight, proposal.vote_options[1].total_weight);
  }
  
  function APIIsProposalActive(SuperMajorityData storage self, RemoteWalletLib.RemoteWalletData storage data, uint256 _proposal_id) constant returns(bool) {
    Proposal storage proposal = self.proposals[_proposal_id-1];
    
    if (!proposal.executed) return true;
    if (block.timestamp.add(data.master_contract._TMP_get_time_shift()) < proposal.end_time) return true;
    return false;
  }
  
   function APICreateProposal(SuperMajorityData storage self, RemoteWalletLib.RemoteWalletData storage data, string _description, address _target_contract, address _code_contract, string _procedure_name) returns(uint256) {
    require(_code_contract != address(0x0));
    require(_target_contract != address(0x0));
    require(_target_contract != _code_contract);
    
    self.proposals.length++;
    uint256 new_proposal_id = self.proposals.length;
    
    uint256 duration = 14;//days
    
    Proposal storage proposal = self.proposals[new_proposal_id-1];
    proposal.id = new_proposal_id;
    proposal.description = _description;
    proposal.start_time = block.timestamp.add(data.master_contract._TMP_get_time_shift());
    proposal.end_time = proposal.start_time + duration * RemoteWalletLib.GetSecondsInADay();
    proposal.creator = msg.sender;
    proposal.duration = duration;
    uint256 days_since_launch = (proposal.start_time - data.master_contract.GetCreationDate()) / RemoteWalletLib.GetSecondsInADay();
    proposal.max_weight = min(days_since_launch+1, 210)*10**9*10**8; //up to 210 billion points
    
    proposal.code_contract = _code_contract;
    proposal.target_contract = _target_contract;
    proposal.procedure_name = _procedure_name; //So that people can see what will get called if vote passes
    proposal.procedure_signature = bytes4(sha3(_procedure_name));
    
    _CreateVoteOption(self, data, proposal.id, "Yes");
    _CreateVoteOption(self, data, proposal.id, "No");
    
    proposal.max_weight_per_vote = proposal.max_weight / proposal.vote_options.length;
    proposal.open = true;
    
    ProposalCreated(new_proposal_id);
    
    return new_proposal_id;
  }

  function _CreateVoteOption(SuperMajorityData storage self, RemoteWalletLib.RemoteWalletData storage data, uint256 _proposal_id, bytes32 _caption) internal returns(uint256) {
    Proposal storage proposal = self.proposals[_proposal_id-1];
    //require(proposal.creator == msg.sender); probably true anyway
    require(!proposal.open); //Not yet fully created, since internal
    require(block.timestamp.add(data.master_contract._TMP_get_time_shift()) < proposal.end_time);
    
    
    proposal.vote_options.length++;
    uint256 new_option_id = proposal.vote_options.length;
    
    VoteOption storage vote_option = proposal.vote_options[new_option_id-1];
    vote_option.id = new_option_id;
    vote_option.caption = _caption;
    
    return new_option_id;
  }

    
  function APIGetProposalStruct1(SuperMajorityData storage self, uint256 _proposal_id) constant returns(
        uint256 start_time,
        uint256 end_time,
        uint256 duration,
        address creator,
        bool executed,
        bool passed,
        bool open)
  {
    Proposal storage proposal = self.proposals[_proposal_id-1];
    return (
        proposal.start_time,
        proposal.end_time,
        proposal.duration,
        proposal.creator,
        proposal.executed,
        proposal.passed,
        proposal.open);
  }
  
  function APIGetProposalStruct2(SuperMajorityData storage self, uint256 _proposal_id) constant returns(
        address code_contract,
        address target_contract,
        bytes4 procedure_signature,
        uint256 max_weight_per_vote,
        uint256 max_weight)
  {
    Proposal storage proposal = self.proposals[_proposal_id-1];
    return (
        proposal.code_contract,
        proposal.target_contract,
        proposal.procedure_signature,
        proposal.max_weight_per_vote,
        proposal.max_weight);
  }
  
  function APIGetVoteReceiptStruct(SuperMajorityData storage self, uint256 _receipt_id) constant returns(
      address voter,
      uint256 proposal_id,
      uint256 vote_option_id,
      uint256 weight,
      uint256 timestamp)
  {
    VoteReceipt storage receipt = self.vote_receipts[_receipt_id-1];
    return (
      receipt.voter,
      receipt.proposal_id,
      receipt.vote_option_id,
      receipt.weight,
      receipt.timestamp);
  }
  
  function max(uint256 a, uint256 b) constant returns (uint256) {
      return (a>b)?a:b;
  }
  
  function min(uint256 a, uint256 b) constant returns (uint256) {
      return !(a>b)?a:b;
  }
}