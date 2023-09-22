//SPDX-license-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {Encoding} from "./Encoding.sol";

contract DeployEncoding is Script {
    function run() external returns (Encoding) {
        vm.startBroadcast();
        Encoding encoding = new Encoding();
        encoding.combineStrings();
        vm.stopBroadcast();
        return encoding;
    }
}