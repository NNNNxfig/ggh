local baseURL = "https://raw.githubusercontent.com/NNNNxfig/ggh/main/"

local function import(relPath)
    local url = baseURL .. relPath
    local src = game:HttpGet(url)
    return loadstring(src)()
end

local gui = import("Gui/defGui/gui.lua")

if type(gui) == "table" and type(gui.init) == "function" then
    gui.init()
end
