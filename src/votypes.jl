
const TYPE_VO_TO_JL = Dict(
    "boolean" => Bool,
    "bit" => Bool,
    "unsignedByte" => UInt8,
    "char" => Char,
    "unicodeChar" => Char,
    "short" => Int16,
    "int" => Int32,
    "long" => Int64,
    "float" => Float32,
    "double" => Float64,
    "floatComplex" => ComplexF32,
    "doubleComplex" => ComplexF64,
)

fixbytecount(size) = nel -> nel * size

const TYPE_VO_TO_NBYTEFUNC = Dict(
    "boolean" => fixbytecount(1),
    "bit" => nel -> (nel + 7) ÷ 8,
    "unsignedByte" => fixbytecount(1),
    "char" => fixbytecount(1),
    "unicodeChar" => fixbytecount(2),
    "short" => fixbytecount(2),
    "int" => fixbytecount(4),
    "long" => fixbytecount(8),
    "float" => fixbytecount(4),
    "double" => fixbytecount(8),
    "floatComplex" => fixbytecount(8),
    "doubleComplex" => fixbytecount(16),
)

function vo2jltype(colspec)
    arraysize = get(colspec, :arraysize, nothing)
    basetype = TYPE_VO_TO_JL[colspec[:datatype]]
    if isnothing(arraysize) || arraysize == "1"
        basetype
    elseif occursin("x", arraysize)
        # # Should really be Array type as below, but the rest of the parsing
        # # to support that is not currently in place
        # ndim = length(split(arraysize, "x"))
        # Array{basetype, ndim}
        Vector{basetype}
    elseif basetype === Char
        @assert occursin(r"^[\d*]+$", arraysize)
        String
    else
        @assert occursin(r"^[\d*]+$", arraysize)
        Vector{basetype}
    end
end

jl2votype(::Type{Union{Missing, T}}) where {T} = jl2votype(T)
jl2votype(::Type{String}) = (datatype="char", arraysize="*")
jl2votype(::Type{Char}) = (datatype="char",)
jl2votype(::Type{Bool}) = (datatype="boolean",)
function jl2votype(T::Type)
    votypes = findall(==(T), TYPE_VO_TO_JL)
    isempty(votypes) && error("Don't know how to convert Julia type $T to a VOTable type")
    length(votypes) > 1 && error("Julia type $T maps to multiple VOTable types: $votypes")
    return (datatype=only(votypes),)
end

function vo2nbytes_fixwidth(colspec)
    arraysize = get(colspec, :arraysize, "1")
    arraysize[end] == '*' && return nothing
    nel = parse.(Int64, split(arraysize, "x")) |> prod
    return TYPE_VO_TO_NBYTEFUNC[colspec[:datatype]](nel)
end


_parse(::Type{Union{Missing, T}}, s) where {T} = isempty(s) ? missing : _parse(T, s)
_parse(::Type{Union{Missing, T}}, s::Missing) where {T} = missing

_parse(::Type{T}, s) where {T} = try
    parse(T, s)
catch e
    @warn "Error parsing $s as $T" exception=e
    missing
end
_parse(::Type{Char}, s) = only(s)
_parse(::Type{String}, s) = s
function _parse(::Type{Bool}, s)
    first(s) in ('T', 't', '1') && return true
    first(s) in ('F', 'f', '0') && return false
    parse(Bool, s)
end

function _parse(::Type{T}, s) where {T <: Complex}
    re, im, rest... = split(s)
    @assert isempty(rest)
    complex(_parse(real(T), re), _parse(real(T), im))
end

_parse(::Type{Vector{T}}, s) where {T} = map(x -> _parse(T, x), split(s))


_parse_binary(::Type{String}, data) = String(copy(data))
_parse_binary(::Type{Char}, data) = Char(only(data))
_parse_binary(::Type{T}, data) where {T<:Union{Int,Int32,Int16,Float32,Float64,ComplexF32,ComplexF64}} = reinterpret(T, data) |> only |> bswap
function _parse_binary(::Type{Bool}, data)
    c = data[1] |> Char
    c in ('T', 't', '1') && return true
    c in ('F', 'f', '0') && return false
    missing
end
function _parse_binary(::Type{Vector{T}}, data) where {T}
    nbyte = sizeof(T)
    nel = length(data) ÷ nbyte
    [_parse_binary(T, data[i*nbyte+1:i*nbyte+nbyte]) for i in 0:nel-1]
end


_unparse(::Missing) = ""
_unparse(x::Complex) = "$(real(x)) $(imag(x))"
_unparse(x) = string(x)
