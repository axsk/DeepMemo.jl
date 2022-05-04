# DeepMemo.jl
## Work in progress

Cache/Memoization of function, where the function (and sub-calls) themselves are treated as part of the data,
built using Cassette.jl

It works recusively and caches all (expensive) computations where they happen and 
invalidates the cache if the function (or any sub-calls) change.

Should this work as imagined (combined with a permanent cache) the computer 
should not have to do any heavy computation twice, automatically retrieving results computed before.



Goals:
- transparent / single macro usage
- dont recompute heavy computations
- efficient space/time loadbalancing


Problems:
- cache invalidation (use a combination of source-hash (long term)/world age(fast))
- identify unpure functions (there is some machinery going on in julia compiler already, check this)
- time based automatic cache tresholding: ignore compile times (julia 1.8 could enable this)

