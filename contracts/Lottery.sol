pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./LotteryNFT.sol";

import "@nomiclabs/buidler/console.sol";

contract Lottery is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public devaddr;

    uint256 public issueIndex;

    uint256 public totalAddresses = 0;
    uint256 public totalAmount = 0;
    uint256 public lastTimestamp;
    uint256 public maxNumber = 5;

    uint256 private firstAllocation = 60;
    uint256 private sencondAllocation = 20;
    uint256 private thirdAllocation = 10;
    uint256 private devAllocation = 10;

    // Info of each lottery.
    // TODO: ERC721
    struct Lottery {
        uint256 amount;
        address owner;
        uint256 lotteryNumber1;
        uint256 lotteryNumber2;
        uint256 lotteryNumber3;
        uint256 lotteryNumber4;
    }

    // Reward
    uint256[] public winningNumbers;
    Lottery[] public firstPrize;
    Lottery[] public sencondPrize;
    Lottery[] public thirdPrize;

    uint256 public firstPrizeAmount;
    uint256 public sencondPrizeAmount;
    uint256 public thirdPrizeAmount;

    uint256[][] public historyNumbers;

    // The SYRUP TOKEN!
    IERC20 public cake;

    LotteryNFT public lotteryNtf;

    mapping (address => Lottery[]) public userInfo;
    Lottery[] public lotteryInfo;

    event Buy(address indexed user, uint256 _amount, uint256[] numbers);
    event Drawing(uint256[] winningNumbers, uint256 firstPrizeNum);
    event Claim(address indexed user, uint256 indexed tokenid, uint256 amount);

    constructor(
        IERC20 _cake,
        LotteryNFT _lottery,
        uint256 _maxNumber,
        address _devaddr
    ) public {
        cake = _cake;
        lotteryNtf = _lottery;
        maxNumber = _maxNumber;
        devaddr = _devaddr;
        lastTimestamp = block.timestamp;
        issueIndex = 0;
    }

    function reset() external {
        lastTimestamp = block.timestamp;
        for (uint i = 0; i < lotteryInfo.length; i++) {
            delete userInfo[lotteryInfo[i].owner];
        }
        delete lotteryInfo;
        delete firstPrize;
        delete sencondPrize;
        delete thirdPrize;
        issueIndex++;
    }


    function buy(uint256 _amount, uint256[] memory _numbers) public {

        require (_numbers.length == 4, 'wrong length');

        for (uint i = 0; i < 4; i++) {
            require (_numbers[i] <= maxNumber, 'exceed the maximum');
        }

        cake.safeTransferFrom(address(msg.sender), address(this), _amount);

        lotteryNtf.newLotteryItem(msg.sender, _numbers, _amount, issueIndex);

        lotteryInfo.push(Lottery({
            amount: _amount,
            owner: address(msg.sender),
            lotteryNumber1: _numbers[0],
            lotteryNumber2: _numbers[1],
            lotteryNumber3: _numbers[2],
            lotteryNumber4: _numbers[3]
        }));

        Lottery[] storage userLotteries = userInfo[msg.sender];

        if (userInfo[msg.sender].length == 0) {
            totalAddresses = totalAddresses + 1;
        }

        userLotteries.push(Lottery({
            amount: _amount,
            owner: address(msg.sender),
            lotteryNumber1: _numbers[0],
            lotteryNumber2: _numbers[1],
            lotteryNumber3: _numbers[2],
            lotteryNumber4: _numbers[3]
        }));

        totalAmount = totalAmount + _amount;

        lastTimestamp = block.timestamp;

        emit Buy(msg.sender, _amount, _numbers);
    }

    function drawing() public {
        require(msg.sender == devaddr, "dev: wut?");


        bytes32 _structHash;
        uint256 _randomNumber;
        uint256 _maxNumber = maxNumber;
        bytes32 blockhash = blockhash(block.number-1);

        // 1
        _structHash = keccak256(
            abi.encode(
                blockhash,
                totalAddresses
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}
        winningNumbers.push(_randomNumber);


        // 2
        _structHash = keccak256(
            abi.encode(
                blockhash,
                totalAmount
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}
        winningNumbers.push(_randomNumber);


        // 3
        _structHash = keccak256(
            abi.encode(
                blockhash,
                lastTimestamp
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}
        winningNumbers.push(_randomNumber);

        // 4
        _structHash = keccak256(
            abi.encode(
                blockhash,
                block.difficulty
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}
        winningNumbers.push(_randomNumber);


        for (uint i = 0; i < lotteryInfo.length; i++) {
            uint matchingNumber = 0;
            if (lotteryInfo[i].lotteryNumber1 == winningNumbers[0]) {
                matchingNumber = matchingNumber + 1;
            }
            if (lotteryInfo[i].lotteryNumber2 == winningNumbers[1]) {
                matchingNumber = matchingNumber + 1;
            }
            if (lotteryInfo[i].lotteryNumber3 == winningNumbers[2]) {
                matchingNumber = matchingNumber + 1;
            }
            if (lotteryInfo[i].lotteryNumber4 == winningNumbers[3]) {
                matchingNumber = matchingNumber + 1;
            }


            if(matchingNumber == 4) {
                firstPrize.push(lotteryInfo[i]);
                firstPrizeAmount = firstPrizeAmount + lotteryInfo[i].amount;
            }

            if(matchingNumber == 3) {
                sencondPrize.push(lotteryInfo[i]);
                sencondPrizeAmount = sencondPrizeAmount + lotteryInfo[i].amount;
            }

            if(matchingNumber == 2) {
                thirdPrize.push(lotteryInfo[i]);
                thirdPrizeAmount = thirdPrizeAmount + lotteryInfo[i].amount;
            }
        }

        historyNumbers.push(winningNumbers);

        emit Drawing(winningNumbers, firstPrize.length);

    }

    function claimReward(uint256 tokenId) public {
        require(msg.sender == lotteryNtf.ownerOf(tokenId), "not from owner");
        require(issueIndex == lotteryNtf.getLotteryIndex(tokenId), "issue index wrong");
        uint256[] memory lotteryNumber = lotteryNtf.getLotteryNumber(tokenId);
        uint256 amount = lotteryNtf.getLotteryAmount(tokenId);
        uint256 matchingNumber = 0;
        for (uint i = 0; i < lotteryNumber.length; i++) {
            if(winningNumbers[i] == lotteryNumber[i]) {
                matchingNumber= matchingNumber +1;
            }
        }
        uint256 reward;
        if(matchingNumber==4)  {
            reward = amount.div(firstPrizeAmount).mul(totalAmount).mul(firstAllocation).div(100);
            cake.safeTransferFrom(address(this), address(msg.sender), reward);
        }
        if(matchingNumber==3)  {
            reward = amount.div(firstPrizeAmount).mul(totalAmount).mul(firstAllocation).div(100);
            cake.safeTransferFrom(address(this), address(msg.sender), reward);
        }
        if(matchingNumber==2)  {
            reward = amount.div(firstPrizeAmount).mul(totalAmount).mul(firstAllocation).div(100);
            cake.safeTransferFrom(address(this), address(msg.sender), reward);
        }

        emit Claim(msg.sender, tokenId, reward);

    }


    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}
