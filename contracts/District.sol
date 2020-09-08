pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

//import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./VoteToken.sol";
import "./Shared.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract District is Ownable{
    VoteToken internal voteToken;
    uint8 public districtNumber;
    //uint public eligibleVotes ;
    uint32 public castVotes;
    //uint32 internal uncountedVotes;
    uint8 constant public seats = 5;
    uint8 public seatsFilled;
    uint32 public quota;
    
    //Shared.DistrictResults internal results;
    mapping(address => Shared.Candidate) public candidates;
    address[] public candidateAddresses;
    uint8 public candidatesCount;
    mapping(uint8 => uint32) public party1stCountVotes;
    address[] electedCandidates;
    
    bool public counted = false;

    Shared.DistrictResults internal districtResults;


    event Vote(address _voter, uint8 districtNo, uint32 castVotes);

    constructor(uint8 _districtNumber, Shared.Candidate[] memory _candidates/*, VoteToken _voteToken*/) Ownable() public{
        //voteToken = _voteToken;
        districtNumber = _districtNumber;
        //eligibleVotes = _eligibleVotes;
        castVotes = 0;
        candidatesCount = uint8(_candidates.length);
        
        for(uint8 i = 0; i < candidatesCount; i++){
            candidateAddresses.push(_candidates[i]._address);
            candidates[_candidates[i]._address] = _candidates[i];
        }
    }
    
    function setVoteToken(VoteToken _voteToken) public onlyOwner{
        voteToken = _voteToken;
    }
    /*function getVoterTurnout() public view returns(uint){
        return castVotes/eligibleVotes;
    }*/

    function getCandidateAddresses() public view returns(address[] memory){
        return candidateAddresses;
    }
    
    function vote(uint256 tokenId, address[] memory _preferences) public {
        require(voteToken.district(tokenId) == districtNumber,"Incorrect District");
        for(uint8 i = 0; i < _preferences.length; i++)
            require(candidates[_preferences[i]]._address != address(0), "Voted for candidate not from this district. Vote Rejected.");
//WRITE TEST FOR ABOVE LINE ^^^
        voteToken.transferFrom(msg.sender,address(this),tokenId);
        voteToken.setVotePreferences(tokenId, _preferences);
        castVotes += 1;
        emit Vote(msg.sender, districtNumber, castVotes);
    }
    
    
    /*function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4){
        require(voteToken.district(tokenId) == districtNumber,"Incorrect District");

   }*/

   function getAddresses() public view returns(address[] memory) {
       return candidateAddresses;
   }

    /*function getResults() public returns(Shared.DistrictResults memory) {
        require(counted,"Votes have not yet been tallied for this district.");
        return districtResults;
    }*/

   function getQuota() public view returns(uint32){
       //quota = (castVotes/(seats+1)) + 1;
       return (castVotes/(seats+1)) + 1;
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
    
    function kill() public onlyOwner {
        //require(msg.sender == owner);
        selfdestruct(msg.sender);
    }

    function transferAllBack(address _from) public {
        voteToken.transferAllBack(_from);
    }

    function countVotes() public{
        uint8 seatsRemaining = seats; //number of seats which have not yet been filled.
        castVotes = uint32(voteToken.balanceOf(address(this)));
        //uncountedVotes = castVotes;
        quota = getQuota();
        

        for (uint8 j = 1; j <= candidatesCount; j++){ //the number of candidates being the theoretical maximum preferences a voter can select.
            bool noMoreRounds = true; //will be set to false if it is found that for a given preference number j, no voter has selected a preference this high, and signal to terminate the counting process.
            bool candidateElected = false; 
            //whether in this round of counting at least one seat has been filled. 

            uint32 uncountedVotes = uint32(voteToken.balanceOf(address(this)));
            uint256[] memory voteTokenIDs = new uint256[](uncountedVotes);

            for (uint32 i = 0; i < uncountedVotes; i++){
                uint256 voteTokenID = voteToken.tokenOfOwnerByIndex(address(this),i);
                voteTokenIDs[i] = voteTokenID;
            }

            for (uint32 i = 0; i < voteTokenIDs.length; i++){
                //uint256 voteTokenID = voteToken.tokenOfOwnerByIndex(address(this),i);
                uint256 voteTokenID = voteTokenIDs[i];

                address candidateAddress = voteToken.preferences(voteTokenID,j);
                if(candidateAddress == address(0))
                    break;
                else
                    noMoreRounds = false;
                
               /* else
                    noMoreRounds = false;*/

                if(j==1)
                    party1stCountVotes[candidates[candidateAddress].party] += 1;
                
                uint32 voteBalance = uint32(voteToken.balanceOf(candidateAddress));
                
                
                if(voteBalance == quota-1 && candidates[candidateAddress].eliminated == false){
                    voteToken.transferFrom(address(this), candidateAddress, voteTokenID);
                    candidates[candidateAddress].elected = true;
                    candidateElected = true;
                    electedCandidates.push(candidateAddress);
                    if(--seatsRemaining == 0)
                        break;
                }
                else if(candidates[candidateAddress].elected == false && candidates[candidateAddress].eliminated == false){
                    voteToken.transferFrom(address(this), candidateAddress, voteTokenID);
                }
                else if(candidates[candidateAddress].elected == true || candidates[candidateAddress].eliminated == true){
                    continue;
                }
                voteBalance = uint32(voteToken.balanceOf(candidateAddress));
                /*
                else {
                    if(voteBalance < currentLeastVotes){
                        currentLeastVotes = voteBalance;
                        currentCandidateWithLeastVotes = candidateAddress;
                    }
                    continue;
                }
                
                if(voteBalance+1 < currentLeastVotes || currentLeastVotes == -1){
                        currentLeastVotes = voteBalance+1;
                        currentCandidateWithLeastVotes = candidateAddress;
                    }
                   */
            }    
            
            if(noMoreRounds || seatsRemaining == 0) 
                break;
            else if(candidateElected)
                continue;

            /*If no candidate was elected this round of counting, we eliminate candidate with least votes and transfer their votes back to the district contract for next preference counting.*/
            address currentCandidateWithLeastVotes = candidateAddresses[0];
            uint32 currentLeastVotes = uint32(voteToken.balanceOf(currentCandidateWithLeastVotes));
            /*In STV, the candidate to be eliminated is selected randomly if 2 or more candidates are
            tied for least amount of votes; This would be expensive to implement on chain, so to eliminate bias, the addresses passed as candidateAddresses to the District constructor should
            be "shuffled" off-chain before being passed. */
            for (uint8 k = 1; k < candidatesCount; k++){
                uint32 _balance = uint32(voteToken.balanceOf(candidateAddresses[k]));
                address _candidateAddress = candidateAddresses[k];

                if(_balance < currentLeastVotes && candidates[_candidateAddress].eliminated == false && candidates[_candidateAddress].elected ==false ){
                    currentCandidateWithLeastVotes = _candidateAddress;
                    currentLeastVotes = _balance;
                }
            }

            candidates[currentCandidateWithLeastVotes].eliminated = true;
            if(currentLeastVotes>0)
                voteToken.transferAllBack(currentCandidateWithLeastVotes);
           
            
            
        }
        
        seatsFilled = seats - seatsRemaining;

        for(uint8 i = 0; i<candidateAddresses.length; i++){
            candidates[candidateAddresses[i]].votes = uint32(voteToken.balanceOf(candidateAddresses[i]));
            districtResults.candidateResults.push(candidates[candidateAddresses[i]]);
        }

        uint8 k = 0;
        while(party1stCountVotes[k]>0){
            districtResults.party1stCountVotes = new uint8[](Shared.parties);
            districtResults.party1stCountVotes[k] = party1stCountVotes[k++];
        }


        counted = true;
    }
}