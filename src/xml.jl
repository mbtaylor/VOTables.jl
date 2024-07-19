# so that it works with or without namespaces:
_namespaces(x) = [(k == "" ? "ns" : k) => v for (k, v) in namespaces(x)]
_findall(xpath, x, ns) =
    if any(n -> first(n) == "ns", ns)
        findall(xpath, x, ns)
    else
        findall(replace(xpath, "ns:" => ""), x)
    end
