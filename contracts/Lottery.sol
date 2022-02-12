//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IERC20.sol";

contract Lottery is Ownable {

    //--------------------------------------
    // constant
    //--------------------------------------

    uint8 public constant LOTTERY_FEE = 5; // lottery fee 5%
    uint16[6] public PRICE_PER_TICKET = [10, 100, 500, 1000, 5000, 10000]; // price per ticket in busd
    uint16[6] public MAX_SIZE_PER_LEVEL = [1000, 500, 100, 50, 50, 35]; // pool size per lotto

    //--------------------------------------
    // data structure
    //--------------------------------------

    // Represents the status of the lottery
    enum Status { 
        NotStarted,     // The lottery has not started yet
        Open,           // The lottery is open for ticket purchases 
        Closed,         // The lottery is no longer open for ticket purchases
        Completed       // The lottery has been closed and the numbers drawn
    }

    // Lottery level1-6
    enum Level { 
        Level1,     // The lottery level 1: ticket price 10 BUSD, max member 1000, max pool size 10,000
        Level2,     // The lottery level 2: ticket price 100 BUSD, max member 500, max pool size 50,000
        Level3,     // The lottery level 3: ticket price 500 BUSD, max member 100, max pool size 50,000
        Level4,     // The lottery level 4: ticket price 1000 BUSD, max member 50, max pool size 50,000
        Level5,     // The lottery level 5: ticket price 5000 BUSD, max member 50, max pool size 250,000
        Level6      // The lottery level 6: ticket price 10,000 BUSD, max member 35, max pool size 350,000
    }

    // All the needed info around a lottery
    struct LottoInfo {
        uint256 lotteryID;          // ID for lotto
        Status lotteryStatus;       // Status for lotto
        Level lotteryLevel;         // Level for lotto
        uint256 startingTimestamp;      // Block timestamp for star of lotto
        uint256 closedTimestamp;       // Block timestamp for end of entries
        uint16 winnerID;     // The winner id
        uint256 winnerAmount;     // The winner prize Amount
        uint256 PoolAmountInBUSD;    // The amount of BUSD for lottery pool money
        uint16[] id;     // id array
        mapping(uint16 => address) member; // lottery member
        mapping(uint16 => uint16) amountOfTicket; // numberOfTicket of every member
    }

    //--------------------------------------
    // State variables
    //--------------------------------------

    // Lottery ID's to info
    mapping(uint256 => LottoInfo) internal allLotteries_;
    // Instance of BUSD token (main currency for lotto)
    IERC20 public busd_; // BUSD address to buy ticket
    // Counter for lottery IDs 
    uint256 public lotteryIdCounter_;

    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event LotteryOpen(uint256 lotteryID);

    //-------------------------------------------------------------------------
    // CONSTRUCTOR
    //-------------------------------------------------------------------------

    constructor(
        address _busd
    ) 
    {
        require(
            _busd != address(0),
            "Contracts cannot be 0 address"
        );
        busd_ = IERC20(_busd);
        lotteryIdCounter_ = 0;
    }

    /**
     * @param   _level: Lottery Level
     * @return  uint256: lotteryID for Lottery ID
     */
    function createNewLotto(
        Level _level
    )
        external
        onlyOwner()
        returns(uint256)
    {
        require(_level >= Level.Level1, "lottery level underflow");
        require(_level <= Level.Level6, "lottery level overflow");
        lotteryIdCounter_ = lotteryIdCounter_ + 1;
        uint256 lotteryID = lotteryIdCounter_;
        // Saving data in struct
        LottoInfo storage newLottery = allLotteries_[lotteryID];
        
        newLottery.lotteryID = lotteryID;
        newLottery.lotteryStatus = Status.Open;
        newLottery.lotteryLevel = _level;
        newLottery.startingTimestamp = block.timestamp;
        newLottery.closedTimestamp = 0;
        newLottery.winnerID = 0;
        newLottery.winnerAmount = 0;
        newLottery.PoolAmountInBUSD = 0;
        newLottery.id.push(1);
        newLottery.member[1] = address(0);
        newLottery.amountOfTicket[1] = 0;

        emit LotteryOpen(lotteryID);
        return lotteryID;
    }

    function getLottoInfo(uint256 lottoID) external view returns(LottoInfo memory)
    {
        return allLotteries_[lottoID];
    }

    /**
     * @param   _lotteryID: lotteryID
     * @param   _numberOfTickets: amount of ticket to buy
     * @return  uint16: ID for Lottery
     */
    function buyTicket(
        uint256 _lotteryID,
        uint16 _numberOfTickets
    )
        external
        returns(uint16)
    {
        // LottoInfo memory lotteryInfo = allLotteries_[_lotteryID];
        // require(lotteryInfo.lotteryStatus == Status.Open, "Can't buy ticket because this Lottery is not OPEN");
        // uint16 lastID = lotteryInfo.id[lotteryInfo.id.length - 1];
        // uint16 restAmountOfTicket = MAX_SIZE_PER_LEVEL[lotteryInfo.lotteryLevel] - lastID + 1;
        // require(restAmountOfTicket >= _numberOfTickets, "There is not enough ticket");
        // uint256 busdAmount = _numberOfTickets * PRICE_PER_TICKET[lotteryInfo.lotteryLevel];
        // require(IERC20(busd_).balanceOf(msg.sender) >= busdAmount, "not enough BUSD");
        // IERC20(busd_).transferFrom(msg.sender, address(this), busdAmount);
        uint16 id = 0;
        return id;
    }

}