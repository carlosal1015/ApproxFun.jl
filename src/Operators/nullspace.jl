

Base.nullspace{T}(A::Operator{T};tolerance=100eps(real(T)),maxlength=1_000_000) =
    transpose_nullspace(qrfact(A'),tolerance,maxlength)


function transpose_nullspace(QR::QROperator,tolerance,maxlength)
    T=eltype(QR)
    ds=domainspace(QR)
    resizedata!(QR,:,100)

    m=size(QR.H,1)
    K=zeros(100,m-1)
    K[1:m-1,1:m-1]=eye(m-1)

    for k=1:10
        v=QR.H[:,k]
        QQ=eye(T,m)-2v*v'
        K[:,:]=K*QQ[1:end-1,2:end]
        K[k+m-1,:]=QQ[end,2:end]
    end
    k=11
    while norm(K[k-10,:]) >tolerance*k
        if k > maxlength
            warn("Max length of $maxlength reached.")
        end

        if k ≥ QR.ncols
            resizedata!(QR,:,k+100)
        end

        v=QR.H[:,k]
        QQ=(eye(m)-2v*v')
        K[:,:]=K*QQ[1:end-1,2:end]

        if k+m-1 > size(K,1)
            K=pad(K,k+m+100,:)
        end
        K[k+m-1,:]=QQ[end,2:end]
        k+=1
    end

    # drop extra rows, and use QR to determine rank
    Q,R=qr(K[1:k-10,:],Val{true})
    ind=findfirst(r->abs(r)≤tolerance,diag(R))
    Kret=ind==0?Q:Q[:,1:ind-1]
    Fun(vec(Kret'),ArraySpace(ds,1,size(K,2)))
end


Base.nullspace{OO<:Operator}(A::Array{OO};kwds...) = nullspace(interlace(A);kwds...)
