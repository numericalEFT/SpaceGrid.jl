using SpaceGrid
using SpaceGrid.AbstractTrees, SpaceGrid.GridTree, SpaceGrid.BaseMesh
using Plots
using LinearAlgebra

include("graphene.jl")

T = 0.05
μ = -2.0

function density(k; band=1)

    dim = la.dim
    n = la.numatoms
    ϵ = dispersion(dim, n, ham, k)[band] - μ

    # return 1 / (exp((ϵ) / T) + 1.0)
    return (π * T)^2 / ((π * T)^2 + ϵ^2)
    # return (exp((ϵ) / T) / T)/(exp((ϵ) / T) + 1.0)^2
end

latvec = [2 0; 1 sqrt(3)]' .* (2π)
# println(SpaceGrid.GridTree._calc_subpoints(3, [3,3], latvec, 2))
tg = treegridfromdensity(k -> density(k), latvec; atol=1 / 2^12, maxdepth=9, mindepth=1, N=4, type=:barycheb)

X, Y = zeros(Float64, length(tg)), zeros(Float64, length(tg))
for (pi, p) in enumerate(tg)
    X[pi], Y[pi] = p[1], p[2]
    # println(p)
end

println("size:$(length(tg)),\t length:$(size(tg)),\t efficiency:$(efficiency(tg))")

smap = SymMap{Float64}(tg, k -> density(k); atol=1e-14, rtol=1e-10)
# println(smap.map)
# println(smap.inv_map)
println("compress:$(smap.reduced_length/length(smap.map))")

k = 4π
# p = plot(legend = false, size = (1024, 1024), xlim = (-1, 1), ylim = (-1, 1))
p = plot(legend=false, size=(1024, 1024), xlim=(-k, k), ylim=(-k, k))
scatter!(p, X, Y, marker=:cross, markersize=2)
savefig(p, "run/tg.pdf")

# test integrate

function green_real(k, n; band=1)
    dim = la.dim
    ln = la.numatoms
    ϵ = dispersion(dim, ln, ham, k)[band] - μ

    # return - ϵ / ((π * T * (2*n + 1))^2 + ϵ^2)
    return 1 / (exp((ϵ) / T) + 1.0)
end

# data = zeros(Float64, length(tg))
data = MappedData(smap)
for i in 1:length(tg)
    data[i] = green_real(tg[i], 1)
end

n0 = integrate(data, tg)
println("n0=$n0")

