macro ref(expression::Expr)
    reference_position::Int = 0
    reference_type::DataType = Nothing

    for (i, symbol) in enumerate(expression.args)
        !(symbol isa Symbol) && continue

        string_symbol = String(symbol)
        if occursin("Rep", string_symbol)
            reference_position = i
            reference_type = eval(Symbol(string_symbol[4:end]))
            break
        end
    end
    reference_position == 0 && return esc(expression)

    expression.args[reference_position] = :reference
    esc(quote
        reference = Ref{$reference_type}()
        $expression
        reference[]
    end)
end

