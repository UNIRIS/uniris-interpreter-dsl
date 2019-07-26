# Uniris Interpreter with DSL

New version of the interpreter using a Domain Specific Language on top of Elixir and its metaprogramming features.
Make easy to create language with user and developer friendly approach and be based on the Elixir parser and runner.
The contract are always interpreted.

## Example

```
trigger :datetime 1348458454655658

condition origin_family: :biometric
condition response: :response.public_key in :contract.keys

actions do
  send_transaction 
end
```

This can be extanded as we want. 
We could also provide even more accurate behaviors such as

```
trigger :datetime 1348458454655658

condition response: :response.public_key in :contract.keys

actions :trigger do
  send_transaction
end

actions :response do
  send_transaction
end
```


