-include .env

# make build
build:
	forge build


deploy-sepolia:
	forge script script/Raffle.s.sol --rpc-url $(SEPOLIA_RPC_URL) --broadcast --private-key $(PRIVATE_KEY)
	--verify --etherscan-api-key $(ETHERSCAN_APO_KEY) -vvvv