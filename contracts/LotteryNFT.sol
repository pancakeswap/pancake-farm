// contracts/LotteryNF.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LotteryNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping (uint256 => uint256[]) public lotteryInfo;
    mapping (uint256 => uint256) public lotteryAmount;
    mapping (uint256 => uint256) public issueIndex;
    mapping (uint256 => bool) public claimInfo;

    constructor() public ERC721("Pancake Lottery NFT", "ticket") {}

    function newLotteryItem(address player, uint256[] memory _lotteryNumbers, uint256 _amount, uint256 _issueIndex)
        public onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        lotteryInfo[newItemId] = _lotteryNumbers;
        lotteryAmount[newItemId] = _amount;
        issueIndex[newItemId] = _issueIndex;
        claimInfo[newItemId] = false;
        // _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function getLotteryNumbers(uint256 tokenId) external view returns (uint256[] memory) {
        return lotteryInfo[tokenId];
    }
    function getLotteryAmount(uint256 tokenId) external view returns (uint256) {
        return lotteryAmount[tokenId];
    }
    function getLotteryIssueIndex(uint256 tokenId) external view returns (uint256) {
        return issueIndex[tokenId];
    }
    function claimReward(uint256 tokenId) external onlyOwner {
        claimInfo[tokenId] = true;
    }
    function getClaimStatus(uint256 tokenId) external view returns (bool) {
        return claimInfo[tokenId];
    }
}
