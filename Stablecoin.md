### Stablecoins

**Stablecoins is a cryptocurrencies whose buying power remains stable!!!**

- `Stablecoins` are usually tied to the value of something stable, like a national currency (US Dollar) or commodity(gold).
- For ex, Bitcoin or Ethereum, which are not Stablecoins, whose prices can change drastically. 

**EX:** (1 USDC == 1 USD)



#### Categories of Stablecoins


1. **`Relatively Stabled(Pegged/Floating Stablecoin)`**:
    - Coins which depends on other assets(cryptocurrencies).
    - `Pegged StableCoin` have their value tied to another assets
    - `Floating stablecoin` use maths and mechanism to maintain a constant buying power.

2. **`Stability method(Governced/Algorithmic Stablecoin)`**:
    - This is a mechanism that makes coin stable.
    - `Governced Stablecoin` this mint and burn token via human intervation
    - `Algorithmic Stablecoin` it uses a transparent math equation or set of codes to mint and burn tokens.

3. **`Collateral Types`**:
    - This include `endogenouslly and exogenouslly Collateralized Stablecoins`

    - **Exogenous:** Backed by external assets (USD, ETH). Generally more stable. (`USDT/DAI/RAI/USDC/FRAX`)
    - **Endogenous:** Backed by internal assets (project's own token). More risky due to dependency on the token's value.(`UST-Lunna/Terra`)


4. **`Fiat-Collateralized Stablecoins:`**
    - These are backed by real-world money, like dollars, stored in a bank.
    - **Example**: USDT (Tether), USDC

5. **`Crypto-Collateralized Stablecoins:`**
    - These are backed by other cryptocurrencies as collateral.
    - This are often `over-collateralized`
    - **Example**: DAI,RAI,FRAX

6. **`Algorithmic  Stablecoins:`**
    - This uses algorithms and smart contracts to manage the coin's supply and keep its value stable.
    - **Example**: UST(Terra/Luna)



#### Why Do We Need Stablecoins in DeFi?

1. **Reduce Volatility:** 
    - Unlike Bitcoin or Ethereum, their value doesn't swing wildly, making them safer for `financial transactions`.

2. **Ease of Use:** 
    - They provide a familiar, dollar-like currency for DeFi users.

3. **Seamless Trading:** 
    - Stablecoins are used as a base currency in trading pairs, allowing people to trade crypto assets without dealing with volatility.
    
4. **Lending and Borrowing:** 
    - Users can lend and borrow stablecoins on DeFi platforms, avoiding the risks of crypto price changes.

5. **Savings:** 
    - Stablecoins allow users to earn interest without worrying about their savings losing value.



#### Examples of Popular Stablecoins

1. **Tether(USDT):** Backed by fiat currency reserves.

2. **USD Coin(USDC):** Similar to Tether but focuses on transparency.

3. **DAI/RAI/FRAX:** Decentralized and backed by other crypto assets.




#### Important Functions in Stablecoins


1. **depositCollateral**:
    - User deposits 2 ETH.
    - Protocol stores users collateral deposit
    - Deposit -> 2 ETH ($4000)

2. **mintDSC**:
    - User mints 1000 DSC ($1000).
    - Protocol checks (HF) of user after minting.
    - If (HF) of user is less than MIN_HF after minting, transaction failed!!!
    - User Debt -> 1000 DSC($1000)
    - HF -> $4000/$1000 = 400%
    - User deposit -> 2ETH ($4000)
    
3. **redeem collateral**:
    - Protocol ensures that users HF remains stable after redeeming!!!
    - Users redeem 0.5 ETH($1000)
    - Remaining Collateral -> 1.5 ETH($3000)
    - users HF -> $3000/$1000 = 300%

4. **burnDSC**:
    - Users burns 500DSC ($500)
    - Protocol checks user have enough debt balance to burn DSC
    - Users debt -> 500DSC ($500) 
    - users HF -> $3000/$500 = 600%


5. **Liquidation system**: