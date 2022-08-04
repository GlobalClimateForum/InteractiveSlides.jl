function to_fieldname(typename, id)
    replace(lowercase(string(typename, id)), "{" => "", "}" => "")
end