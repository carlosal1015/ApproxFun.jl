export Derivative,Integral,Hilbert


macro calculus_operator(Op,AbstOp,WrappOp)
    quote
        abstract $AbstOp{T} <: BandedOperator{T}
        immutable $Op{S<:FunctionSpace,T<:Number} <: $AbstOp{T}
            space::S        # the domain space
            order::Int
        end        
        
        $Op{S<:PeriodicDomainSpace}(sp::S,k::Integer)=$Op{S,Complex{Float64}}(sp,k)
        $Op{S<:FunctionSpace}(sp::S,k::Integer)=$Op{S,Float64}(sp,k)
        
        $Op(sp::FunctionSpace)=$Op(sp,1)
        $Op()=$Op(AnySpace())
        $Op(k::Integer)=$Op(AnySpace(),k)
        
        $Op(d::PeriodicDomain,n::Integer)=$Op(LaurentSpace(d),n)
        $Op(d::Domain)=$Op(d,1)

        
        domain(D::$Op)=domain(D.space)
        
        domainspace(D::$Op)=D.space
        rangespace{T,S<:PeriodicDomainSpace}(D::$Op{S,T})=D.space        #assume rangespace is the same
        
        addentries!{T}(::$Op{AnySpace,T},A::ShiftArray,kr::Range)=error("Spaces cannot be inferred for operator")
        
        function addentries!{S,T}(D::$Op{S,T},A::ShiftArray,kr::Range)   
            # Default is to convert to Canonical and d
            sp=domainspace(D)
            csp=canonicalspace(sp)
            addentries!(TimesOperator([$Op(csp,D.order),Conversion(sp,csp)]),A,kr)
        end
        
        function bandinds(D::$Op)
            sp=domainspace(D)
            csp=canonicalspace(sp)
            bandinds(TimesOperator([$Op(csp,D.order),Conversion(sp,csp)])) 
        end
        
        rangespace{S,T}(D::$Op{S,T})=rangespace($Op(canonicalspace(domainspace(D)),D.order))
        rangespace{T}(D::$Op{AnySpace,T})=AnySpace()        
        
        #promoting domain space is allowed to change range space
        # for integration, we fall back on existing conversion for now
        promotedomainspace(D::$AbstOp,sp::AnySpace)=D
        
        function promotedomainspace{S<:FunctionSpace}(D::$AbstOp,sp::S)
            if domain(sp) == AnyDomain()
                $Op(S(domain(D)),D.order)
            else
                $Op(sp,D.order)
            end
        end   
        
        ## Wrapper
        # this allows for a Derivative implementation to return another operator, use a SpaceOperator containing
        # the domain and range space
        # but continue to know its a derivative
        
        
        immutable $WrappOp{S<:BandedOperator} <: $AbstOp{Float64}
            op::S
            order::Int
        end        
        
        addentries!(D::$WrappOp,A::ShiftArray,k::Range)=addentries!(D.op,A,k)      
        
        rangespace(D::$WrappOp)=rangespace(D.op)    
        domainspace(D::$WrappOp)=domainspace(D.op)        
        bandinds(D::$WrappOp)=bandinds(D.op)                
    end
#     for func in (:rangespace,:domainspace,:bandinds)
#         quote $func(D::$WrappOp)=$func(D.op) end
#     end       
end


@calculus_operator(Derivative,AbstractDerivative,DerivativeWrapper)
@calculus_operator(Integral,AbstractIntegral,IntegralWrapper)
@calculus_operator(Hilbert,AbstractHilbert,HilbertWrapper)




# the default domain space is higher to avoid negative ultraspherical spaces
Derivative(d::IntervalDomain,n::Integer)=Derivative(ChebyshevSpace(d),n)
Integral(d::IntervalDomain,n::Integer)=Integral(UltrasphericalSpace{1}(d),n)
Hilbert(d::IntervalDomain,n::Integer)=Hilbert(JacobiWeightSpace(-.5,-.5,ChebyshevSpace(d)),n)




## simplify higher order derivatives/integration/Hilbert
function *(D1::AbstractDerivative,D2::AbstractDerivative)
    @assert domain(D1) == domain(D2)
    
    Derivative(domainspace(D2),D1.order+D2.order)
end


## Overrideable


## Convenience routines

Base.diff(d::DomainSpace,μ::Integer)=Derivative(d,μ)
Base.diff(d::Domain,μ::Integer)=Derivative(d,μ)
Base.diff(d::Domain)=Base.diff(d,1)

integrate(d::Domain)=Integral(d,1)


# Default is to use ops
differentiate(f::Fun)=Derivative(space(f))*f


#^(D1::Derivative,k::Integer)=Derivative(D1.order*k,D1.space)







