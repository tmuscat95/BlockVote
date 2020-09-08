pragma solidity ^0.6.0;
import "./VoteToken.sol";
import "./District.sol";


library Shared {
    uint8 constant parties = 2;
    struct Candidate{
        address _address;
        uint8 party;
        uint8 districtNo;
        
        bool elected;
        bool eliminated;
        
        uint32 votes;
    }
    
    struct DistrictResults {
        uint8 districtNo;
        
        Candidate[] candidateResults;
        uint32[] party1stCountVotes;
    }
    
    
    struct Election{
        mapping(uint8 => District) districtContracts;
        string name;
        uint voteStart;
        uint voteEnd;
        VoteToken voteToken;
        bool concluded;
        uint8 partyWithMostVotesIndex;
        uint8 numberOfPartiesContesting;
        
        mapping(uint8 => uint32) party1stCountVotes;
        //mapping(uint8 => DistrictResults) districtResults;
        
    }
   
    
}