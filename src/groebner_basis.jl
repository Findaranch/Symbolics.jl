
DP = SymbolicUtils.DynamicPolynomials
Bijections = SymbolicUtils.Bijections

# extracting underlying polynomial and coefficient type from Polyforms
underlyingpoly(x::Number)    = x
underlyingpoly(pf::PolyForm) = pf.p
coefftype(x::Number)    = typeof(x)
coefftype(pf::PolyForm) = DP.coefficienttype(underlyingpoly(pf))

#=
Converts an array of symbolic polynomials
into an array of DynamicPolynomials.Polynomials
=#
function symbol_to_poly(sympolys::AbstractArray)
    @assert !isempty(sympolys) "Empty input."

    pvar2sym  = Bijections.Bijection{Any,Any}()
    sym2term  = Dict{Sym,Any}()
    polyforms = map(f -> PolyForm(unwrap(f), pvar2sym, sym2term), sympolys)

    # Discover common coefficient type
    commontype = mapreduce(coefftype, promote_type, polyforms, init=Int)
    @assert commontype <: Union{Integer,Rational} "Only integer and rational coefficients are supported as input."

    # Convert all to DP.Polynomial, so that coefficients are of same type,
    # and constants are treated as polynomials
    # We also need this because Groebner does not support abstract types as input
    polynoms = Vector{DP.Polynomial{true,commontype}}(undef, length(sympolys))
    for (i, pf) in enumerate(polyforms)
        polynoms[i] = underlyingpoly(pf)
    end

    polynoms, pvar2sym, sym2term
end

#=
Converts an array of AbstractPolynomialLike`s into an array of
symbolic expressions mapping variables w.r.t pvar2sym
=#
function poly_to_symbol(polys, pvar2sym, sym2term, ::Type{T}) where {T}
    map(f -> PolyForm{T}(f, pvar2sym, sym2term), polys)
end

"""

groebner_basis(polynomials; reduced=true)

Computes a Groebner basis of the ideal generated by the given `polynomials`.

If `reduced` is set, the basis is reduced and *unique*.

"""
function groebner_basis(polynomials; reduced=true)
    polynoms, pvar2sym, sym2term = symbol_to_poly(polynomials)

    basis = groebner(polynoms, reduced=reduced)

    # polynomials is nonemtpy
    T = symtype(first(polynomials))
    poly_to_symbol(basis, pvar2sym, sym2term, T)
end
