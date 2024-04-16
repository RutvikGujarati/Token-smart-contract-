// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract WhaleTaxToken is ERC20, Ownable(msg.sender) {
    using Math for uint256;

    uint256 public constant TOTAL_SUPPLY = 7500000000 * 10**18; // 7.5B tokens
    uint256 public constant TAX_BUY = 1; // 1%
    uint256 public  TAX_SELL_DEFAULT = 2; // 2%
    uint256 public constant TAX_SELL_OVER_20 = 10; // 10%
    uint256 public constant TAX_SELL_20_30 = 20; // 20%
    uint256 public constant TAX_SELL_OVER_30 = 30; // 30%
    uint256 public constant MAX_TRANSACTIONS_PER_DAY = 3;
    uint256 public constant TIME_BETWEEN_SELLS = 2 minutes;

    mapping(address => uint256) public lastSellTime;
    mapping(address => uint256) public dailySellCount;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public blacklist;

    modifier onlyWhitelist() {
        require(whitelist[msg.sender], "Only whitelisted addresses can call this function.");
        _;
    }

    modifier notBlacklisted(address _address) {
        require(!blacklist[_address], "This action is not allowed for blacklisted addresses.");
        _;
    }

    modifier notOverMaxTransactions() {
        require(dailySellCount[msg.sender] < MAX_TRANSACTIONS_PER_DAY, "Maximum transactions per day reached.");
        _;
    }

    modifier notBeforeTimeBetweenSells() {
        require(block.timestamp - lastSellTime[msg.sender] >= TIME_BETWEEN_SELLS, "Cannot make a sell transaction two minutes after the previous one.");
        _;
    }

    constructor() ERC20("WhaleTaxToken", "WHT") {
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(!blacklist[sender] && !blacklist[recipient], "Transfer is not allowed for blacklisted addresses.");

        if (sender != owner() && recipient != owner()) {
            uint256 taxAmount = 0;
            if (amount > TOTAL_SUPPLY * 30 / 100) {
                taxAmount = amount * TAX_SELL_OVER_30 / 100;
            } else if (amount > TOTAL_SUPPLY * 20 / 100) {
                taxAmount = amount * TAX_SELL_20_30 / 100;
            } else if (amount > TOTAL_SUPPLY * 20 / 100) {
                taxAmount = amount * TAX_SELL_OVER_20 / 100;
            } else {
                taxAmount = amount * TAX_SELL_DEFAULT / 100;
            }

            super._transfer(sender, address(this), taxAmount);
            super._transfer(sender, recipient, amount - taxAmount);

            if (!whitelist[sender]) {
                if (block.timestamp - lastSellTime[sender] < TIME_BETWEEN_SELLS) {
                    revert("Cannot make a sell transaction two minutes after the previous one.");
                }
                lastSellTime[sender] = block.timestamp;
                dailySellCount[sender]++;
            }
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    function addToWhitelist(address _address) external onlyOwner {
        whitelist[_address] = true;
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        whitelist[_address] = false;
    }

    function addToBlacklist(address _address) external onlyOwner {
        blacklist[_address] = true;
    }

    function removeFromBlacklist(address _address) external onlyOwner {
        blacklist[_address] = false;
    }

    function distributeTokens(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Arrays length mismatch.");
        for (uint256 i = 0; i < recipients.length; i++) {
            super._transfer(msg.sender, recipients[i], amounts[i]);
        }
    }

    function changeTaxRate(uint256 newTaxRate) external onlyOwner {
        require(newTaxRate >= 0 && newTaxRate <= 100, "Tax rate must be between 0 and 100.");
        TAX_SELL_DEFAULT = newTaxRate;
    }
}
