// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Hooks}        from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {HookMiner}    from "v4-periphery/src/utils/HookMiner.sol";
import {WhitelistBuyHook} from "../src/WhitelistBuyHook.sol";

/// @notice 使用 CREATE2 部署 WhitelistBuyHook 合约（适配BSC主网）
contract WhitelistBuyHookScript is Script {
    function setUp() public {}

    // 配置参数（确认BSC主网的PoolManager地址正确）
    address public constant POOLMANAGER = address(0x28e2Ea090877bF75740558f6BFB36A5ffeE9e9dF);
    // Forge默认CREATE2部署器 0x4e59b44847b379578588920cA78FbF26c0B4956C 0x93FC345B718e5462A9D54c6909928F76E6D28099
    address public constant CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);
	
	
    function run() public {
        // 1. 配置Hook权限标志（和合约getHookPermissions匹配）
        console.log(unicode"合约flags应该是128:", Hooks.BEFORE_SWAP_FLAG); 
        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG);
        console.log(unicode"合约flags应该是128:", uint256(flags)); 

        // 2. 挖矿生成CREATE2盐值（仅用于地址预测）
        bytes memory constructorArgs = abi.encode(POOLMANAGER);
        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_DEPLOYER, 
            flags, 
            type(WhitelistBuyHook).creationCode, 
            constructorArgs
        );

        // 3. 广播部署（核心：修正私钥格式！）
        // 自己用来部署合约的钱包私钥
        uint256 deployerPrivateKey = ;
        // 启动广播
        vm.startBroadcast(deployerPrivateKey);

        // 4. 实际部署合约（CREATE2方式）
        WhitelistBuyHook whitelistHook = new WhitelistBuyHook{salt: salt}(IPoolManager(POOLMANAGER));

        vm.stopBroadcast();

        // 5. 验证部署地址（可选，确保预测和实际一致）
        require(address(whitelistHook) == hookAddress, unicode"WhitelistBuyHookScript: 部署地址和预期不匹配");

        // 输出结果
        console.log(unicode"WhitelistBuyHook 部署成功！");
        console.log(unicode"flags    地址:", flags);
		console.log(unicode"salt     地址:", uint256(salt));
        console.log(unicode"Hook 预期地址:", hookAddress);
        console.log(unicode"Hook 实际地址:", address(whitelistHook));
        console.log(unicode"PoolManager 地址:", POOLMANAGER);
        console.log(unicode"合约所有者地址:", msg.sender); 
    }
}