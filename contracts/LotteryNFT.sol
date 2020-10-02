// contracts/LotteryNF.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract LotteryNFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping (uint256 => uint256[]) public lotteryInfo;
    mapping (uint256 => uint256) public lotteryAmount;
    mapping (uint256 => uint256) public issueIndex;

    constructor() public ERC721("Pancake Lottery", "Lottery") {}

    function newLotteryItem(address player, uint256[] memory _lotteryNumbers, uint256 _amount, uint256 _issueIndex)
        public
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        lotteryInfo[newItemId] = _lotteryNumbers;
        lotteryAmount[newItemId] = _amount;
        issueIndex[newItemId] = _issueIndex;
        // _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function getLotteryNumber(uint256 tokenId) public returns (uint256[] memory) {
        return lotteryInfo[tokenId];
    }
    function getLotteryAmount(uint256 tokenId) public returns (uint256) {
        return lotteryAmount[tokenId];
    }
    function getLotteryIndex(uint256 tokenId) public returns (uint256) {
        return issueIndex[tokenId];
    }
}
