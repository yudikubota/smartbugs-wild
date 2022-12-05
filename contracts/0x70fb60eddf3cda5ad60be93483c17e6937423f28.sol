// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// æ¥å£åçº¦
interface IERC721 {
    // é¸é æ¹æ³
    function mint(
        uint256 _category,
        bytes memory _data,
        bytes memory _signature
    ) external;

    // åéæ¹æ³
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);
}

// é¸é åçº¦
contract ERC721Mint {
    // æé å½æ°(nftåçº¦å°å, å½éå°å)
    constructor() payable {
        // è·åæ»é
        // IERC721(tokenAddress).mint(countItem, dataItem, signature);
        // // å½é
        // IERC721(tokenAddress).safeTransferFrom(
        //     address(this),
        //     ownerInfo,
        //     countItem,
        //     1,
        //     "0x"
        // );
        // // èªæ¯(æ¶æ¬¾å°å,å½éå°å)
        // selfdestruct(payable(ownerInfo));
    }

    function mintInfo(  address tokenAddress,
        uint256 countItem,
        bytes memory dataItem,
        bytes memory signature,
        address ownerInfo)
       public
    {
            // è·åæ»é
        IERC721(tokenAddress).mint(countItem, dataItem, signature);
        // å½é
        IERC721(tokenAddress).safeTransferFrom(
            address(this),
            ownerInfo,
            countItem,
            1,
            "0x"
        );
        selfdestruct(payable(ownerInfo));
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

}

// å·¥ååçº¦
contract BatchMint {
    // ææèå°å
    address public owner;
    address public cc;

    constructor() {
        // ææè = åçº¦é¨ç½²è
        owner = msg.sender;
    }

    // é¨ç½²æ¹æ³,(NFTåçº¦å°å,æ¢è´­æ°é)
    function deploy(
        bytes32[] memory saltArr,
        address tokenAddress,
        uint256[] memory countArr,
        bytes[] memory dataArr,
        bytes[] memory signatureArr,
        address sendAddress
    ) public {
        require(msg.sender == owner, "not owner");
        // ç¨æ¢è´­æ°éè¿è¡å¾ªç¯
        for (uint256 i; i < saltArr.length; i++) {
            // é¨ç½²åçº¦(æ¢è´­æ»ä»·)(NFTåçº¦å°å,ææèå°å)
            ERC721Mint c = new ERC721Mint{salt: saltArr[i]}();
            cc = address(c);
            c.mintInfo(tokenAddress,countArr[i],
                dataArr[i],
                signatureArr[i],
                sendAddress);
        }
    }

    function getAddress(
        bytes32 salt
    ) public view returns (address) {
        address predictedAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt,
                            keccak256(
                                abi.encodePacked(
                                    type(ERC721Mint).creationCode
                                )
                            )
                        )
                    )
                )
            )
        );

        return predictedAddress;
    }

    function balanceOf(address tokenAddress,address searchAddress, uint256 id)
        external
        view
        returns (uint256)
    {
        uint256 count = IERC721(tokenAddress).balanceOf(searchAddress, id);
        return count;
    }

}