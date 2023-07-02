// contracts/HOW3Domain.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract NoobsTender is Ownable,ERC721, ERC721URIStorage {

  /** STRUCTS */
  struct CompanyDetails {
    bytes companyName;
    bytes companyDIN;
    address owner;
    uint256 tokenId;
    uint256 tenderIdApplied;
    uint256 priceBid;
  }

  /** CONSTANTS */
  bytes1 public constant BYTES_DEFAULT_VALUE = bytes1(0x00);
  bytes public tenderName;
  uint256 public tenderId;
  uint public tenderStart;
  uint public tenderTime;
  uint256 public winner = 0;

  /** STATE VARIABLES */
  mapping(bytes32 => CompanyDetails) public companyNames;
  mapping(uint256 => bytes32) public tokenToHash;

  modifier isCompanyOwner(bytes memory company, bytes memory din, address ownerToCheck) {
    bytes32 companyHash = getCompanyHash(company, din);
    require(
      companyNames[companyHash].owner == ownerToCheck,
      'You are not the owner of this company.'
    );
    _;
  }

  modifier isRegistrationOpen() {
    require(
      tenderStart+ tenderTime*1 days > block.timestamp,
      "registration is not open"
    );
    _;
  }

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;

  /**
   * @dev - Constructor of the contract
   */
  constructor() ERC721("NoobsTender", "Noobs") {}
  function safeMint(address to, string memory uri, uint256 tokenId2) internal onlyOwner{
        _safeMint(to, tokenId2);
        _setTokenURI(tokenId2, uri);
    }
        
        
    //burning the nft
    function _burn(uint256 tokenId2) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId2);
    }


    //Getting NFT uri
    function tokenURI(uint256 tokenId2)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId2);
    }


  function startTendor(
    bytes memory name,
    uint256 id,
    uint time
  ) public onlyOwner {
    tenderName = name;
    tenderId = id;
    tenderStart=block.timestamp;
    tenderTime=time;
    winner=0;
  }




  /*
   * @dev - function to register company name
   * @param company - company name to be registered
   * @param din - DIN number of company
   * @param bid - bid amount by company
   */




  function register(
    bytes memory company,
    bytes memory din,
    uint256 bid,
    address payable companyOwner
  )
    onlyOwner
    public
    payable
    isRegistrationOpen()
  {
    // calculate the company hash
    bytes32 companyHash = getCompanyHash(company, din);
    // create a new company entry with the provided fn parameters
    // string memory uri = string(abi.encodePacked(domainHash));
    uint256 tokenId2 = _tokenIdCounter.current()+1;
    _tokenIdCounter.increment();
    safeMint(companyOwner,string.concat("https://sourabhchoudhary.live/tenderDetails/", Strings.toString(tokenId2)), tokenId2);
    tokenToHash[tokenId2] = companyHash; 
    CompanyDetails memory newCompany = CompanyDetails({
      companyName: company,
      companyDIN: din,
      owner: companyOwner,
      tokenId: tokenId2,
      tenderIdApplied: tenderId,
      priceBid: bid
    });

    // save the company to the storage
    companyNames[companyHash] = newCompany;
    if(winner==0){
      winner=tokenId2;
    }
    else if(companyNames[tokenToHash[winner]].priceBid>bid){
      winner = tokenId2;
    }
  }

  /*
   * @dev - Transfer contract ownership
   * @param from - owner of tender NFT
   * @param to - to new owner of tender NFT
   * @param tokenId - ID of tender NFT
   */
  function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )  public virtual  override (ERC721)
    {
          require(to != address(0));

          // calculate the hash of the current company
          bytes32 companyHash = getCompanyHash(companyNames[tokenToHash[tokenId]].companyName, companyNames[tokenToHash[tokenId]].companyDIN);
          // assign the new owner of the tender
          companyNames[companyHash].owner = to;
          //checking if from is ownder of tender NFT
          require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
          _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721) {
        require(to != address(0));

          // calculate the hash of the current company
          bytes32 companyHash = getCompanyHash(companyNames[tokenToHash[tokenId]].companyName, companyNames[tokenToHash[tokenId]].companyDIN);
          // assign the new owner of the tender
          companyNames[companyHash].owner = to;
          //checking if from is ownder of tender NFT
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721) {
              require(to != address(0));
          // calculate the hash of the current company
          bytes32 companyHash = getCompanyHash(companyNames[tokenToHash[tokenId]].companyName, companyNames[tokenToHash[tokenId]].companyDIN);
          // assign the new owner of the tender
          companyNames[companyHash].owner = to;
        //checking if from is ownder of tender NFT
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

  /*
   * @dev - Get details of tender
   */
  function getTenderDetails()
    public
    view
    returns (uint256,uint256,uint256)
  {
    // return the tender details
    return (tenderId,winner,_tokenIdCounter.current());
  }

  /*
   * @dev - Get (company name + din number) hash used for unique identifier
   */
  function getCompanyHash(bytes memory company, bytes memory din)
    public
    pure
    returns (bytes32)
  {
    // @dev - tightly pack parameters in struct for keccak256
    return keccak256(abi.encodePacked(company, din));
  }

  /**
   * @dev - Withdraw tender
   */
  function withdraw(uint256 tokenIdofDomain) public onlyOwner {
    _burn(tokenIdofDomain);
  }
}