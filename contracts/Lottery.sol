//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IBEP20.sol";

import "./IERC20.sol";
// import "hardhat/console.sol";

contract Lottery is Ownable {

    //--------------------------------------
    // constant
    //--------------------------------------

    uint8 public constant LOTTERY_FEE = 5; // lottery fee 5%
    uint256 public /*constant*/ LOTTERY_CYCLE = 7 * 24 * 3600; // lottery cycle 7 days
    uint16[6] public PRICE_PER_TICKET = [10, 100, 500, 1000, 5000, 10000]; // price per ticket in busd
    uint16[6] public MAX_SIZE_PER_LEVEL = [1000, 500, 100, 50, 50, 35]; // pool size per lotto
    // Treasury wallet must be multi-sig wallet
    address public TREASURY = 0xd51aF39B679EA8C4B5720E681D2b89cDAb01eABd; // Treasury wallet address, LotteryOwner for ganache

    // for random number
    uint256 private constant MAX_UINT_VALUE = (2**256 - 1);
    uint256 private seedValue1_;
    uint256 private seedValue2_;
    uint256 private seedValue3_;
    string private seedString1_;
    string private seedString2_;
    string private seedString3_;
    address private seedAddress1_;
    address private seedAddress2_;
    address private seedAddress3_;

    //--------------------------------------
    // data structure
    //--------------------------------------

    // Represents the status of the lottery
    enum Status { 
        NotStarted,     // The lottery has not started yet
        Open,           // The lottery is open for ticket purchases 
        Closed,         // The lottery is no longer open for ticket purchases
        Completed,      // The lottery has been closed
        Prized          // Winner got a prize.
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
        uint256 PoolAmountInBUSD;    // The amount of BUSD for lottery pool money
        uint256 winnerPrize;     // The winner prize Amount
        uint16[] id;     // id array
        uint16 winnerID;     // The winner id
        mapping(uint16 => address) member; // lottery member
        mapping(uint16 => uint16) amountOfTicket; // numberOfTicket of every member
    }

    //--------------------------------------
    // State variables
    //--------------------------------------

    // Lottery ID's to info
    mapping(uint256 => LottoInfo) internal allLotteries_;
    // Instance of BUSD token (main currency for lotto)
    IBEP20 public busd_; // BUSD address to buy ticket
    // Counter for lottery IDs 
    uint256 public lotteryIDCounter_;
    // Opening Lotteries
    uint256[6] public openingLotteries_;
    uint256[] public prevLotteriesLevel1_;
    uint256[] public prevLotteriesLevel2_;
    uint256[] public prevLotteriesLevel3_;
    uint256[] public prevLotteriesLevel4_;
    uint256[] public prevLotteriesLevel5_;
    uint256[] public prevLotteriesLevel6_;

    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event LogLotteryStatus(uint256 indexed lotteryID, Status lotteryStatus);
    event LogTicketBuyer(address indexed buyer, uint256 indexed lotteryID, uint16 amountOfTickets);
    event LogLotteryCycleChange(address indexed admin, uint256 indexed time, uint256 newCycle);
    event LogAllSeedValueChanged(address indexed admin, uint256 indexed time,
        uint256 prevSeedVal1,
        uint256 prevSeedVal2,
        uint256 prevSeedVal3,
        string prevSeedStr1,
        string prevSeedStr2,
        string prevSeedStr3,
        address prevSeedAddr1,
        address prevSeedAddr2,
        address prevSeedAddr3
    );
    event LogWinner(address indexed winnerAddress, uint256 indexed lotteryID, uint256 prizeAmount);
    event LogTreasuryChanged(address indexed admin, uint256 indexed time, address newTreasury);

    //-------------------------------------------------------------------------
    // CONSTRUCTOR
    //-------------------------------------------------------------------------

    constructor(
        // uint256 _seedValue1,
        // uint256 _seedValue2,
        // uint256 _seedValue3,
        // string memory _seedString1,
        // string memory _seedString2,
        // string memory _seedString3,
        // address _seedAddress1,
        // address _seedAddress2,
        // address _seedAddress3,
        address _busd
    ) 
    {
        require(
            _busd != address(0),
            "Contracts cannot be 0 address"
        );
        busd_ = IBEP20(_busd);
        lotteryIDCounter_ = 0;
        allLotteries_[0].lotteryStatus = Status.Completed;
        openingLotteries_[0] = 0;
        openingLotteries_[1] = 0;
        openingLotteries_[2] = 0;
        openingLotteries_[3] = 0;
        openingLotteries_[4] = 0;
        openingLotteries_[5] = 0;
        
        // initialize seedValues
        // seedValue1_ = _seedValue1;
        // seedValue2_ = _seedValue2;
        // seedValue3_ = _seedValue3;

        // seedString1_ = _seedString1;
        // seedString2_ = _seedString2;
        // seedString3_ = _seedString3;

        // seedAddress1_ = _seedAddress1;
        // seedAddress2_ = _seedAddress2;
        // seedAddress3_ = _seedAddress3;

        // for only test
        seedValue1_ = 123;
        seedValue2_ = 456;
        seedValue3_ = 789;

        seedString1_ = "apple";
        seedString2_ = "banana";
        seedString3_ = "orange";

        seedAddress1_ = 0x256C9FbE9093E7b9E3C4584aDBC3066D8c6216da;
        seedAddress2_ = 0x36285fDa2bE8a96fEb1d763CA77531D696Ae3B0b;
        seedAddress3_ = 0x7F77451e9c89058556674C5b82Bd5A4fab601AFC;
    }

    /**
     * @param   _level: Lottery Level
     * @return  uint256: lotteryID for Lottery ID
     */
    function createNewLotto(
        Level _level
    )
        external
        onlyOwner
        returns(uint256)
    {
        require(_level >= Level.Level1, "lottery level underflow");
        require(_level <= Level.Level6, "lottery level overflow");
        uint256 level = uint256(_level);
        require(
            allLotteries_[openingLotteries_[level]].lotteryStatus == Status.Completed || 
            allLotteries_[openingLotteries_[level]].lotteryStatus == Status.Prized, 
            "Prev Lottery is not finished."
        );
        lotteryIDCounter_ = lotteryIDCounter_ + 1;
        uint256 lotteryID = lotteryIDCounter_;
        // Saving data in struct
        LottoInfo storage newLottery = allLotteries_[lotteryID];
        
        newLottery.lotteryID = lotteryID;
        newLottery.lotteryStatus = Status.Open; // status set to open
        newLottery.lotteryLevel = _level;
        newLottery.startingTimestamp = block.timestamp;
        newLottery.closedTimestamp = 0;
        newLottery.winnerID = 0;
        newLottery.winnerPrize = 0;
        newLottery.PoolAmountInBUSD = 0;
        newLottery.id.push(1);
        newLottery.member[1] = address(msg.sender);
        newLottery.amountOfTicket[1] = 0;

        if (_level == Level.Level1) {
            prevLotteriesLevel1_.push(openingLotteries_[level]);
        }
        else if (_level == Level.Level2) {
            prevLotteriesLevel2_.push(openingLotteries_[level]);
        }
        else if (_level == Level.Level3) {
            prevLotteriesLevel3_.push(openingLotteries_[level]);
        }
        else if (_level == Level.Level4) {
            prevLotteriesLevel4_.push(openingLotteries_[level]);
        }
        else if (_level == Level.Level5) {
            prevLotteriesLevel5_.push(openingLotteries_[level]);
        }
        else if (_level == Level.Level6) {
            prevLotteriesLevel6_.push(openingLotteries_[level]);
        }

        openingLotteries_[level] = lotteryID;

        emit LogLotteryStatus(lotteryID, newLottery.lotteryStatus);
        return lotteryID;
    }

    function getLotteryRemainTime(uint256 _lotteryID) public view returns(uint256)
    {
        require(_lotteryID <= lotteryIDCounter_, "This lotteryID does not exist.");
        return LOTTERY_CYCLE - (block.timestamp - allLotteries_[_lotteryID].startingTimestamp);
    }
    
    function getRestAmountOfTicket(uint256 _lotteryID) public view returns(uint16)
    {
        require(_lotteryID <= lotteryIDCounter_, "This lotteryID does not exist.");
        uint16 lastID = uint16(allLotteries_[_lotteryID].id.length) - 1;
        uint16 restAmountOfTicket = MAX_SIZE_PER_LEVEL[uint256(allLotteries_[_lotteryID].lotteryLevel)] + 1 
            - allLotteries_[_lotteryID].amountOfTicket[lastID] - allLotteries_[_lotteryID].id[lastID];
        return restAmountOfTicket;
    }

    function getLotteryStatus(uint256 _lotteryID) external view returns(Status)
    {
        require(_lotteryID <= lotteryIDCounter_, "This lotteryID does not exist.");
        return allLotteries_[_lotteryID].lotteryStatus;
    }

    function setLotteryStatus(uint256 _lotteryID) external onlyOwner returns(bool)
    {
        require(_lotteryID <= lotteryIDCounter_, "This lotteryID does not exist.");
        require(allLotteries_[_lotteryID].lotteryStatus == Status.Open, "This Lottery Status is not Open.");
        if ((block.timestamp - allLotteries_[_lotteryID].startingTimestamp) >= LOTTERY_CYCLE) {
            allLotteries_[_lotteryID].lotteryStatus = Status.Closed;
            allLotteries_[_lotteryID].closedTimestamp = block.timestamp;
        }
        return true;
    }

    function getLotteryLevel(uint256 _lotteryID) external view returns(Level)
    {
        require(_lotteryID <= lotteryIDCounter_, "This lotteryID does not exist.");
        return allLotteries_[_lotteryID].lotteryLevel;
    }

    function setLotteryCycle(uint256 _lotteryCycle) external onlyOwner returns(bool)
    {
        LOTTERY_CYCLE = _lotteryCycle;
        emit LogLotteryCycleChange(msg.sender, block.timestamp, LOTTERY_CYCLE);
        return true;
    }

    function getLotteryCycle() external view returns(uint256)
    {
        return LOTTERY_CYCLE;
    }
    
    /**
     * @param _lotteryID: Lottery ID
     * @return uint256: startingTimestamp
     * @return uint256: remainTime
     * @return uint256: closedTimestamp
     * @return uint16: winnerID
     * @return address: winnerAddress
     * @return uint256: PoolAmountInBUSD
     * @return uint16: NumberOfLottoMembers
     */
     function getLottoInfo(uint256 _lotteryID) external view returns(
        uint256,    // startingTimestamp
        uint256,    // closedTimestamp
        uint16,     // winnerID
        address,    // winnerAddress
        uint256,    // PoolAmountInBUSD
        uint16,     // NumberOfLottoMembers
        uint256     // winnerPrize
    )
    {
        require(_lotteryID <= lotteryIDCounter_, "This lotteryID does not exist.");
        LottoInfo storage lottoInfo = allLotteries_[_lotteryID];
        uint256 startingTimestamp = lottoInfo.startingTimestamp;
        uint256 closedTimestamp = lottoInfo.closedTimestamp;
        uint16 winnerID = lottoInfo.winnerID;
        address winnerAddress = lottoInfo.member[lottoInfo.winnerID];
        uint256 PoolAmountInBUSD = lottoInfo.PoolAmountInBUSD;
        uint16 NumberOfLottoMembers = uint16(lottoInfo.id.length - 1);
        uint256 winnerPrize = lottoInfo.winnerPrize;
        return (
            startingTimestamp,
            closedTimestamp,
            winnerID,
            winnerAddress,
            PoolAmountInBUSD,
            NumberOfLottoMembers,
            winnerPrize
        );
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
        require(_lotteryID <= lotteryIDCounter_, "This lotteryID does not exist.");
        LottoInfo storage lotteryInfo = allLotteries_[_lotteryID];

        if ((block.timestamp - lotteryInfo.startingTimestamp) >= LOTTERY_CYCLE) {
            lotteryInfo.lotteryStatus = Status.Closed;
            lotteryInfo.closedTimestamp = block.timestamp;
        }

        require(lotteryInfo.lotteryStatus == Status.Open, 
            "Can't buy ticket because this Lottery is not Open.");

        uint16 lastID = lotteryInfo.id[lotteryInfo.id.length - 1];
        uint16 restAmountOfTicket = MAX_SIZE_PER_LEVEL[uint256(lotteryInfo.lotteryLevel)] - lastID + 1;
        lastID = 0;
        require(restAmountOfTicket >= _numberOfTickets, 
            "There is not enough ticket");
        uint256 busdAmount = _numberOfTickets * PRICE_PER_TICKET[uint256(lotteryInfo.lotteryLevel)] * (10 ** busd_.decimals());
        
        require(busd_.balanceOf(msg.sender) >= busdAmount, "Not enough BUSD");

        busd_.transferFrom(msg.sender, address(this), busdAmount);
        lotteryInfo.PoolAmountInBUSD += busdAmount;
        
        lastID = lotteryInfo.id[lotteryInfo.id.length - 1];
        uint16 newID = lastID + lotteryInfo.amountOfTicket[lastID];
        lastID = 0;
        lotteryInfo.id.push(newID);
        lotteryInfo.member[newID] = address(msg.sender);
        lotteryInfo.amountOfTicket[newID] = _numberOfTickets;
        if ((restAmountOfTicket <= _numberOfTickets) || 
            ((block.timestamp - lotteryInfo.startingTimestamp) >= LOTTERY_CYCLE)) {
            lotteryInfo.lotteryStatus = Status.Closed;
            lotteryInfo.closedTimestamp = block.timestamp;
        }
        emit LogTicketBuyer(msg.sender, _lotteryID, _numberOfTickets);
        return newID;
    }
    
    function randomNumberGenerate(uint256 _lotteryID) private view returns (uint16) {
        require(_lotteryID <= lotteryIDCounter_, "This lotteryID does not exist.");
        uint randomHash = uint(keccak256(abi.encodePacked(
            seedValue1_, seedString1_, seedAddress1_, 
            seedValue2_, seedString2_, seedAddress2_, 
            seedValue3_, seedString3_, seedAddress3_, 
            block.timestamp, block.difficulty, block.number)));
        uint16 lastID = uint16(allLotteries_[_lotteryID].id.length - 1);
        uint16 totalMembers = allLotteries_[_lotteryID].id[lastID] + 
            allLotteries_[_lotteryID].amountOfTicket[lastID] - 1;
        uint256 maxValue = MAX_UINT_VALUE / totalMembers;
        uint16 randomNum = uint16(randomHash / maxValue) + 1;
        if (randomNum > totalMembers)
        {
            randomNum = 1;
        }
        return randomNum;
    }

    /**
     * @param   _lotteryID: lotteryID
     * @return  uint16: ID for Winner
     */
    function whoIsWinner(
        uint256 _lotteryID
    )
        external
        onlyOwner
        returns(uint16)
    {
        require(_lotteryID <= lotteryIDCounter_, "This lotteryID does not exist.");
        LottoInfo storage lotteryInfo = allLotteries_[_lotteryID];
        require(lotteryInfo.lotteryStatus == Status.Closed, 
            "Can't execute whoIsWinner because the lottery Status is not Closed status");

        uint16 winnerIDKey = randomNumberGenerate(_lotteryID);

        // binary search
        /* initialize variables:
            low : index of smallest value in current subarray of id array
            high: index of largest value in current subarray of id array
            mid : average of low and high in current subarray of id array */
        uint256 mid;

        uint256 low = 1;         // set initial value for low
        uint256 high = lotteryInfo.id.length - 1;  // set initial value for high

        /* perform binary search */
        while (low <= high) {
            mid = low + (high - low)/2; // update mid
            
            if ((winnerIDKey >= lotteryInfo.id[mid]) && 
                (winnerIDKey < lotteryInfo.id[mid] + lotteryInfo.amountOfTicket[lotteryInfo.id[mid]]))
            {
                break; // find winnerID
            }
            else if (lotteryInfo.id[mid] > winnerIDKey) { // search left subarray for val
                high = mid - 1;  // update high
            }
            else if (lotteryInfo.id[mid] < winnerIDKey) { // search right subarray for val
                low = mid + 1;        // update low
            }
        }

        lotteryInfo.winnerID = lotteryInfo.id[mid];
        busd_.transfer(TREASURY, lotteryInfo.PoolAmountInBUSD * LOTTERY_FEE / 100);
        lotteryInfo.lotteryStatus = Status.Completed; // Now, we know winnerID.

        emit LogLotteryStatus(_lotteryID, lotteryInfo.lotteryStatus);
        return lotteryInfo.winnerID;
    }

    function winnerGetPrize(uint256 _lotteryID) external returns(bool)
    {
        require(_lotteryID <= lotteryIDCounter_, "This lotteryID does not exist.");
        uint16 winnerID = allLotteries_[_lotteryID].winnerID;
        require(allLotteries_[_lotteryID].lotteryStatus == Status.Completed, "Lottery has not been completed.");
        require(msg.sender == allLotteries_[_lotteryID].member[winnerID], "You are not Winner of this lottery");
        require(allLotteries_[_lotteryID].PoolAmountInBUSD > 1, "Lottery Pool is empty!");
        require(allLotteries_[_lotteryID].winnerPrize == 0, "You already won a prize!");

        allLotteries_[_lotteryID].winnerPrize = allLotteries_[_lotteryID].PoolAmountInBUSD * (100 - LOTTERY_FEE) / 100;
        allLotteries_[_lotteryID].lotteryStatus = Status.Prized;
        // send prize busd to winner
        busd_.transfer(allLotteries_[_lotteryID].member[winnerID], allLotteries_[_lotteryID].winnerPrize);
        
        emit LogWinner(allLotteries_[_lotteryID].member[winnerID], _lotteryID, allLotteries_[_lotteryID].winnerPrize);
        return true;
    }

    function getWiner(uint256 _lotteryID) external view returns(address) {
        require(_lotteryID <= lotteryIDCounter_, "This lotteryID does not exist.");
        require(allLotteries_[_lotteryID].lotteryStatus == Status.Completed || 
            allLotteries_[_lotteryID].lotteryStatus == Status.Prized, 
            "Lottery is going on or not started.");
        return allLotteries_[_lotteryID].member[allLotteries_[_lotteryID].winnerID];
    }

    function updateSeeds(
        uint256 _seedValue1,
        uint256 _seedValue2,
        uint256 _seedValue3,
        string memory _seedString1,
        string memory _seedString2,
        string memory _seedString3,
        address _seedAddress1,
        address _seedAddress2,
        address _seedAddress3
    ) external onlyOwner returns(bool)
    {
        bool ret = false;
        // seed value check
        require(_seedValue1 != 0 && _seedValue1 != seedValue1_, 
            "The seed value can't be 0 value and can't be the same as the previous one.");
        require(_seedValue2 != 0 && _seedValue2 != seedValue2_, 
            "The seed value can't be 0 value and can't be the same as the previous one.");
        require(_seedValue2 != 0 && _seedValue3 != seedValue3_, 
            "The seed value can't be 0 value and can't be the same as the previous one.");
        require(_seedValue1 != _seedValue2, "The seed values never be the same.");
        require(_seedValue1 != _seedValue3, "The seed values never be the same.");
        require(_seedValue2 != _seedValue3, "The seed values never be the same.");

        // seed address check
        require(_seedAddress1 != address(0) && _seedAddress1 != seedAddress1_, 
            "The seed Address can't be 0 Address and can't be the same as the previous one.");
        require(_seedAddress2 != address(0) && _seedAddress2 != seedAddress2_, 
            "The seed Address can't be 0 Address and can't be the same as the previous one.");
        require(_seedAddress2 != address(0) && _seedAddress3 != seedAddress3_, 
            "The seed Address can't be 0 Address and can't be the same as the previous one.");
        require(_seedAddress1 != _seedAddress2, "The seed Address never be the same.");
        require(_seedAddress1 != _seedAddress3, "The seed Address never be the same.");
        require(_seedAddress2 != _seedAddress3, "The seed Address never be the same.");
        
        // seed string check
        require(keccak256(abi.encodePacked(_seedString1)) != 0 && 
            keccak256(abi.encodePacked(_seedString1)) != keccak256(abi.encodePacked(seedString1_)), 
            "The seed String can't be 0 String and can't be the same as the previous one.");
        require(keccak256(abi.encodePacked(_seedString2)) != 0 && 
            keccak256(abi.encodePacked(_seedString2)) != keccak256(abi.encodePacked(seedString2_)), 
            "The seed String can't be 0 String and can't be the same as the previous one.");
        require(keccak256(abi.encodePacked(_seedString3)) != 0 && 
            keccak256(abi.encodePacked(_seedString3)) != keccak256(abi.encodePacked(seedString3_)), 
            "The seed String can't be 0 String and can't be the same as the previous one.");
        require(keccak256(abi.encodePacked(_seedString1)) != keccak256(abi.encodePacked(_seedString2)), 
            "The seed String never be the same.");
        require(keccak256(abi.encodePacked(_seedString1)) != keccak256(abi.encodePacked(_seedString3)), 
            "The seed String never be the same.");
        require(keccak256(abi.encodePacked(_seedString2)) != keccak256(abi.encodePacked(_seedString3)), 
            "The seed String never be the same.");

        emit LogAllSeedValueChanged(msg.sender, block.timestamp,
            seedValue1_,
            seedValue2_,
            seedValue3_,
            seedString1_,
            seedString2_,
            seedString3_,
            seedAddress1_,
            seedAddress2_,
            seedAddress3_
        );

        seedValue1_ = _seedValue1;
        seedValue2_ = _seedValue2;
        seedValue3_ = _seedValue3;

        seedString1_ = _seedString1;
        seedString2_ = _seedString2;
        seedString3_ = _seedString3;

        seedAddress1_ = _seedAddress1;
        seedAddress2_ = _seedAddress2;
        seedAddress3_ = _seedAddress3;

        ret = true;
        return ret;
    }

    function getBalanceOfToken() external view returns(uint256) {
        return busd_.balanceOf(address(this));
    }

    // lottery project end
    function endLotteryProject() external onlyOwner {
        // transfer all the remaining tokens to admin
        busd_.transfer(TREASURY, busd_.balanceOf(address(this)));
        // transfer all the BNB to admin and self selfdestruct the contract
        selfdestruct(payable(TREASURY));
    }

    // _treasury must be multi-sig wallet
    function setTREASURY(address _treasury) external onlyOwner returns(bool) {
        bool ret = false;
        require(_treasury != address(0), "The TREASURY wallet must be multi-sig wallet and never be zero address.");
        TREASURY = _treasury;
        ret = true;
        emit LogTreasuryChanged(msg.sender, block.timestamp, TREASURY);
        return ret;
    }
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract Token is ERC20, Ownable {
    event Mint(address indexed account, uint256 amount);
    event Burn(address indexed account, uint256 amount);

    constructor() ERC20 ("TG Busd", "BUSD") {
        // Quantity : 1 quad = 1000, 000, 000, 000, 000 = 10 ** 15
        _mint(msg.sender, 10 ** (15 + 18)); // supply 1 quad

        emit Mint(msg.sender, 10 ** (15 + 18));
    }

    function mint(address account, uint256 amount) external onlyOwner {
        require(amount != uint256(0), "mint: amount is zero");
        _mint(account, amount);

        emit Mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        require(amount != uint256(0), "burn: amount is zero");
        _burn(account, amount);

        emit Burn(account, amount);
    }

    function approve_custom(address spender, uint256 amount) public returns (bool) {
        approve(spender, amount * (10 ** this.decimals()));
        return true;
    }
}
