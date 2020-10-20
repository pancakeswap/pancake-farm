pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./LotteryNFT.sol";

import "@nomiclabs/buidler/console.sol";

// 4 numbers
contract Lottery is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Allocation for first/sencond/third reward
    uint256[] private allocation = [60, 20, 10];
    // The TOKEN to buy lottery
    IERC20 public cake;
    // The Lottery NFT for tickets
    LotteryNFT public lotteryNFT;
    // adminAddress
    address public adminAddress;
    // maxNumber
    uint256 public maxNumber = 5;
    // claiming
    bool public claiming = false;

    // =================================

    // issueId => winningNumbers[numbers]
    mapping (uint256 => uint256[]) public historyNumbers;
    // issueId => [tokenId]
    mapping (uint256 => uint256[]) public lotteryInfo;
    // issueId => [totalAmount, firstMatchAmount, secondMatchingAmount, thirdMatchingAmount]
    mapping (uint256 => uint256[]) public historyAmount;
    // address => [tokenId]
    mapping (address => uint256[]) public userInfo;

    uint256 public issueIndex = 0;
    uint256 public totalAddresses = 0;
    uint256 public totalAmount = 0;
    uint256 public lastTimestamp;

    uint256[] public winningNumbers;

    // =================================

    event Buy(address indexed user, uint256 tokenId);
    event Drawing(uint256 indexed issueIndex, uint256[] winningNumbers);
    event Claim(address indexed user, uint256 tokenid, uint256 amount);
    event DevWithdraw(address indexed user, uint256 amount);
    event Reset(uint256 indexed issueIndex);
    event MultiClaim(address indexed user, uint256 amount);

    constructor(
        IERC20 _cake,
        LotteryNFT _lottery,
        uint256 _maxNumber,
        address _adminAddress
    ) public {
        cake = _cake;
        lotteryNFT = _lottery;
        maxNumber = _maxNumber;
        adminAddress = _adminAddress;
        lastTimestamp = block.timestamp;
    }

    uint256[] private nullTicket = [0,0,0,0];

    function reset() external {
        require(msg.sender == adminAddress, "admin: wut?");
        require(drawed(), "drawed?");
        lastTimestamp = block.timestamp;
        totalAddresses = 0;
        totalAmount = 0;
        delete winningNumbers;
        issueIndex = issueIndex +1;
        if(getMatchingRewardAmount(issueIndex-1, 4) == 0) {
            uint256 amount = getTotalRewards(issueIndex-1).mul(allocation[0]).div(100);
            buy(amount, nullTicket);
        }
        claiming = false;
        emit Reset(issueIndex);
    }

    function drawed() public view returns(bool res) {
        return winningNumbers.length != 0;
    }

    function buy(uint256 _amount, uint256[] memory _numbers) public {
        require (_numbers.length == 4, 'wrong length');
        require (!drawed(), 'drawed, can not buy now');
        for (uint i = 0; i < 4; i++) {
            require (_numbers[i] <= maxNumber, 'exceed the maximum');
        }
        if(_numbers[0] == 0)  {
            uint256 tokenId = lotteryNFT.newLotteryItem(address(this), _numbers, _amount, issueIndex);
            lotteryInfo[issueIndex].push(tokenId);
            totalAmount = totalAmount + _amount;
            lastTimestamp = block.timestamp;
            emit Buy(address(this), tokenId);
        }
        else {
            cake.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 tokenId = lotteryNFT.newLotteryItem(msg.sender, _numbers, _amount, issueIndex);
            lotteryInfo[issueIndex].push(tokenId);
            if (userInfo[msg.sender].length == 0) {
                totalAddresses = totalAddresses + 1;
            }
            userInfo[msg.sender].push(tokenId);
            totalAmount = totalAmount + _amount;
            lastTimestamp = block.timestamp;
            emit Buy(msg.sender, tokenId);
        }
    }

    function  multiBuy(uint256 _price, uint256[][] memory _numbers) public {
        require (!drawed(), 'drawed, can not buy now');
        uint256 totalPrice  = 0;
        for (uint i = 0; i < _numbers.length; i++) {
            require (_numbers[i].length == 4, 'wrong length');
            for (uint j = 0; j < 4; j++) {
                require (_numbers[i][j] <= maxNumber, 'exceed the maximum');
            }
            uint256 tokenId = lotteryNFT.newLotteryItem(msg.sender, _numbers[i], _price, issueIndex);
            lotteryInfo[issueIndex].push(tokenId);
            if (userInfo[msg.sender].length == 0) {
                totalAddresses = totalAddresses + 1;
            }
            userInfo[msg.sender].push(tokenId);
            totalAmount = totalAmount + _price;
            lastTimestamp = block.timestamp;
            totalPrice = totalPrice + _price;
            // buy(_price, _numbers[i]);
        }
        cake.safeTransferFrom(address(msg.sender), address(this), totalPrice);
    }

    function drawing() public {
        require(msg.sender == adminAddress, "admin: wut?");
        require(!drawed(), "reset?");
        bytes32 _structHash;
        uint256 _randomNumber;
        uint256 _maxNumber = maxNumber;
        bytes32 _blockhash = blockhash(block.number-1);

        // 1
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                totalAddresses
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}
        winningNumbers.push(_randomNumber);

        // 2
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                totalAmount
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}
        winningNumbers.push(_randomNumber);

        // 3
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                lastTimestamp
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}
        winningNumbers.push(_randomNumber);

        // 4
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                block.difficulty
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}
        winningNumbers.push(_randomNumber);
        historyNumbers[issueIndex] = winningNumbers;
        emit Drawing(issueIndex, winningNumbers);
    }

    function setClaiming(uint256[4] memory _historyAmount) public {
        require(msg.sender == adminAddress, "admin: wut?");
        require(drawed(), "reset?");
        historyAmount[issueIndex] = _historyAmount;
        claiming = true;
    }

    function calculateMatchingRewardAmount() external view returns (uint256[4] memory) {
        uint256 totalAmout1 = 0;
        uint256 totalAmout2 = 0;
        uint256 totalAmout3 = 0;
        for (uint i = 0; i < lotteryInfo[issueIndex].length; i++) {
            uint256 tokenId = lotteryInfo[issueIndex][i];
            uint256[] memory lotteryNumbers = lotteryNFT.getLotteryNumbers(tokenId);
            uint256[] storage _winningNumbers = historyNumbers[issueIndex];
            uint256 matchingNumber = 0;
            for (uint j = 0; j < _winningNumbers.length; j++) {
                if(lotteryNumbers[j] == _winningNumbers[j]) {
                    matchingNumber++;
                }
            }
            if (matchingNumber == 4)  {
                totalAmout1 = totalAmout1 + lotteryNFT.getLotteryAmount(tokenId);;
            }
            if (matchingNumber == 3)  {
                totalAmout2 = totalAmout2 + lotteryNFT.getLotteryAmount(tokenId);;
            }
            if (matchingNumber == 2)  {
                totalAmout3 = totalAmout3 + lotteryNFT.getLotteryAmount(tokenId);;
            }
        }
        return [totalAmount, totalAmout1, totalAmout2, totalAmout3];
    }

    function getMatchingRewardAmount(uint256 _issueIndex, uint256 _matchingNumber) internal view returns (uint256) {
        return historyAmount[_issueIndex][5 - _matchingNumber];
    }


    function getTotalRewards(uint256 _issueIndex) public view returns(uint256) {
        require (_issueIndex <= issueIndex, '_issueIndex <= issueIndex');

        if(!drawed() && _issueIndex == issueIndex) {
            return totalAmount;
        }
        return historyAmount[_issueIndex][0];
    }

    function getMatchingRewardLength(uint256 _issueIndex, uint256 _matchingNumber) external view returns (uint256) {
        uint256 length = 0;
        for (uint i = 0; i < lotteryInfo[_issueIndex].length; i++) {
            uint256 tokenId = lotteryInfo[_issueIndex][i];
            uint256[] memory lotteryNumbers = lotteryNFT.getLotteryNumbers(tokenId);
            uint256[] storage _winningNumbers = historyNumbers[_issueIndex];
            uint256 matchingNumber = 0;
            for (uint j = 0; j < _winningNumbers.length; j++) {
                if(lotteryNumbers[j] == _winningNumbers[j]) {
                    matchingNumber++;
                }
            }
            if (matchingNumber == _matchingNumber)  {
                length = length + 1;
            }
        }
        return length;
    }

    function getMatchingLotteries(uint256 _issueIndex, uint256 _matchingNumber, uint256 _index) external view returns(uint256) {
        uint256 index = 0;
        for (uint i = 0; i < lotteryInfo[_issueIndex].length; i++) {
            uint256 tokenId = lotteryInfo[_issueIndex][i];
            uint256[] memory lotteryNumbers = lotteryNFT.getLotteryNumbers(tokenId);
            uint256[] storage _winningNumbers = historyNumbers[_issueIndex];
            uint256 matchingNumber = 0;
            for (uint j = 0; j < _winningNumbers.length; j++) {
                if (lotteryNumbers[j] == _winningNumbers[j]) {
                    matchingNumber++;
                }
            }
            if (matchingNumber == _matchingNumber)  {
                if (index == _index) {
                    return tokenId;
                }
                index++;
            }
        }
        return index;
    }

    function getRewardView(uint256 _tokenId) public view returns(uint256) {
        uint256 _issueIndex = lotteryNFT.getLotteryIssueIndex(_tokenId);
        uint256[] memory lotteryNumbers = lotteryNFT.getLotteryNumbers(_tokenId);
        uint256[] storage _winningNumbers = historyNumbers[_issueIndex];
        uint256 matchingNumber = 0;
        for (uint i = 0; i < lotteryNumbers.length; i++) {
            if (_winningNumbers[i] == lotteryNumbers[i]) {
                matchingNumber= matchingNumber +1;
            }
        }
        uint256 reward = 0;
        if (matchingNumber > 1) {
            uint256 amount = lotteryNFT.getLotteryAmount(_tokenId);
            uint256 poolAmount = getTotalRewards(_issueIndex).mul(allocation[4-matchingNumber]).div(100);
            reward = amount.mul(1e12).div(getMatchingRewardAmount(_issueIndex, matchingNumber)).mul(poolAmount);
        }
        return reward.div(1e12);
    }


    function claimReward(uint256 _tokenId) public {
        require(msg.sender == lotteryNFT.ownerOf(_tokenId), "not from owner");
        require (lotteryNFT.getClaimStatus(_tokenId) == false, "claimed");
        uint256 reward = getRewardView(_tokenId);
        if(reward>0) {
            cake.safeTransfer(address(msg.sender), reward);
        }
        lotteryNFT.claimReward(_tokenId);
        emit Claim(msg.sender, _tokenId, reward);
    }

    function  multiClaim(uint256[] memory _tickets) public {
        require (drawed(), 'havnt drawed, can not claim');
        uint256 totalReward = 0;
        for (uint i = 0; i < _tickets.length; i++) {
            require (msg.sender == lotteryNFT.ownerOf(_tickets[i]), "not from owner");
            require (lotteryNFT.getClaimStatus(_tickets[i]) == false, "claimed");
            uint256 reward = getRewardView(_tickets[i]);
            if(reward>0) {
                totalReward = reward.add(totalReward);
            }
        }
        lotteryNFT.multiClaimReward(_tickets);
        if(totalReward>0) {
            cake.safeTransfer(address(msg.sender), totalReward);
        }
        emit MultiClaim(msg.sender, totalReward);
    }

    // Update admin address by the previous dev.
    function setAdmin(address _adminAddress) public onlyOwner {
        adminAddress = _adminAddress;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function adminWithdraw(uint256 _amount) public onlyOwner {
        cake.safeTransfer(address(msg.sender), _amount);
        emit DevWithdraw(msg.sender, _amount);
    }
}
