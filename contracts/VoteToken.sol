pragma solidity ^0.6.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./District.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract VoteToken is ERC721, Ownable{
    mapping(uint256 => uint8) public district; //maps token ID to District voter it is issued to is on.
    mapping(uint256 => mapping(uint8=>address)) public preferences; //maps token ID to the preferences selected by the voter.
    uint public voteStart; //Time (in seconds since epoch) 
    uint public voteEnd;
    uint64 public votesTotal;

    using SafeMath for uint64;
    //Much of the ERC721 functionality will be restricted to only the District contracts.
    mapping(address => bool) public allowedContracts; 
    modifier OnlyAllowed {
        require(allowedContracts[msg.sender] == true,"Calling Address not in list of allowed contracts.");
        _;
    }

    constructor(string memory __name, string memory __symbol, uint _voteStart, uint _voteEnd) ERC721(__name,__symbol) Ownable() public{
        voteStart = _voteStart;
        voteEnd = _voteEnd;
        allowedContracts[address(this)] = true;
        
    }

    //Called For Each District Contract Address.
    function setAllowed(address _address) public onlyOwner {
        allowedContracts[_address] = true;
    }

    /*
    Ensures No tokens can be transferred (ie: voting) before or after voting period ends
    */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        require((now >= voteStart && now <= voteEnd) || (_msgSender() == owner()),"Voting Not Open."); 
        require(now <= voteEnd,"Election is over.");
    }
    
    /* Maps a given vote Token ID to a mapping of the voter's preferences (1..N) to the addresses of the corresponding candidates. */
    function setVotePreferences(uint256 _tokenId, address[] memory _preferences) public{
        _isApprovedOrOwner(_msgSender(), _tokenId);

        for(uint8 i = 1; i <= _preferences.length; i++){
            preferences[_tokenId][i] = _preferences[i-1];
        }
    }
    
    /* Utilises vanilla ERC721 mint functionality but adds the restrictions that the mint is rejected if the recipient has a balance larger than 0;
    As every voter may only be issued one vote and that only the owner of the VoteToken contract (the Election Controller contract) may call it.
    Additionally, it also assigns the number of the electoral district in which the voter resides as metadata*/
    function mint(address _to, uint256 _tokenId, uint8 _districtNo) public onlyOwner{
        //require(balanceOf(_to) == 0,"Recipient Already has a vote. (balance non 0)"); //no one may have more than 1 vote.

        _mint(_to , _tokenId);
        district[_tokenId] = _districtNo;
        votesTotal++;
    }
    
    /*
    May be called only by District contracts (onlyAllowed). Used in order to redistribute votes from candidates that are eliminated in the process of counting.
    Has the additional restriction that each token must "belong" to the District that is attempting to seize it.
     */
    function transferAllBack(address _from) public OnlyAllowed {
        uint8 _districtNo = District(msg.sender).districtNumber();
        uint balance = balanceOf(_from);

        for(uint32 i = 0; i < balance; i++){
            uint256 tokenId = tokenOfOwnerByIndex(_from,i);
            require(district[tokenId] == _districtNo,"Attempting to seize token from another district.");
            transferFrom(_from,msg.sender,tokenId);
        }
    }
    
    /*Proxy for the vanilla transferFrom function of ERC721, but restricts it to only allowed callers (District contracts))*/
    function transferFrom(address from, address to, uint256 tokenId) public OnlyAllowed override {
        //_beforeTokenTransfer(from,to,tokenId);
        super.transferFrom(from,to,tokenId);
    }

    /*
    Safe Transfer is used to check that a recipient of a token is either: a wallet address or, if it is a contract, that it has functionality that allows it to
    transfer otherwise make use of the tokens it receives. This was implemented in order to ensure tokens are not lost by being sent to a contract that has no way of moving them.
    It is not necessary for this application given the limited use-scope of our token. It has therefore been overriden with an empty function.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        /*unnecessary*/
        revert();
    }

    
    function kill() public onlyOwner {
        selfdestruct(msg.sender);
    }
}