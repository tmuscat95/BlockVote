pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./VoteToken.sol";
import "./Shared.sol";
import "./District.sol";
import "./DistrictFactory.sol";
import "./VoteTokenFactory.sol";


contract ElectionController is Ownable{

    Shared.Election[] public elections;
    uint8 public districtsNo;
    DistrictFactory internal districtFactory;
    VoteTokenFactory internal voteTokenFactory;
    
    constructor(uint8 _districtsNo, DistrictFactory _districtFactory, VoteTokenFactory _voteTokenFactory) Ownable() public payable{
        districtsNo = _districtsNo;
        districtFactory = _districtFactory;
        voteTokenFactory = _voteTokenFactory;
    }

    function endElection(uint8 _electionNo) external{
        //Shared.Election storage election = elections[_electionNo]; //storage in order to copy by reference.
        uint8 partyWithMostVotesIndex;
        uint32 mostVotes;
        
        for(uint8 i = 1; i <= districtsNo; i++){
            //require(election.districtContracts[i].counted() == true, string(abi.encodePacked("Hasn't Counted Yet: ",i)));
            elections[_electionNo].districtContracts[i].countVotes();
            require(elections[_electionNo].districtContracts[i].counted() == true, string(abi.encodePacked("Counting failed for district: ",i)));
            //election.districtContracts[i].getAllElected();
            
            for(uint8 j = 0; j < elections[_electionNo].numberOfPartiesContesting ;j++){
                
                uint32 _votes = uint32(elections[_electionNo].districtContracts[i].party1stCountVotes(j));
                
                /*if(_votes == 0)
                    break;*/
                
                elections[_electionNo].party1stCountVotes[j] += _votes;
                if(elections[_electionNo].party1stCountVotes[j] > mostVotes){
                    mostVotes = elections[_electionNo].party1stCountVotes[j];
                    partyWithMostVotesIndex = j;
                }
            }
        }
        
        elections[_electionNo].partyWithMostVotesIndex = partyWithMostVotesIndex;
        elections[_electionNo].concluded = true;
    }
    
    function launchElection (
        string memory _name,
        uint _voteStart,
        uint _voteEnd,
        uint8 numberOfPartiesContesting,
        Shared.Candidate[][] memory candidates
        ) public onlyOwner{

        VoteToken _voteToken = voteTokenFactory.create(_name,_voteStart,_voteEnd);
        elections.push(Shared.Election({name: _name, voteStart: _voteStart, voteEnd: _voteEnd, voteToken: _voteToken, concluded:false, partyWithMostVotesIndex:255, numberOfPartiesContesting: uint8(candidates.length)}));
        
        
        for(uint8 i = 1 ; i <= districtsNo; i++){
            District d = districtFactory.create(i, candidates[i-1]);
            elections[elections.length-1].voteToken.setApprovalForAll(address(d),true);
            elections[elections.length-1].districtContracts[i] = d;
            elections[elections.length-1].voteToken.setAllowed(address(elections[elections.length-1].districtContracts[i]));
            elections[elections.length-1].districtContracts[i].setVoteToken(elections[elections.length-1].voteToken);
        
        }
 
    }

    function vote(uint8 _electionNo, uint256 _voteTokenID, address[] memory _preferences) public onlyOwner {
        uint8 districtNo = elections[_electionNo].voteToken.district(_voteTokenID);
        require(districtNo != 0,"Invalid Vote Token.");
        District _district = elections[_electionNo].districtContracts[districtNo];
        //voteToken.setApprovalForAll(_district,true);
        _district.vote(_voteTokenID,_preferences);

    }
    
    function balanceOf(address _address, uint16 _election) public view returns(uint256){
        return elections[_election].voteToken.balanceOf(_address);
    }

    function getDistrictCandidateAddresses(uint8 _election,uint8 _district)  public view returns(address[] memory){
        address[] memory addresses = elections[_election].districtContracts[_district].getCandidateAddresses();
        return addresses;
    }

    function getDistrictContract(uint8 _election, uint8 _district) public view returns(District){
        return elections[_election].districtContracts[_district];
    }

    function mintVote(uint256 _tokenId, uint8 _districtNo, uint32 _electionNo) public onlyOwner {
        elections[_electionNo].voteToken.mint(address(this), _tokenId, _districtNo);

    }
    
}