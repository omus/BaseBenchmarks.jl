module MiscellaneousBenchmarks

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

using .RandUtils
using BenchmarkTools
using Compat

const SUITE = BenchmarkGroup()

###########################################################################
# Splatting penalties (issue #13359)

g = addgroup!(SUITE, "splatting", ["array", "getindex"])

@noinline function perf_splatting_(A, xs...)
    A[xs...]
end
function perf_splatting(A, n, xs...)
    s = zero(eltype(A))
    for i = 1:n
        s += perf_splatting_(A, xs...)
    end
    return s
end

g[(3,3,3)] = @benchmarkable perf_splatting($(samerand(3,3,3)), 100, 1, 2, 3)

###########################################################################
# crossover from x + y + ... to afoldl (issue #13724)

function perf_afoldl(n, k)
    s = zero(eltype(k))
    assert(length(k) >= 12)
    for i = 1:n
        s += k[1] + k[2] + k[3] + k[4] + k[5] + 2 * k[6] + k[7] + k[8] + k[9] + k[10] + k[11] + k[12]
    end
    return s
end

g = addgroup!(SUITE, "afoldl", ["+", "getindex"])
g["Int"] = @benchmarkable perf_afoldl(100, $(zeros(Int, 20)))
g["Float64"] = @benchmarkable perf_afoldl(100, $(zeros(Float64, 20)))
g["Complex{Float64}"] = @benchmarkable perf_afoldl(100, $(zeros(Complex{Float64}, 20)))

###########################################################################
# repeat function (issue #15553)

g = addgroup!(SUITE, "repeat", ["array"])
g[200, 24, 1] = @benchmarkable repeat($(collect(1:200)), inner=$[24], outer=$[1])
g[200, 1, 24] = @benchmarkable repeat($(collect(1:200)), inner=$[1], outer=$[24])

###########################################################################
# bitshift operators (from #18135)

function perf_bitshift(r, n)
    s = zero(eltype(r))
    for i in r
        s += i<<n
    end
    return s
end

g = addgroup!(SUITE, "bitshift", ["range"])
g["Int", "Int"] = @benchmarkable perf_bitshift($(1:1000), Int(3))
g["Int", "UInt"] = @benchmarkable perf_bitshift($(1:1000), UInt(3))
g["UInt", "UInt"] = @benchmarkable perf_bitshift($(UInt(1):UInt(1000)), UInt(3))
g["UInt32", "UInt32"] = @benchmarkable perf_bitshift($(UInt32(1):UInt32(1000)), UInt32(3))

###########################################################################
# Integer, Float64, and Date (#18000) parsing

if !method_exists(parse, Tuple{Type{DateTime}, AbstractString})
    Base.parse(::Type{DateTime}, s::AbstractString) = DateTime(s)
end

function perf_parse{T}(result::AbstractVector{T}, strings::AbstractVector)
    assert(length(result) == length(strings))
    for i = 1:length(strings)
        @inbounds result[i] = parse(T, strings[i])
    end
    return result
end

g = addgroup!(SUITE, "parse", ["DateTime"])
datestr = map(string,range(DateTime("2016-02-19T12:34:56"),Dates.Millisecond(123),200))
g["DateTime"] = @benchmarkable perf_parse($(similar(datestr, DateTime)), $datestr)
g["Int"] = @benchmarkable perf_parse($(Array(Int,1000)), $(map(string, 1:1000)))
g["Float64"] = @benchmarkable perf_parse($(Array(Float64,1000)), $(map(string, 1:1000)))

###########################################################################

end
