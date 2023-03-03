// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";
import {SSTORE2} from "solmate/utils/SSTORE2.sol";

import {SS2ERC721} from "src/SS2ERC721.sol";

contract BasicSS2ERC721 is SS2ERC721 {
    constructor(string memory name_, string memory symbol_)
        SS2ERC721(name_, symbol_)
    {}

    function mint(address ptr) public {
        _mint(ptr);
    }

    function tokenURI(uint256) public view virtual override returns (string memory) {
        return "";
    }
}

contract BasicERC721Test is Test {
    BasicSS2ERC721 nftContract;
    BasicSS2ERC721 nftContract_preminted;
    BasicSS2ERC721 nftContract_pretransferred;


    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    function setUp() public {
        nftContract = new BasicSS2ERC721("basic", unicode"✌️");
        nftContract_preminted = new BasicSS2ERC721("preminted", unicode"✌️");
        nftContract_pretransferred = new BasicSS2ERC721("pretransferred", unicode"✌️");

        address ptr = SSTORE2.write(abi.encodePacked(alice));

        // alice starts with a token
        nftContract_preminted.mint(ptr);

        // set up the pre-transfer
        nftContract_pretransferred.mint(ptr);

        vm.prank(alice);
        nftContract_pretransferred.transferFrom(alice, bob, 1);

        vm.prank(bob);
        nftContract_pretransferred.transferFrom(bob, alice, 1);
    }

    /// @dev code from nft-editions/utils/Addresses.sol
    function make(uint256 n) private pure returns (bytes memory addresses) {
        assembly {
            addresses := mload(0x40)
            let data := add(addresses, 32)

            let addr := 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
            for {
                let i := n
            } gt(i, 0) {
                i := sub(i, 1)
            } {
                mstore(add(data, sub(mul(i, 20), 32)), add(addr, i))
            }

            let last := add(data, mul(n, 20))

            // store the length
            mstore(addresses, mul(n, 20))

            // Allocate memory for the length and the bytes,
            // rounded up to a multiple of 32.
            mstore(0x40, and(add(last, 31), not(31)))
        }
    }

    function mint(uint256 n) private {
        bytes memory addresses = make(n);
        address ptr = SSTORE2.write(addresses);
        nftContract.mint(ptr);
    }

    function test_mint_newcomer_0001() public {
        mint(1);
    }

    function test_mint_newcomer_0010() public {
        mint(10);
    }

    function test_mint_newcomer_0100() public {
        mint(100);
    }

    function test_mint_newcomer_1000() public {
        mint(1000);
    }

    function test_transferFrom_initial() public {
        vm.prank(alice);
        nftContract_preminted.transferFrom(alice, bob, 1);
    }

    function test_transferFrom_subsequent() public {
        vm.prank(alice);
        nftContract_pretransferred.transferFrom(alice, bob, 1);
    }

    function test_balanceOf() public view {
        nftContract_preminted.balanceOf(alice);
    }

    function test_ownerOf() public view {
        nftContract_preminted.ownerOf(1);
    }
}
