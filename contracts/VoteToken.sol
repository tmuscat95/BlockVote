pragma solidity ^0.6.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./District.sol";

contract VoteToken is ERC721, Ownable{
    mapping(uint256 => uint8) public district;
    mapping(uint256 => mapping(uint8=>address)) public preferences;
    uint public voteStart;
    uint public voteEnd;
    mapping(address => bool) public allowedContracts;
    
    modifier OnlyAllowed {
        require(allowedContracts[msg.sender] == true || msg.sender == owner(),"Calling Address not in list of allowed contracts.");
        _;
    }

    constructor(string memory __name, string memory __symbol, uint _voteStart, uint _voteEnd) ERC721(__name,__symbol) Ownable() public{
        voteStart = _voteStart;
        voteEnd = _voteEnd;
        allowedContracts[address(this)] = true;
    }

    function kill() public onlyOwner {
        //require(msg.sender == owner);
        selfdestruct(msg.sender);
    }
    
    function setAllowed(address _address) public onlyOwner {
        allowedContracts[_address] = true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override { 
        require( ( (now >= voteStart && now <= voteEnd) || (_msgSender() == owner() && now <= voteEnd) ),"Voting Not Open."); //necessary to ensure minting of tokens is possible before voting starts.
    }
    
    function setVotePreferences(uint256 _tokenId, address[] memory _preferences) public{
        _isApprovedOrOwner(_msgSender(), _tokenId);

        for(uint8 i = 1; i <= _preferences.length; i++){
            preferences[_tokenId][i] = _preferences[i-1];
        }
    }
    
    function mint(address _to, uint256 _tokenId, uint8 _districtNo) public onlyOwner{
        require(balanceOf(_to) == 0,"Recipient Already has a vote. (balance non 0)"); //no one may have more than 1 vote.
        _mint(_to , _tokenId);
        district[_tokenId] = _districtNo;
    }
    
    function transferAllBack(address _from) public OnlyAllowed {
        uint8 _districtNo = District(msg.sender).districtNumber();
        uint balance = balanceOf(_from);

        for(uint32 i = 0; i < balance; i++){
            uint256 tokenId = tokenOfOwnerByIndex(_from,i);
            require(district[tokenId] == _districtNo,"Attempting to seize token from another district.");
            transferFrom(_from,msg.sender,tokenId);
        }
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public OnlyAllowed override {
        
        super.transferFrom(from,to,tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {}
}