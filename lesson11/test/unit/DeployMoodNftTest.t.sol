//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployMoodNft} from "../../script/DeployMoodNft.s.sol";

contract DeployMoodNftTest is Test {
    DeployMoodNft public deployer;

    function setUp() public {
        deployer = new DeployMoodNft();
    }

    function testConvertSvgToUri() public view {
        string memory expectedUri =
            "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNTAwIiBoZWlnaHQ9IjUwMCIgdmlld0JveD0iMCAwIDI4NSAzNTAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHBhdGggZmlsbD0iYmxhY2siIGQ9Ik0xNTAsMCxMNzUsMjAwLEwyMjUsMjAwLFoiPjwvcGF0aD48L3N2Zz4=";
        string memory svg =
            '<svg width="500" height="500" viewBox="0 0 285 350" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill="black" d="M150,0,L75,200,L225,200,Z"></path></svg>';
        string memory actualUri = deployer.svgToImageURI(svg);
        assert(
            /**
             * abi.encodePacked関数の戻り値は、可変長のバイト列であり、
             *         同じ値を表していても、バイト列の長さが異なる場合があります。
             *         一方、keccak256関数の戻り値は、固定長のバイト列であり、
             *         同じ値を表している場合は常に同じ長さのバイト列を返します。
             */
            keccak256(abi.encodePacked(actualUri)) == keccak256(abi.encodePacked(expectedUri))
        );
    }
}
