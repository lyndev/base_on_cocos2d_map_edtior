
StartUpCommand = class(StartUpCommand, ControllerCommand)
function StartUpCommand:Execute(message)
    -- 初始化管理器
    AppFacade:GetInstance():AddManager("MusicPlayer")
    AppFacade:GetInstance():AddManager("TimerManager")
    AppFacade:GetInstance():AddManager("NetworkManager")
    AppFacade:GetInstance():AddManager("ResourceManager")
    AppFacade:GetInstance():AddManager("MusicPlayer")
    AppFacade:GetInstance():AddManager("ObjectPoolManager")
end
