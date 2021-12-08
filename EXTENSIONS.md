# EXT Standard - Extensions
* allowance - ERC20 like allowances

   Allows developers to include ERC20 like `approve` and `allowance` methods. Developers can already use `ext_transfer` instead of `transferFrom` as it has an existing `from` field.

* archive - Transaction archive

   Allows the developer to store transactions in an archive, which can be queried from (e.g. transaction history)
   
* batch - Batch transfer/balance functions

   Provides `ext_*_batch` methods for common calls to allow multiple operations per call.
   
* common - Some common token methods

   Provides `ext_metadata` and `ext_supply` queries. More to come...
   
* fee - Allow 3rd parties to query for a fee prior to sending

   Allows the charging of fees
   
* ledger - ICP Ledger-like interface

   Aims to provide a ICP ledger-like interface to make integration with exchanges via rosettaApi much easier.
   
* operator - Operator's for spending tokens

   Adds operator methods `ext_updateOperator` and `ext_isAuthorized` to allow 3rd party operators to spend tokens (or more).
   
* secure - Add's update calls for common queries (more secure)

   Adds `ext_balance_secure`, `ext_supply_secure`, `ext_metadata_secure` and `ext_extensions_secure` - update calls as opposed to queries.
   
* subscribe - Provide interface for notification subscription

   Allows developers to use a subscription method instead of/along-side of the core notification method.
