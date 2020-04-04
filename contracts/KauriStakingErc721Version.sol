pragma solidity ^0.5.13;

import "./ERC20.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract KauriStaking is Ownable {

    event TokensStaked(address stakedBy, uint256 stakerTokenId, uint256 time, uint256 duration, uint256 amount);
    event TokensWithdrawn(address withdrawnBy, uint256 stakerTokenId, uint256 time, uint256 amount, uint256 remaining);

    ERC20 public token;
    ERC721 public assetToken;

    struct Staked {
        uint256 time;
        uint256 duration;
        uint256 amount;
    }

    mapping(uint256 => Staked) private stakedTokens;

    constructor(ERC20 _token, ERC721 _assetToken) public {
        token = _token;
        assetToken = _assetToken;
    }

    function stakeTokens(uint256 _assetTokenId, uint256 _amount, uint256 _duration) public {
        require(msg.sender == assetToken.ownerOf(_assetTokenId), "you must be the current owner of asset token id");
//        require(stakedTokens[msg.sender].amount == 0, "some tokens are already staked for this address");
        require(stakedTokens[_assetTokenId].amount == 0, "some tokens are already staked for this address");

        token.transferFrom(msg.sender, address(this), _amount);
        stakedTokens[_assetTokenId] = Staked(now, _duration, _amount);
        emit TokensStaked(msg.sender, _assetTokenId, now, _duration, _amount);
    }

    function stakeTokensFor(uint256 _assetTokenId, uint256 _amount, uint256 _duration) public onlyOwner {
        require(stakedTokens[_assetTokenId].amount == 0, "some tokens are already staked for this address");
        token.transferFrom(msg.sender, address(this), _amount);
        stakedTokens[_assetTokenId] = Staked(now, _duration, _amount);
        emit TokensStaked(msg.sender, _assetTokenId, now, _duration, _amount);
    }

    function withdrawTokens(uint256 _assetTokenId, uint256 _amount) public {
        require(msg.sender == assetToken.ownerOf(_assetTokenId), "you must be the current owner of asset token id");
        Staked memory staked = stakedTokens[_assetTokenId];
        require(!isLocked(now, staked.time, staked.duration), "tokens are still locked");
        require(staked.amount > 0, "no staked tokens to withdraw");

        //if trying to withdraw more than available, withdraw all
        uint256 toWithdraw = _amount;
        if(toWithdraw > staked.amount){
            toWithdraw = staked.amount;
        }

        token.transfer(msg.sender, toWithdraw);
        if(staked.amount == toWithdraw){
            //withdrawing all
            stakedTokens[_assetTokenId] = Staked(0, 0, 0);
        } else {
            stakedTokens[_assetTokenId] = Staked(staked.time, staked.duration, staked.amount - toWithdraw);
        }
        emit TokensWithdrawn(msg.sender, _assetTokenId, now, toWithdraw, staked.amount - toWithdraw);
    }

    function isLocked(uint256 _now, uint256 _time, uint256 _duration) internal pure returns (bool) {
        return _now >= _time + _duration ? false:true;
    }

    //also returns current owner (might change)
    function stakedDetails(uint256 _assetTokenId) public view returns (address, uint256, uint256, uint256, bool) {
        Staked memory staked = stakedTokens[_assetTokenId];
        return (assetToken.ownerOf(_assetTokenId),
        staked.time,
        staked.duration,
        staked.amount,
        isLocked(now, staked.time, staked.duration));
    }
}
