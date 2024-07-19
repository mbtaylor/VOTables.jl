# https://github.com/JuliaLang/julia/pull/50795
_filter(f, xs::NamedTuple)= xs[filter(k -> f(xs[k]), keys(xs))]

nth_bit(m, N) = Bool((m & (1<<(N-1))) >> (N-1))
