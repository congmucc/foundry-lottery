## About

This is a foundry project for smart contract of lottery game.

1. Users can enter by paying for a ticket
    1. The ticket fees are going to go to the winner during the draw
2. After X period of time, the lottery will automatically draw a winner
    1. And this will be done programatically
3. Using Chainlink VRF & Chainlink Automation
    1. Chainlink VRF -> Randomness
    2. Chainlink Automation -> Time based trigger


## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ make build
```

### Test

```shell
$ make test
```

### Format

```shell
$ make fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ make deploy
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```


1.Write some deploy scripts
2.Write our tests
    1.Work on a local chain
    2.Forked testnet


## BY

[The Github course link](https://github.com/Cyfrin/foundry-full-course-cu?tab=readme-ov-file#introduction-6)
