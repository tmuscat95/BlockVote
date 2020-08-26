pragma solidity ^0.6.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VoteToken is ERC721, Ownable{
    mapping(uint256 => uint8) public district;
    mapping(uint256 => mapping(uint8=>address)) public preferences;
    uint public voteStart;
    uint public voteEnd;
    
    
    constructor(string memory name, string memory symbol, uint _voteStart, uint _voteEnd) ERC721(name,symbol) Ownable() public{
        voteStart = _voteStart;
        voteEnd = _voteEnd;
    }
    
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override { 
        require((now >= voteStart && now <= voteEnd) || (msg.sender == owner() && now <= voteEnd)); //necessary to ensure minting of tokens is possible before voting starts.
    }
    
    function setVotePreferences(uint256 _tokenId, address[] memory _preferences) public{
        for(uint8 i = 1; i <= _preferences.length; i++){
            preferences[_tokenId][i] = _preferences[i-1];
        }
    }
    
    function mint(address _to, uint256 _tokenId, uint8 _districtNo) public onlyOwner{
        require(balanceOf(_to) == 0); //no one may have more than 1 vote.
        _mint(_to , _tokenId);
        district[_tokenId] = _districtNo;
    }
    
    function transferAllBack(address _from) public onlyOwner {
        uint balance = balanceOf(_from);
        
        for(uint32 i = 0; i < balance; i++){
            uint256 tokenId = tokenOfOwnerByIndex(_from,i);
            transferFrom(_from, msg.sender,tokenId);
        }
    }
    
}