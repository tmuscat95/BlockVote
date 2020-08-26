pragma solidity ^0.6.0;
import "./VoteToken.sol";
import "./District.sol";


library Shared {
    
    struct Candidate{
        address _address;
        uint8 party;
        uint8 district;
        
        bool elected;
        bool eliminated;
        //uint votes;
    }
    
    /*struct DistrictResults {
        uint8 districtNo;
        
        mapping(address => Candidate) candidateResults;
        mapping(uint8 => uint) party1stCountVotes;
    }*/
    
    
    struct Election{
        string name;
        uint voteStart;
        uint voteEnd;
        VoteToken voteToken;
        
        mapping(uint8 => uint32) party1stCountVotes;
        //mapping(uint8 => DistrictResults) districtResults;
        mapping(uint8 => District) districtContracts;
    }
   
    
}