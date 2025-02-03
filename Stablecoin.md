### PROJECT ACHIEVEMENTS!!!

1. **Test Coverage**: Unit and fuzz testing achieved Forge coverage of 76.15%, 78.35%, and 60.00%.
2. **Stablecoin Peg**: The protocol effectively maintains the stablecoin's value around $1, backed by equivalent assets.
3. **System Stability**: The protocol ensures system stability by liquidating users whose health factor (HF) falls below the minimum threshold.
4. **Over-Collateralization**: The protocol consistently remains over-collateralized, ensuring robust financial security.
5. **Invarient Fuzz testing**: Successfully implemented the invarient fuzz testing covering over 1000 input data for functions parameters for better protocol security.


### Some important functions we should keep in mind.

1. **Deposit collateral function**
2. **mintDSC function**
3. **Redeem collateral function**
4. **burnDSC function**
5. **Get user health factor function**
6. **Liquidate user when user has less health factor!!!**
7. **Chainlink price feeds**


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

**Note: In protocols we will keep some x% of Liquidation_Threshold that determines the maximum amount of depositColllateral value that is safe**

- If userDeposit -> 2 ETH($4000)
- And, LIQUIDATION_THRESHOLD = 50%
- So, Considered_Valid_Collateral => ($4000 * 0.5 == $2000)
- This value can be considered for minting and burning or redeeming.



1. **depositCollateral**:
    - User deposits 2 ETH.
    - Protocol stores users collateral deposit
    - Users_Deposit -> 2 ETH ($4000)

2. **mintDSC**:
    - User mints/borrows 1000 DSC ($1000).
    - Protocol checks (HF) of user after minting.
    - If (HF) of user is less than MIN_HF after minting, transaction failed!!!
    - User Debt -> 1000 DSC($1000)
    - HF -> $4000/$1000 = 400%
    - User deposit -> 2ETH ($4000)
    - We can consider LIQUIDATION_THRESHOLD here!!!
    
3. **redeem collateral**:
    - Protocol ensures that users HF remains stable after redeeming!!!
    - Users redeem 0.5 ETH($1000)
    - System will check users HF and reverts if its break.
    - Remaining Collateral -> 1.5 ETH($3000)
    - users HF -> $3000/$1000 = 300%
    - We can consider LIQUIDATION_THRESHOLD here!!!

4. **burnDSC**:
    - Users burns 500DSC ($500)
    - Protocol checks user have enough debt balance to burn DSC
    - System reverts if HF of user breaks after redeeming.
    - Users debt -> 500DSC ($500) 
    - users HF -> $3000/$500 = 600%


5. **Liquidating User**:
   - UserA:  deposits -> $150 of ETH `and`  debt -> $100 of DSC `and` HF->1.5
   - If ETH falls to 40%
   - UserA's  deposit->$90  debt->$100  HF->0.9
   - If UserA's HF falls below 1!!! They are eligible for liquidation.
   - Let, liquidator pays partial-debt of UserA($50)
   - If protocol decides to give 5% or 10% discount price to liquidator from Users collteral amount.
   - Liquidator will receive $52.5/$55 of ETH from users collateral amount

   - Final position of UserA after liquidation:
      - Debt reduced to $50
      - Collateral reduced -> $90-$52.5 == $37.5
      - Liquidator recieves -> $52.5 of ETH
      - Improves UserA health factor. 



#### Health factor

- LIQUIDATION_THRESHOLD = 50%

**Valid_Collateral** = (collateralAmount * LIQUIDATION_THRESHOLD)
**Health_Factor** = ((Valid_Collateral * 1e10)/totalDSCMinted)


1. **Safe Health factor**:
   - Deposit->1 ETH($2000)  Debt->1000 DSC($1000)
   - Valid collateral -> $2000*0.5 == $1000
   - Health factor -> (($1000 * 1e10)/$1000) == 1 * 1e10


2. **Poorer Health factor**:
    - Deposit->0.5 ETH($1000)  Debt->800 DSC($800)  
    - Valid collateral -> $1000*0.5 == $500
    - Health factor -> (($500 * 1e10)/$800) == 0.625 * 1e10



**ChatGPT link**:(IMP.)
https://chatgpt.com/c/6789544e-f88c-800d-9a31-bc3f063804aa