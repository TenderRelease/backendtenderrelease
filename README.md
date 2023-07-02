# Tender Release

This project contains the backend for the project Tender Release which is a decentralised web application for automating and adding transparency to the process of tender assigning to companies especially by governments to remove all the middlemans and reduce corruption in the process.

Starting the server

(The following parameters need to be added in .env file in scripts folder- API_URL, PRIVATE_KEY, REACT_URL, NOOBSWALLET, CHAIN, ABI, CONTRACTADDRESS, MONGO_PASSWORD, GAS, SECRET. Also outside scripts folder also API_URL and PRIVATE_KEY need to added in a separate .env file)
```starting the server
cd scripts
npm i
node server.js
```

Below are the API for backend:

admin login

```admin login
https://localhost:8282/login
```

To release a tender by admin

```To release a tender by admin
https://localhost:8282/startTender
```

To register against a tender by a company

```To register against a tender by a company
https://localhost:8282/register
```

To see the winner details

```To see the winner details
https://localhost:8282/getWinner
```

To see the details of a company using a tokenId assigned to it

```To see the details of a company using a tokenId assigned to it
https://localhost:8282/tenderDetails/:tenderId
```

# Smart Contract Commands

To deploy the smart contract use:

```deploying smart contract
npx hardhat compile
npx run --network bsc scripts/deploy.js
```

To run the hardhat console use the below commands

``` running hardhat console
npx hardhat console --network bsc
```
Commands to run smart contract functions using hardhat

Hardhat commands to attach to the contract

``` Hardhat commands to attach to the contract
const Contract = await ethers.getContractFactory("NoobsTender")
const contract = await Contract.attach('contract address') #Our contract address is 0x87219d4b9A4d44b7660F6a198E2F5298e77E6CA2 which has been deployed on binance testnet
```

Hardhat commands to start tender in contract

``` Hardhat command to start tender in contract
await contract.startTender(Tender_name_in_bytes, tender_id, time_till_registration_is_open)
```

Hardhat command to register

``` Hardhat command to register
await contract.register(company_name_in_bytes, company_din_number_in_bytes, bid_amount, wallet_address_of_company) 
#In case of govt tender this wallet address can be a custom wallet address that can be created by the organisation relaseing the tender but the addresss nedd to be evm compatible.
```

To get Winner of Tender and Tender Id of current tender deployed in contract

``` To get Winner of Tender and Tender Id of current tender deployed in contract
await contract.getTenderDetails()
```

Apart from these we have three transfer funtions and a withdraw function as well which can used from hardhat console but they have not been added to node.js backend and frontend of the application but are kept for future uses.

Made with ❤️ by Team Noobs - [Sourabh Choudhary](https://github.com/SD-IITKGP), [Mahim Jain](https://github.com/jainmahim) and [Abhishek Sarjaliya](https://github.com/Abhi21sar)
