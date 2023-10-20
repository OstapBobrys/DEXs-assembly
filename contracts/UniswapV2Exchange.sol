// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract UniswapV2Exchange {
    address public immutable owner;

    error NotOwner();
    error TransferFailed();
    error SwapFailed();

    modifier onlyOwner() {
        address _owner = owner;

        assembly {
            if iszero(eq(caller(), _owner)) {
                let errorPtr := mload(0x40)
                mstore(errorPtr, 0x30cd747100000000000000000000000000000000000000000000000000000000)
                revert(errorPtr, 0x4)
            }
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function swap(address _pair, address _tokenToBuy, uint256 _buyAmount) external {
        assembly {
            let ptr := mload(0x40)

            mstore(ptr, 0x0dfe168100000000000000000000000000000000000000000000000000000000) // token0()
            if iszero(staticcall(gas(), _pair, ptr, 0x04, 0, 0)) {
                mstore(0, 0x0200000000000000000000000000000000000000000000000000000000000000)
                revert(0, 0x1)
            }
            returndatacopy(0x100, 0, returndatasize())

            mstore(ptr, 0xd21220a700000000000000000000000000000000000000000000000000000000) // token1()
            if iszero(staticcall(gas(), _pair, ptr, 0x04, 0, 0)) {
                mstore(0, 0x0200000000000000000000000000000000000000000000000000000000000000)
                revert(0, 0x1)
            }
            returndatacopy(0x120, 0, returndatasize())

            switch eq(mload(0x100), _tokenToBuy)
            case 0 {
                mstore(0x140, mload(0x100))
            }
            case 1 {
                mstore(0x140, mload(0x120))
            }

            // getReserves()
            mstore(ptr, 0x0902f1ac00000000000000000000000000000000000000000000000000000000)
            if iszero(staticcall(gas(), _pair, ptr, 0x04, 0, 0)) {
                mstore(0, 0x0200000000000000000000000000000000000000000000000000000000000000)
                revert(0, 0x1)
            }
            returndatacopy(0x200, 0, returndatasize())

            // calculate amountIn
            let numerator := mul(mload(0x200), _buyAmount)
            numerator := mul(numerator, 1000)

            let denominator := sub(mload(0x220), _buyAmount)
            denominator := mul(denominator, 997)

            let amountIn := add(div(numerator, denominator), 1)

            // call transfer
            mstore(ptr, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x4), _pair)
            mstore(add(ptr, 0x24), amountIn)
            if iszero(call(gas(), mload(0x140), 0, ptr, 0x44, 0, 0)) {
                let errorPtr := mload(0x40)
                mstore(errorPtr, 0x90b8ec1800000000000000000000000000000000000000000000000000000000)
                revert(errorPtr, 0x4)
            }

            // call swap
            mstore(ptr, 0x022c0d9f00000000000000000000000000000000000000000000000000000000)
            switch eq(mload(0x100), _tokenToBuy)
            case 0 {
                mstore(add(ptr, 0x4), 0)
                mstore(add(ptr, 0x24), _buyAmount)
            }
            case 1 {
                mstore(add(ptr, 0x4), _buyAmount)
                mstore(add(ptr, 0x24), 0)
            }
            mstore(add(ptr, 0x44), caller())
            mstore(add(ptr, 0x64), "")
            if iszero(call(gas(), _pair, 0, ptr, 0x84, 0, 0)) {
                let errorPtr := mload(0x40)
                mstore(errorPtr, 0x81ceff3000000000000000000000000000000000000000000000000000000000)
                revert(errorPtr, 0x4)
            }
        }
    }

    function withdrawTokens(address _token) external onlyOwner {
        assembly {
            let ptr := mload(0x40)

            // check balance
            mstore(ptr, 0x70a0823100000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x4), address())
            if iszero(staticcall(gas(), _token, ptr, 0x24, 0, 0)) {
                mstore(0, 0x0200000000000000000000000000000000000000000000000000000000000000)
                revert(0, 0x1)
            }
            returndatacopy(0x200, 0, returndatasize())

            // transfer
            mstore(ptr, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x4), caller())
            mstore(add(ptr, 0x24), mload(0x200))
            if iszero(call(gas(), _token, 0, ptr, 0x44, 0, 0)) {
                let errorPtr := mload(0x40)
                mstore(errorPtr, 0x90b8ec1800000000000000000000000000000000000000000000000000000000)
                revert(errorPtr, 0x4)
            }
        }
    }
}
