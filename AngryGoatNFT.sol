// SPDX-License-Identifier: GPL-3.0

// Thanks to HashLips
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AngryGoatNFT is ERC721Enumerable, Ownable {
  using Strings for uint256;
  
  string public baseURI = "https://angrygoats.io/api/";
  string public baseExtension = "";
  string public notRevealedUri = "https://angrygoats.io/comingsoon.json";
  uint256 public cost = 0.10 ether;
  uint256 public cost_3 = 0.08 ether;
  uint256 public cost_10 = 0.07 ether;
  uint256 public self_whitelist = 0.01 ether;
  uint256 public maxSupply = 6047;
  uint256 public nftPerAddressLimit = 100;
  address payable public payments;
  bool public paused = false;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  address[] public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;
    
  constructor(
    string memory _name,
    string memory _symbol,
    address _payments
  ) ERC721(_name, _symbol) {
    payments = payable(_payments);
  }
  
  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
    
    if (msg.sender != owner()) {
        require(!paused, "the contract is not active yet");
        require(_mintAmount <= nftPerAddressLimit, "max mint amount per session exceeded");
        uint256 _cost = cost;
        if(_mintAmount >= 3 && _mintAmount <= 9) {
           _cost = cost_3;
        }
        if(_mintAmount >= 10) {
           _cost = cost_10;
        }
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "user is not whitelisted");
            require(ownerMintedCount + _mintAmount <= 20, "max early access NFT per address exceeded");
        }
        require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
        require(msg.value >= _cost * _mintAmount, "insufficient funds");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }
  
  function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
  return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner() {
      revealed = true;
  }
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner() {
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }
  
  function setCostThree(uint256 _newCost) public onlyOwner() {
    cost_3 = _newCost;
  }
  
  function setCostTen(uint256 _newCost) public onlyOwner() {
    cost_10 = _newCost;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }
  
  function whitelistUser(address wallet) public onlyOwner {
    whitelistedAddresses.push(wallet);
  }
  
  function whitelistAddress() public payable  {
    require(whitelistedAddresses.length <= 149, "Early Access limit reached");  
    require(msg.value >= self_whitelist, "insufficient funds");
    (bool success, ) = payable(payments).call{value: self_whitelist}("");
    require(success);
    whitelistedAddresses.push(msg.sender);
  }
 
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(payments).call{value: address(this).balance}("");
    require(success);
  }
  
  function breedable(uint256 tokenId) public pure returns (bool) {
    if((tokenId % 9) == 1){
         return true;
    }
    return false;
  }
  
}
