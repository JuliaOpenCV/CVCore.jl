export @gencxxf

using Cxx

global const JlToCxxVarNameMap = Dict{Any,Any}(
    :AbstractCvMat => symbol(".handle"),
    :Mat => symbol(".handle"),
    :UMat => symbol(".handle"),
)

function gencxxf_impl(callexpr::Expr, cxxname::String, varmap::Dict)
    while callexpr.head == :block
        if callexpr.args[1].head == :line
            callexpr = callexpr.args[2]
        else
            callexpr = callexpr.args[1]
        end
    end
    @assert callexpr.head == :call
    name = first(callexpr.args)
    args = callexpr.args[2:end]

    # @show name
    # @show args

    if args[1].head == :tuple
        args = args[1].args
    end

    cxxargs = []
    for arg in args
        if isa(arg, Symbol)
            push!(cxxargs, arg)
        elseif arg.head != :(::)
            push!(cxxargs, arg.args[1])
        else
            cxxarg = copy(arg)
            # TODO: Union
            typname = arg.args[2]
            varname = arg.args[1]
            if haskey(varmap, typname)
                cxxarg.args[1] = Symbol(varname, varmap[typname])
            end
            push!(cxxargs, cxxarg.args[1])
        end
    end

    icxxstr = """
    $(cxxname)($(join(map(x -> string("\$(", x, ")"), cxxargs), ", ")));
    """
    # @show icxxstr
    icxxcall = Expr(:macrocall, symbol("@icxx_str"), icxxstr)

    f = esc(quote
            function $name($(args...))
                $icxxcall
            end
        end)
    # @show f
    f
end

macro gencxxf(callexpr, cxxname)
    gencxxf_impl(callexpr, cxxname, JlToCxxVarNameMap)
end
