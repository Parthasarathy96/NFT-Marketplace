const { ethers } = require("hardhat");

async function main(){
    const myNFT = await ethers.getContractFactory("MyNFTMarket");
    const MyNFT = await myNFT.deploy();

    console.log("Contract has been deployed to ",MyNFT.address);
}

main()
.then(() => process.exit(0))
.catch((error) => {
    console.log(error)
    process.exit(1)
})