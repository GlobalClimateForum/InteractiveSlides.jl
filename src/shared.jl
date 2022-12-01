const MAX_NUM_TEAMS = 6::Int64
const AS_EXECUTABLE  = Ref{Bool}(false)

function to_fieldname(typename; id::Union{Int, String} = "")
    replace(lowercase(string(typename, id)), "{" => "", "}" => "")
end

function eqtokw!(exprs)
    for expr = exprs
        if isa(expr, Expr) && expr.head == :(=)
            expr.head = :kw
        end
    end
    exprs
end