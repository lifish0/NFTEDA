// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {INFTEDA} from "src/interfaces/INFTEDA.sol";
import {NFTEDA} from "src/NFTEDA.sol";

contract NFTEDAStarterIncentive is NFTEDA {
    struct AuctionState {
        uint96 startTime;
        address starter;
    }

    /// @notice emitted when auction creator discount is set
    /// @param discount the new auction creator discount
    /// expressed as a percent scaled by 1e18
    /// i.e. 1e18 = 100%
    event SetAuctionCreatorDiscount(uint256 discount);

    /// @notice The percent discount the creator of an auction should
    /// receive, compared to the current price
    /// 1e18 = 100%
    uint256 public auctionCreatorDiscountPercentWad;
    uint256 internal _pricePercentAfterDiscount;

    mapping(uint256 => AuctionState) public auctionState;

    constructor(uint256 _auctionCreatorDiscountPercentWad) {
        _setCreatorDiscount(_auctionCreatorDiscountPercentWad);
    }

    function auctionStartTime(uint256 id) public view virtual override returns (uint256) {
        return auctionState[id].startTime;
    }

    function _setAuctionStartTime(uint256 id) internal virtual override {
        auctionState[id] = AuctionState({startTime: uint96(block.timestamp), starter: msg.sender});
    }

    function _clearAuctionState(uint256 id) internal virtual override {
        delete auctionState[id];
    }

    function _auctionCurrentPrice(uint256 id, uint256 startTime, INFTEDA.Auction memory auction)
        internal
        view
        virtual
        override
        returns (uint256)
    {
        uint256 price = super._auctionCurrentPrice(id, startTime, auction);

        if (msg.sender == auctionState[id].starter) {
            price = FixedPointMathLib.mulWadUp(price, _pricePercentAfterDiscount);
        }

        return price;
    }

    function _setCreatorDiscount(uint256 _auctionCreatorDiscountPercentWad) internal virtual {
        auctionCreatorDiscountPercentWad = _auctionCreatorDiscountPercentWad;
        _pricePercentAfterDiscount = FixedPointMathLib.WAD - _auctionCreatorDiscountPercentWad;

        emit SetAuctionCreatorDiscount(_auctionCreatorDiscountPercentWad);
    }
}
