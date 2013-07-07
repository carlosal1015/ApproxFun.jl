

periodic_interval = PeriodicInterval(-1.π,1.π)

type FFun{T<:Number,D<:PeriodicDomain} <: AbstractFun
    coefficients::ShiftVector{T}
    domain::D
end


function FFun(f::Function,n::Integer)
    FFun(f,periodic_interval,n)
end

function FFun(f::Function,d::Domain,n::Integer)
    FFun(svfft(f(points(d,n))),d)
end

function FFun(f::Function,d::Vector,n::Integer)
    FFun(f,apply(PeriodicInterval,d),n)
end

function FFun(cfs::ShiftVector)
	FFun(cfs,periodic_interval)
end

function FFun(cfs::ShiftVector,d::Vector)
	FFun(cfs,apply(PeriodicInterval,d))
end


function FFun(f::Function)
    FFun(f,periodic_interval)
end

function FFun(f::Function,d::Vector)
    FFun(f,apply(PeriodicInterval,d))
end


##TODO: Adaptive routine




##Evaluation


evaluate(f::FFun,x)=horner(f.coefficients,tocanonical(f,x))


##TODO: fast list routine
function horner(v::ShiftVector,x)
    ret = 0.;
    ei = exp(1.im.*x);
    ein = exp(-1.im.*x);    
    
    p = 1.;
    for k = 0:lastindex(v)
        ret += v[k]*p;
        p .*= ei;
    end
    p=ein;
    for k = -1:-1:firstindex(v)
        ret+= v[k]*p;
        p .*= ein;
    end
    
    ret
end

Base.getindex(f::FFun,x)=evaluate(f,x)

##Data routines  TODO: Unify with IFun
values(f::FFun)=isvfft(f.coefficients)
points(f::FFun)=points(f.domain,length(f))
Base.length(f::FFun)=length(f.coefficients)


## Manipulate length

pad(f::FFun,r::Range1)=FFun(pad(f.coefficients,r),f.domain)


## Addition

## Addition and multiplication




for op = (:+,:-)
    @eval begin
        function ($op)(f::FFun,g::FFun)
            @assert f.domain == g.domain

            fi = min(firstindex(f.coefficients),firstindex(g.coefficients))        
            li = max(lastindex(f.coefficients),lastindex(g.coefficients))
            f2 = pad(f,fi:li);
            g2 = pad(g,fi:li);
            
            FFun(($op)(f2.coefficients,g2.coefficients),f.domain)
        end

##TODO: assignment to shiftvector
#         function ($op)(f::FFun,c::Number)
#             f2 = deepcopy(f);
#             
#             f2.coefficients[0] = ($op)(f2.coefficients[0],c);
#             
#             f2
#         end
    end
end 



function .*(f::FFun,g::FFun)
    @assert f.domain == g.domain
    #TODO Coefficient space version
    fi = firstindex(f.coefficients)+firstindex(g.coefficients)
    li = lastindex(f.coefficients)+lastindex(g.coefficients)
    
    ##Todo: Fix following hack to ensure FFT index range
    li = max(-fi,li)
    fi = min(fi,-li)    
    
    
    f2 = pad(f,fi:li)
    g2 = pad(g,fi:li)
    

    FFun(svfft(values(f2).*values(g2)),f.domain)
end




for op = (:*,:.*,:./,:/)
    @eval ($op)(f::FFun,c::Number) = FFun(($op)(f.coefficients,c),f.domain)
end 

-(f::FFun)=FFun(-f.coefficients,f.domain)
-(c::Number,f::FFun)=-(f-c)


for op = (:*,:.*,:+)
    @eval ($op)(c::Number,f::FFun)=($op)(f,c)
end


## Norm

import Base.norm


##TODO: this is mapped L^2[-π,π] norm, 
norm(f::FFun)=norm(f.coefficients.vector)


##TODO: Implement coefficient space real and imag

import Base.imag, Base.real

for op = (:real,:imag) 
    @eval ($op)(f::FFun) = IFun(svfft(($op)(values(f))),f.domain)
end


##Differentiation


##TODO:Figure out how to do type <: Number
#Base.diff(f::FFun{Complex,PeriodicInterval})
function Base.diff(f::FFun) 
    if typeof(f.domain) <: PeriodicInterval
        tocanonicalD(f.domain,0)*FFun(
                        ShiftVector(1.im*[firstindex(f.coefficients):-1],
                                    1.im*[0:lastindex(f.coefficients)]).*f.coefficients,
                        f.domain)
    else#Circle
        ##TODO: general radii
        @assert f.domain.radius == 1.
        cfs = f.coefficients
        # Now shift everything by one
        FFun(ShiftVector(
                        [([firstindex(cfs):-1].*cfs[firstindex(cfs):-1]),0],
                        [1:lastindex(cfs)].*cfs[1:lastindex(cfs)]
                        ),
            f.domain)
    end
end



##TODO: Division by FFun


##Plotting

#TODO: Pad

function plot(f::FFun) 
    p = FramedPlot();
    pts = [points(f),f.domain.b];
    vals =[values(f),f[f.domain.b]];
    add(p,Curve(pts,real(vals),"color","blue"));
    add(p,Curve(pts,imag(vals),"color","red"));    
    Winston.display(p);
    p
end
