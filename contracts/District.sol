pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./VoteToken.sol";
import "./Shared.sol";

contract District is IERC721Receiver{
    VoteToken internal voteToken;
    uint8 internal districtNumber;
    //uint public eligibleVotes ;
    uint32 public castVotes;
    uint32 internal uncountedVotes;
    uint8 constant public seats = 5;
    uint32 public quota;
    
    //Shared.DistrictResults internal results;
    mapping(address => Shared.Candidate) public candidates;
    address[] public candidateAddresses;
    uint8 public candidatesCount;
    mapping(uint8 => uint) public party1stCountVotes;
    address[] electedCandidates;
    
    constructor(uint8 _districtNumber, Shared.Candidate[] memory _candidates, VoteToken _voteToken) public{
        voteToken = _voteToken;
        districtNumber = _districtNumber;
        //eligibleVotes = _eligibleVotes;
        castVotes = 0;
        candidatesCount = uint8(_candidates.length);
        
        for(uint8 i = 0; i < candidatesCount; i++){
            candidateAddresses.push(_candidates[i]._address);
            candidates[_candidates[i]._address] = _candidates[i];
        }
    }
    
    /*function getVoterTurnout() public view returns(uint){
        return castVotes/eligibleVotes;
    }*/
    
    function vote(uint256 _tokenId, address[] memory _preferences) public{
        
        voteToken.approve(address(this),_tokenId);
        voteToken.transferFrom(msg.sender,address(this),_tokenId);
        voteToken.setVotePreferences(_tokenId, _preferences);
        castVotes += 1;
    }
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4){
        require(voteToken.district(tokenId) == districtNumber,"Incorrect District");

   }

   function getQuota() internal returns(uint32){
       quota = (castVotes/(seats+1)) + 1;
       return quota;
   }
    
    function getAllElected() public returns(address[] memory){
        if(electedCandidates.length==0){
        
            for(uint8 i = 0; i < candidatesCount; i++){
                if(candidates[candidateAddresses[i]].elected == true)
                    electedCandidates.push(candidates[candidateAddresses[i]]._address);
            }
        
        }
        return electedCandidates;
    }
    
    function count() external{
        castVotes = uint32(voteToken.balanceOf(address(this)));
        uncountedVotes = castVotes;
        quota = getQuota();
        address currentCandidateWithLeastVotes;
        uint32 currentLeastVotes;
        
        for (uint8 j = 1; j <= candidatesCount; j++){ //the number of candidates being the theoretical maximum preferences a voter can select.
            uncountedVotes = uint32(voteToken.balanceOf(address(this)));
            
            for (uint i = 0; i < uncountedVotes; i++){
                uint256 voteTokenID = voteToken.tokenOfOwnerByIndex(address(this),i);
                
                address candidateAddress = voteToken.preferences(voteTokenID,j);
                if(j==1)
                    party1stCountVotes[candidates[candidateAddress].party] += 1;
                   
                uint32 voteBalance = uint32(voteToken.balanceOf(candidateAddress));
                
                
                if(voteBalance == quota-1 && candidates[candidateAddress].eliminated == false){
                    voteToken.transferFrom(address(this), candidateAddress, voteTokenID);
                    candidates[candidateAddress].elected = true;
                }
                else if(candidates[candidateAddress].elected == false && candidates[candidateAddress].eliminated == false){
                    voteToken.transferFrom(address(this), candidateAddress, voteTokenID);
                }
                else{
                    if(voteBalance < currentLeastVotes){
                        currentLeastVotes = voteBalance;
                        currentCandidateWithLeastVotes = candidateAddress;
                    }
                    continue;
                }
                
                if(voteBalance+1 < currentLeastVotes){
                        currentLeastVotes = voteBalance+1;
                        currentCandidateWithLeastVotes = candidateAddress;
                    }
            }    
            
            candidates[currentCandidateWithLeastVotes].eliminated = true;
            voteToken.transferAllBack(currentCandidateWithLeastVotes);
           
            
        }
        
        for (uint32 i = 0; i < castVotes; i++){
            uint256 voteTokenID = voteToken.tokenOfOwnerByIndex(address(this),i);
            
            for (uint8 j = 1; j <= candidatesCount; j++){ //the number of candidates being the theoretical maximum preferences a voter can select.
                
                address candidateAddress = voteToken.preferences(voteTokenID,j);
                if(j==1)
                    party1stCountVotes[candidates[candidateAddress].party] += 1;
                
                if(voteToken.balanceOf(candidateAddress) == quota-1){
                    voteToken.transferFrom(address(this), candidateAddress, voteTokenID);
                    candidates[candidateAddress].elected = true;
                }
                else if(candidates[candidateAddress].elected == false){
                    voteToken.transferFrom(address(this), candidateAddress, voteTokenID);
                }
                else
                    continue;
                    
                
                    
            }
        }
    }
}