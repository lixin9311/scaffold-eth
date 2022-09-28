# Hub

用于本地可靠的智能合约可重复测试

## Installation

需要：

- scaffold-eth
  - 模拟区块链
  - 提供合约交互UI
  - 模拟moralis的cloud function

依赖：

- nodejs 16
- yarn

## 用到的钱包地址

测试用助记词:

```text
test test test test test test test test test test test junk
```

### 子钱包分配

0 是 Deployer，默认所有合约的Admin

1~16 是16个测试账户，每个账户会给发一定数量的NFT和两种ERC20 Token

17 是Delegatee，要存钱就往里打

18 是Admin (就是KMS)，部署合约的时候Delegatee已经完全授权过给Admin了

## 配置

hardhat测试环境编译的合约地址是稳定不变的。除非合约代码有更改，合约的地址才会变。

## 启动顺序

1. 先启动 `hardhat node`

```bash
# 在 terminal #1 里面
cd scaffold-eth
yarn install

yarn chain # 启动本地 eth node 测试链
# 开一个新的 terminal #2

yarn start # 启动和智能合约交互的Web UI，在 127.0.0.1:3000

# 再开一个新的 terminal #3
yarn deploy # 部署和初始化智能合约
```

2. 启动 moralis 模拟

```bash
# 回到 terminal #3
yarn moralis # 启动moralis事件监听
```

## Cli deposit withdraw

原理是写了 hardhat 的 task

可以任意扩展
<https://github.com/lixin9311/scaffold-eth/blob/master/packages/hardhat/hardhat.config.js#L626-L690>

```bash
cd scaffold-eth
yarn deposit --from 1 --token soc --amount 100 # 从1号钱包存 100 个soc
yarn deposit --from 1 --token nft --amount 1000 # 把 NFT#1000 给存进来
yarn withdraw --to 1 --token nft --amount 1000 # 把 NFT#1000 给提现到1
```
