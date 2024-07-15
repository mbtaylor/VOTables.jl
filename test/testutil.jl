using StructArrays.Tables

isblank(d)::Bool = ismissing(d) || isnothing(d) || length(d) == 0 || (d isa Number && isnan(d))

squashblank(d) = if isblank(d) missing else d end

function isapproxtable(t1, t2; canblankarray::Bool=true)
    cols1 = Tables.columns(t1)
    cols2 = Tables.columns(t2)
    if length(cols1) != length(cols2)
        @error "column length mismatch $(length(cols1)) != $(length(cols2))"
        return false
    end
    for (icol, (c1, c2)) in enumerate(zip(cols1, cols2))
        for (irow, (v1, v2)) in enumerate(zip(c1, c2))
            equiv = (isequal(v1, v2) ||
                     isblank(v1) && isblank(v2) ||
                     !canblankarray && (isblank(v1) && v2 isa AbstractArray ||
                                        isblank(v2) && v1 isa AbstractArray))
            if !equiv
                cname = Tables.schema(t1).names[icol]
                @error """
                    data mismatch for column $icol $cname at row $irow:
                    --> t1: $v1
                    --> t2: $v2
                """
                return false
            end
        end
    end
    true
end

