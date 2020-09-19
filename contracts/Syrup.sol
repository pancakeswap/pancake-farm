pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./MasterChef.sol";


contract SYRUP is ERC20("SYRUP Token", "SYRUP"){
    using SafeMath for uint256;
    IERC20 public cake;

    MasterChef public chef;

    uint256 public poolId;


    constructor(IERC20 _cake, MasterChef _chef, uint256 _pid) public {
        cake = _cake;
        chef = _chef;
        poolId = _pid;
    }

    // Enter the bar. Pay some CAKEs. Earn some shares.
    function enter(uint256 _amount) public {
        uint256 totalSushi = cake.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        if (totalShares == 0 || totalSushi == 0) {
            _mint(msg.sender, _amount);
        } else {
            uint256 what = _amount.mul(totalShares).div(totalSushi);
            _mint(msg.sender, what);
        }
        cake.transferFrom(msg.sender, address(this), _amount);
        chef.deposit(poolId, _amount)
    }

    // Leave the bar. Claim back your CAKEs.
    function leave(uint256 _share) public {
        uint256 totalShares = totalSupply();
        uint256 what = _share.mul(cake.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        uint256 cakeReward = chef.getPendingSushi(poolId, address(this), _share) + _share
        chef.withdraw(poolId, _share);
        cake.transfer(msg.sender, cakeReward);
    }
}