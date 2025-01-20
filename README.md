# RLBT: Range-Limited Bounded Token

Welcome to the RLBT repository! This project introduces the Range-Limited Bounded Token (RLBT), a token standard designed to maintain token prices within predefined upper and lower limits, ensuring price stability and reducing volatility.

## Motivation

Cryptocurrency markets are often characterized by extreme volatility, with token prices experiencing rapid and unpredictable fluctuations. RLBT aims to mitigate this volatility by establishing boundaries on token prices, fostering value creation and growth within communities, and encouraging broader adoption of digital assets.

## What is RLBT?

A Range-Limited Bounded Token (RLBT) is a token standard that ensures the token's price remains within a specified range. This is achieved through predefined upper and lower price limits, similar to setting side barriers in bowling. The system allows for predictable price stability influenced by factors such as treasury management, market liquidity, user base, and protocol revenues.

## How Does It Work?

The RLBT mechanism utilizes a bonding curve to manage token minting and burning, maintaining the token's price within the established limits:

- **Upper Limit (Minting):** Tokens can be minted at a set price point on the bonding curve, enforcing the upper price limit. For example, if the upper limit is $2, tokens can be minted at this price, creating arbitrage opportunities that prevent the market price from exceeding this threshold.

- **Lower Limit (Burning):** Tokens can be burned in exchange for another currency at a predefined lower price limit. For instance, if the token's market price drops to $0.49 while the lower limit is $0.50, tokens can be burned for a return, maintaining the price floor.

## Duration of Mechanism

The RLBT mechanism can be implemented with a time lock, ensuring it remains in place for a predefined period. This approach allows the protocol or project to achieve a certain level of decentralization or value before the mechanism exits automatically.

## Documentation

For comprehensive documentation, including detailed explanations of limit functions, variables, function examples, treasury management, time locks, smart contracts, risks, and more, please visit our GitBook:

[RLBT Documentation](https://rlbt.gitbook.io/rlbt)

## Author & Contributors

For information about the author and contributors to the RLBT project, please refer to the [Author & Contributors](https://rlbt.gitbook.io/rlbt/author-and-contributors) section in our documentation.

## License

This project is licensed under the terms specified in the [License](https://rlbt.gitbook.io/rlbt/licence) section of our documentation.

---

*This README provides an overview of the RLBT project. For detailed information and technical specifics, please refer to the official documentation linked above.*
