local util = require[[util]]

local z3_raw = terralib.includec[[z3.h]]
terralib.linklibrary[[/lib/libz3.so]]

local z3 = {}
for name, value in pairs(z3_raw) do
    if name:sub(1, 3) == 'Z3_' then
        z3[name:sub(4)] = value
    end
end

z3.context = z3.mk_context(z3.mk_config())

return z3
