local asdl = require[[asdl]]

local syntax = asdl.NewContext()

syntax:Define[[
    expr = ident(string name)
         | focus(string name)
         | num(number value)
         | str(string value)
         | app(expr a, expr b)
         | alt(expr a, expr b)
         | seq(expr a, expr b)
         | eq(expr a, expr b)
         | map(expr a, expr b)

    stmt = clause(expr body, string focus)
]]

local function match(value, cases)
    return (cases[value.kind] or cases._)(value)
end

local binops = {'|', ';', '=', '->'}

local binop_names = {
    ['|'] = 'alt',
    [';'] = 'seq',
    ['='] = 'eq',
    ['->'] = 'map'
}

local parse_expr

local function parse_prim_expr(lex)
    if lex:matches(lex.number) then
        return syntax.num(lex:next().value)
    elseif lex:matches(lex.string) then
        return syntax.str(lex:next().value)
    elseif lex:matches(lex.name) then
        return syntax.ident(lex:next().value)
    elseif lex:nextif('@') then
        return syntax.focus(lex:expect(lex.name).value)
    elseif lex:nextif('(') then
        local expr = parse_expr(lex)
        lex:expect(')')
        return expr
    else
        return nil
    end
end

local function parse_app_expr(lex)
    local expr = parse_prim_expr(lex)
    while true do
        local param = parse_prim_expr(lex)
        if param then
            expr = syntax.app(expr, param)
        else
            return expr
        end
    end
end

local function parse_binop_expr(lex, level)
    if level > #binops then
        return parse_app_expr(lex)
    else
        local op = binops[level]
        local op_name = binop_names[op]
        local expr = parse_binop_expr(lex, level + 1)
        while lex:nextif(op) do
            expr = syntax[op_name](expr, parse_binop_expr(lex, level + 1))
        end
        return expr
    end
end

function parse_expr(lex)
    return parse_binop_expr(lex, 1)
end

local function merge_foci(x, y)
    if x == nil then
        return y
    elseif y == nil then
        return x
    elseif x == y then
        return x
    else
        error('Multiple foci')
    end
end

local function the_focus(expr)
    return match(expr, {
        ident = function() return nil end,
        focus = function(expr) return expr.name end,
        num = function() return nil end,
        str = function() return nil end,
        app = function(expr) return merge_foci(the_focus(expr.a), the_focus(expr.b)) end,
        alt = function(expr) return merge_foci(the_focus(expr.a), the_focus(expr.b)) end,
        seq = function(expr) return merge_foci(the_focus(expr.a), the_focus(expr.b)) end,
        eq = function(expr) return merge_foci(the_focus(expr.a), the_focus(expr.b)) end,
        map = function(expr) return merge_foci(the_focus(expr.a), the_focus(expr.b)) end
    })
end

local function parse_clause(lex)
    local expr = parse_expr(lex)
    lex:expect('.')
    local focus = the_focus(expr)
    if not focus then
        lex:error('No focus')
    end
    return syntax.clause(expr, focus)
end

local struct Value
{
    tag : uint;
    union
    {
        num : int64
    }
}

local tags = {}
tags.num = 1

local function compile_expr(expr, cont)
    return match(expr, {
        ident = function()
            return nil
        end,
        num = function()
            local value = constant(Value, `Value { tag = [tags.num], num = [expr.value] })
            return cont(`&[value])
        end,
        alt = function()
            local body_a = compile_expr(expr.a, cont)
            local body_b = compile_expr(expr.b, cont)
            return quote
                [body_a]
                [body_b]
            end
        end
    })
end

local function compile_top_expr(expr)
    local result = symbol(int64)
    local body = compile_expr(expr, function(value)
        return quote
            [result] = [result] + [value].num
        end
    end)
    return terra() : int64
        var [result] = 0;
        [body]
        return [result];
    end
end

local p = compile_top_expr(syntax.alt(syntax.num(42), syntax.num(28)))
print(p)
print(p())

return {
    name = 'algeo',
    entrypoints = {'algeo'},
    keywords = {},
    expression = function(self, lex)
        lex:expect('algeo')
        local clauses = terralib.newlist()
        while not lex:nextif('end') do
            clauses:insert(parse_clause(lex))
        end
        return function(env)
            return clauses
        end
    end
}
