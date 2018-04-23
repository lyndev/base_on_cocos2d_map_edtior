
local MyApp = class("MyApp", cc.load("mvc").AppBase)

function MyApp:onCreate()
    math.randomseed(os.time())
    self:InitRequireFile()
end

function MyApp:InitRequireFile()

end

return MyApp
