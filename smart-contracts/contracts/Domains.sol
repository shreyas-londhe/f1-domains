// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {StringUtils} from "./libraries/StringUtils.sol";
import {Base64} from "./libraries/Base64.sol";
import "hardhat/console.sol";

contract Domains is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public tld;
    mapping(string => address) public domains; // domain => address
    mapping(string => string) public records; // domain => record
    mapping(uint256 => string) public names; //

    string private svgPartOne =
        '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#B)" d="M0 0h270v270H0z"/><defs><filter id="A" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><path fill-rule="evenodd" clip-rule="evenodd" d="M177.413 101.999H178.226V98.2378H178.24L179.591 101.999H180.294L181.645 98.2378H181.659V101.999H182.472V97.125H181.283L179.973 100.94H179.959L178.614 97.125H177.413V101.999ZM172.916 97.8621H174.458V101.999H175.311V97.8621H176.861V97.125H172.916V97.8621ZM163 101.999L202 63H178.527L139.529 101.999H163.001H163ZM157.409 79.9841H110.197C95.8084 79.9841 93.2902 80.7472 87.1272 86.91C81.3628 92.6729 72.0004 102 72.0004 102H92.4517L97.3308 97.1198C100.539 93.9127 102.193 93.5799 108.928 93.5799H143.812L157.407 79.9836L157.409 79.9841ZM86.4975 84.1285C82.2412 88.1455 72.9789 97.141 67.9867 101.999H46C46 101.999 63.6177 84.4327 73.4105 74.7936C83.4996 65.1909 88.5282 63.0004 107.033 63.0004H174.394L159.809 77.5847H108.402C95.3998 77.5847 92.4786 78.4856 86.4988 84.1285H86.4975Z" fill="white"/><defs><linearGradient id="B" x1="-1.65382e-07" y1="6" x2="255.702" y2="248.31" gradientUnits="userSpaceOnUse"><stop stop-color="#E34A15"/><stop offset="0.460667" stop-color="#B13A11"/><stop offset="1" stop-color="#692108"/></linearGradient></defs><text x="32.5" y="200" font-size="27" fill="#fff" filter="url(#A)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
    string private svgPartTwo = "</text></svg>";

    constructor(string memory _tld) ERC721("Formula1 Name Service", "F1NS") {
        tld = _tld;
        console.log("%s name service deployed", _tld);
    }

    function price(string calldata name) public pure returns (uint256) {
        uint256 len = StringUtils.strlen(name);
        require(len > 2 && len < 9, "name must be at least 3 characters long");
        if (len == 3) {
            return 5 * 10**17; // 5 MATIC = 5 000 000 000 000 000 000 (18 decimals). We're going with 0.5 Matic cause the faucets don't give a lot
        } else if (len == 4) {
            return 3 * 10**17; // To charge smaller amounts, reduce the decimals. This is 0.3
        } else {
            return 1 * 10**17;
        }
    }

    function register(string calldata name) public payable {
        require(domains[name] == address(0), "Domain already registered");

        uint256 _price = this.price(name);
        require(msg.value >= _price, "Not enough funds");

        // Combine the name passed into the function  with the TLD
        string memory _name = string(abi.encodePacked(name, ".", tld));
        // Create the SVG (image) for the NFT with the name
        string memory finalSvg = string(
            abi.encodePacked(svgPartOne, _name, svgPartTwo)
        );
        uint256 newRecordId = _tokenIds.current();
        uint256 length = StringUtils.strlen(name);
        string memory strLen = Strings.toString(length);

        console.log(
            "Registering %s.%s on the contract with tokenID %d",
            name,
            tld,
            newRecordId
        );

        // Create the JSON metadata of our NFT. We do this by combining strings and encoding as base64
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        _name,
                        '", "description": "A domain on the Formula1 Name Service", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(finalSvg)),
                        '","length":"',
                        strLen,
                        '"}'
                    )
                )
            )
        );

        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        console.log(
            "\n--------------------------------------------------------"
        );
        console.log("Final tokenURI", finalTokenUri);
        console.log(
            "--------------------------------------------------------\n"
        );

        _safeMint(msg.sender, newRecordId);
        _setTokenURI(newRecordId, finalTokenUri);
        domains[name] = msg.sender;
        names[newRecordId] = name;

        _tokenIds.increment();
    }

    function getAddress(string calldata name) public view returns (address) {
        return domains[name];
    }

    function setRecord(string calldata name, string calldata record) public {
        require(
            domains[name] == msg.sender,
            "You are not the owner of this domain"
        );
        records[name] = record;
    }

    function getRecord(string calldata name)
        public
        view
        returns (string memory)
    {
        return records[name];
    }

    function getAllNames() public view returns (string[] memory) {
        console.log("Getting all names from contract");
        string[] memory allNames = new string[](_tokenIds.current());
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            allNames[i] = names[i];
            console.log("Name for token %d is %s", i, allNames[i]);
        }

        return allNames;
    }

    function withdrawFunds() public onlyOwner {
        require(msg.sender == owner(), "You are not the owner");
        payable(msg.sender).transfer(address(this).balance);
    }
}
