_G.eNigma = _G.eNigma or {}
_G.eNigma.baseURL = "https://raw.githubusercontent.com/NNNNxfig/ggh/main/"

local function import(relPath)
    local url = _G.eNigma.baseURL .. relPath
    local src = game:HttpGet(url)
    return loadstring(src)()
end

import("Gui/defGui/gui.lua")
