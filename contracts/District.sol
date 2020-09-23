pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

//import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./VoteToken.sol";
import "./Shared.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract District is Ownable{
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeMath for uint8;
    using SafeMath for uint;

    VoteToken public voteToken;
    uint8 public districtNumber;
    //uint public eligibleVotes ;
    uint public castVotes;
    //uint32 internal uncountedVotes;
    uint8 constant public seats = 5;
    uint8 public seatsFilled;
    uint32 public quota;
    
    //Shared.DistrictResults internal results;
    mapping(address => Shared.Candidate) public candidates;
    address[] public candidateAddresses;
    uint8 public candidatesCount;
    mapping(uint8 => uint64) public party1stCountVotes;
    address[] electedCandidates;
    
    bool public counted = false;

    Shared.DistrictResults internal districtResults;


    event Vote(address _voter, uint8 districtNo, uint castVotes);

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
    
    function setVoteToken(VoteToken _voteToken) external onlyOwner{
        voteToken = _voteToken;
    }
    /*function getVoterTurnout() public view returns(uint){
        return castVotes/eligibleVotes;
    }*/

    function getCandidateAddresses() external view returns(address[] memory){
        return candidateAddresses;
    }
    
    function vote(uint256 tokenId, address[] calldata _preferences) external onlyOwner {
        require(voteToken.district(tokenId) == districtNumber,"Incorrect District");

        for(uint8 i = 0; i < _preferences.length; i++)
            require(candidates[_preferences[i]]._address != address(0), "Voted for candidate not from this district. Vote Rejected.");
        
        voteToken.transferFrom(msg.sender,address(this),tokenId);
        voteToken.setVotePreferences(tokenId, _preferences);
        castVotes += 1;
        emit Vote(msg.sender, districtNumber, castVotes);
    }
    
    
    /*function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4){
        require(voteToken.district(tokenId) == districtNumber,"Incorrect District");

   }*/

   function getAddresses() external view returns(address[] memory) {
       return candidateAddresses;
   }

    /*function getResults() public returns(Shared.DistrictResults memory) {
        require(counted,"Votes have not yet been tallied for this district.");
        return districtResults;
    }*/

   function getQuota() public view returns(uint32){
       //quota = (castVotes/(seats+1)) + 1;
       return uint32((castVotes/(seats + 1)) + 1);
   }


    function getAllElected() external returns(address[] memory){
        if(electedCandidates.length==0){
        
            for(uint8 i = 0; i < candidatesCount; i++){
                if(candidates[candidateAddresses[i]].elected == true)
                    electedCandidates.push(candidates[candidateAddresses[i]]._address);
            }
        
        }
        return electedCandidates;
    }
    
    function kill() external onlyOwner {
        //require(msg.sender == owner);
        selfdestruct(msg.sender);
    }

    function transferAllBack(address _from) private {
        voteToken.transferAllBack(_from);
    }

    function countVotes() external onlyOwner{
        uint8 seatsRemaining = seats; //number of seats which have not yet been filled.
        castVotes = voteToken.balanceOf(address(this));
        quota = getQuota();
        
        for (uint8 j = 1; j <= candidatesCount; j++){ 
            /*the number of candidates being the theoretical maximum preferences a voter can select, and therefore the theoretical maximum possible number of rounds.*/
            bool noMoreRounds = true; 
            //Will remain set to true if it is found that for a given round of counting j, no voter has selected a preference this high, and signal to terminate the counting process.
            bool candidateElected = false; 
            //whether in this round of counting at least one seat has been filled. 
            uint uncountedVotes = voteToken.balanceOf(address(this));
            
            uint8 i=0; 
            /*
            i: "pointer" value which indicates which indicates the index of the token that will be counted, starts at 0 at each round of counting and increases by 1 when a vote is encountered that cannot be
            counted this round.
            Reminder that in ERC721 implementing IERC721enumerable and using the Openzeppelin EnumerableSet library, when a token is removed from an address' balance, the last token in
            the Enumerable list of tokens swaps places with the removed token in the enumerate list, with the last index of the array being popped off, and the arrays length reduced by 1.
            
            When a vote is encountered where the jth preference is a candidate that is elected or eliminated, or not marked; ie their vote will be transferred to the next j+1th
            round of counting, the pointer value i is incremented by 1 for this round and the loop is moved forward one iteration. 
            In the next iteration, the token at index i + 1 will be counted, with the process above repeating itself if this vote also cannot be counted in this round.

            When i becomes == the remaining balance (uncountedVotes) it means there are no more votes left to count this round and the loop will end.
            When the balance is reduced to 0, the inner while loop ends  
            */
            while(uncountedVotes > 0 && i < uncountedVotes){
                uint256 voteTokenID = voteToken.tokenOfOwnerByIndex(address(this),i); 
                /*
                If a vote is uncounted by the jth round of counting, and the voter only marked j-1 preferences,
                ie: the voter's preferences from 1 to j-1 have all been elected or eliminated by the time the vote is counted,
                the vote is said to be non-transferable and is effectively discarded. In reality, it remains in the District contract balance.
                */
                address candidateAddress = voteToken.preferences(voteTokenID,j);
                if(candidateAddress == address(0)){
                    i++;
                    continue;
                }
                else
                    noMoreRounds = false;
 
                if(j==1)
                    party1stCountVotes[candidates[candidateAddress].party] += 1;
                    /*
                    Party 1st count votes balance increases regardless of whether the vote actually ends up at the 1st preference candidate or 
                    is transferred to another candidate, potentially of a different party.
                    */
                
                uint voteBalance = voteToken.balanceOf(candidateAddress);
                
                
                if(voteBalance >= quota-1 && !candidates[candidateAddress].eliminated){
                    voteToken.transferFrom(address(this), candidateAddress, voteTokenID);
                    candidates[candidateAddress].elected = true;
                    candidateElected = true;
                    electedCandidates.push(candidateAddress);
                    uncountedVotes = voteToken.balanceOf(address(this));
                    --seatsRemaining;
                    if(seatsRemaining == 0)
                        break;
                }
                else if(!candidates[candidateAddress].elected && !candidates[candidateAddress].eliminated){
                    voteToken.transferFrom(address(this), candidateAddress, voteTokenID);
                    uncountedVotes = voteToken.balanceOf(address(this));
                }
                else if(candidates[candidateAddress].elected  || candidates[candidateAddress].eliminated ){
                    // move pointer forward
                    i++;
                    continue;
                }
            }
            
            if(noMoreRounds || seatsRemaining == 0) 
                break;
            else if(candidateElected)
                continue;

            /*If no candidate was elected this round of counting, we eliminate candidate with least votes and transfer their votes back to the district contract for next preference counting.*/
            address currentCandidateWithLeastVotes = candidateAddresses[0];
            uint currentLeastVotes = voteToken.balanceOf(currentCandidateWithLeastVotes);
            /*In STV, the candidate to be eliminated is selected randomly if 2 or more candidates are
            tied for least amount of votes; This would be expensive to implement on chain, so to eliminate bias, the addresses passed as candidateAddresses to the District constructor should
            be "shuffled" off-chain before being passed. */
            for (uint8 k = 1; k < candidatesCount; k++){
                uint _balance = voteToken.balanceOf(candidateAddresses[k]);
                address _candidateAddress = candidateAddresses[k];

                if(_balance < currentLeastVotes && !candidates[_candidateAddress].eliminated && !candidates[_candidateAddress].elected ){
                    currentCandidateWithLeastVotes = _candidateAddress;
                    currentLeastVotes = _balance;
                }
            }

            candidates[currentCandidateWithLeastVotes].eliminated = true;
            if(currentLeastVotes>0){
                voteToken.transferAllBack(currentCandidateWithLeastVotes);
                uncountedVotes = voteToken.balanceOf(address(this));
            }
           
            
            
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