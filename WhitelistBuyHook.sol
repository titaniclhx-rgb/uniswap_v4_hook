// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import {BaseHook}        from "v4-periphery/src/utils/BaseHook.sol";
import {IPoolManager}    from "v4-core/src/interfaces/IPoolManager.sol";
import {Hooks}           from "v4-core/src/libraries/Hooks.sol";
import {PoolKey}         from "v4-core/src/types/PoolKey.sol";
import {SwapParams}      from "v4-core/src/types/PoolOperation.sol";
import {BeforeSwapDelta} from "v4-core/src/types/BeforeSwapDelta.sol";


interface IMsgSender {
    function msgSender() external view returns (address);
}

contract WhitelistBuyHook is BaseHook {
    address public owner;
    bool public restrictToken1 = true;
    bool public restrictToken0 = false;
    mapping(address => bool) public whitelist;

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {
        owner = 0x679328c67c83dDA3741D0222D6D4A9F4a3a36e85;
        whitelist[owner] = true;
    }


	function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

	function _beforeSwap(address sender,
						 PoolKey calldata /*key*/, // not use
						 SwapParams calldata params,
						 bytes calldata /*hookData*/
	) internal view override returns (bytes4, BeforeSwapDelta, uint24) {
		
		address swapper;
        try IMsgSender(sender).msgSender() returns (address res) {
            swapper = res;
        } catch {
            revert("Router does not implement msgSender()");
        }
		
        if (restrictToken1 && params.zeroForOne) {
            require(whitelist[swapper], "Not whitelisted for buying Token1");
        }
		
		if (restrictToken0 && !params.zeroForOne) {
            require(whitelist[swapper], "Not whitelisted for buying Token0");
        }
		
		return (BaseHook.beforeSwap.selector, BeforeSwapDelta.wrap(0), 0);
    }

    function setWhitelist(address addr, bool allowed) external {
        require(msg.sender == owner, "!owner");
        whitelist[addr] = allowed;
    }

    function setrestrictToken1(bool _restrictToken1) external {
        require(msg.sender == owner, "!owner");
        restrictToken1 = _restrictToken1;
    }

	function setrestrictToken0(bool _restrictToken0) external {
        require(msg.sender == owner, "!owner");
        restrictToken0 = _restrictToken0;
    }
}
