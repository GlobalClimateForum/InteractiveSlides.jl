function to_fieldname(typename, id)
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