pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract SushiBar is ERC20("SushiBar", "xCAKE"){
    using SafeMath for uint256;
    IERC20 public cake;

    constructor(IERC20 _cake) public {
        cake = _cake;
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
    }

    // Leave the bar. Claim back your CAKEs.
    function leave(uint256 _share) public {
        uint256 totalShares = totalSupply();
        uint256 what = _share.mul(cake.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        cake.transfer(msg.sender, what);
    }
}