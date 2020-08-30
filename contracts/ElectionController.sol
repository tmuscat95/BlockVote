pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./VoteToken.sol";
import "./Shared.sol";
import "./District.sol";
import "./DistrictFactory.sol";
import "./VoteTokenFactory.sol";


contract ElectionController is Ownable{
    Shared.Election[] internal elections;
    uint8 public districtsNo;
    DistrictFactory districtFactory;
    VoteTokenFactory voteTokenFactory;
    
    constructor(uint8 _districtsNo, DistrictFactory _districtFactory, VoteTokenFactory _voteTokenFactory) Ownable() public payable{
        districtsNo = _districtsNo;
        districtFactory = _districtFactory;
        voteTokenFactory = _voteTokenFactory;
    }
    
    function launchElection(
        string memory _name,
        uint _voteStart,
        uint _voteEnd,
        Shared.Candidate[][] memory candidates//, //first dimension index is the district number - 1
        //uint32[] memory districtEligibleVotes
        ) public onlyOwner{
        
        elections.push(Shared.Election({name: _name, voteStart: _voteStart, voteEnd: _voteEnd, voteToken: voteTokenFactory.create(_name,_voteStart,_voteEnd)}));
        
        for(uint8 i = 1 ; i <= districtsNo; i++){
            elections[elections.length-1].districtContracts[i] = districtFactory.create(i, candidates[i-1]/*, elections[elections.length-1].voteToken*/);
            elections[elections.length-1].voteToken.setAllowed(address(elections[elections.length-1].districtContracts[i]));
            elections[elections.length-1].districtContracts[i].setVoteToken(elections[elections.length-1].voteToken);
        }
 
    }
    
    function mintVote(address _to, uint256 _tokenId, uint8 _districtNo, uint32 _electionNo) public {
        elections[_electionNo].voteToken.mint(_to, _tokenId, _districtNo);
    }
    
    function endElection(uint32 _electionNo) public onlyOwner returns(uint8){
        Shared.Election storage election = elections[_electionNo]; //storage in order to copy by reference.
        uint8 partyWithMostVotesIndex;
        uint32 mostVotes;
        
        for(uint8 i = 1; i <= districtsNo; i++){
            election.districtContracts[i].count();
            //election.districtContracts[i].getAllElected();
            
            for(uint8 j = 0; ; j++){
                
                uint32 _votes = uint32(election.districtContracts[i].party1stCountVotes(j));
                
                if(_votes == 0)
                    break;
                
                election.party1stCountVotes[j] += _votes;
                if(election.party1stCountVotes[j] > mostVotes){
                    mostVotes = election.party1stCountVotes[j];
                    partyWithMostVotesIndex = j;
                }
            }
        }
        
        return partyWithMostVotesIndex;
    }
    
}