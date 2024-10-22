local sdl_raw = terralib.includec[[SDL2/SDL.h]]
terralib.linklibrary[[/lib/libSDL2.so]]

local sdl = {}
for name, value in pairs(sdl_raw) do
    if name:sub(1, 4) == 'SDL_' then
        sdl[name:sub(5)] = value
    end
end

return sdl
