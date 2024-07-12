using StructArrays.Tables

isblank(d)::Bool = ismissing(d) || isnothing(d) || length(d) == 0 || (d isa Number && isnan(d))

squashblank(d) = if isblank(d) missing else d end

function isapproxtable(t1, t2)
    cols1 = Tables.columns(t1)
    cols2 = Tables.columns(t2)
    if length(cols1) != length(cols2)
        @error "column length mismatch $(length(cols1)) != $(length(cols2))"
        return false
    end
    for (icol, (c1, c2)) in enumerate(zip(cols1, cols2))
        cs1 = squashblank.(c1)
        cs2 = squashblank.(c2)
        if !isequal(cs1, cs2)
            cname = Tables.schema(t1).names[icol]
            @error """
                data mismatch for column $icol $cname:
                --> t1 $cname: $cs1
                --> t2 $cname: $cs2
            """
            return false
        end
    end
    true
end

