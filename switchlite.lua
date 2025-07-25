local obs = obslua
local ffi = require("ffi")

-- Script globals
local active = false
local audio = false
local source = ""
local audio_source = ""
local interval = 100
local last_account = ""

-- FFI calls for foreground window title
ffi.cdef[[
    typedef void* HWND;
    typedef wchar_t WCHAR;
    typedef WCHAR *LPWSTR;
    HWND GetForegroundWindow();
    int GetWindowTextLengthW(HWND hWnd);
    int GetWindowTextW(HWND hWnd, LPWSTR lpString, int nMaxCount);
]]

local C = ffi.C

local function wcs(s)
    if type(s) == 'string' then
        local ws = ffi.new('WCHAR[?]', #s + 1)
        for i = 1, #s do ws[i-1] = s:byte(i) end
        ws[#s] = 0
        return ws
    elseif type(s) == 'number' then
        local ws = ffi.new('WCHAR[?]', s + 1)
        return ws, s
    elseif s == nil then
        return nil
    else
        return s
    end
end

local function mbs(ws)
    local s = {}
    for i = 0, 50 do
        if ws[i] == 0 then break end
        s[i+1] = string.char(ws[i] % 256)
    end
    return table.concat(s)
end

local function GetWindowText(hwnd, buf)
    local ws, sz = wcs(buf or C.GetWindowTextLengthW(hwnd))
    C.GetWindowTextW(hwnd, ws, sz + 1)
    return buf or mbs(ws)
end

local function GetForegroundWindow()
    return ffi.cast('HWND', C.GetForegroundWindow())
end

local function get_active_window_title()
    local hwnd = GetForegroundWindow()
    if hwnd == nil then return nil end
    return GetWindowText(hwnd)
end

-- Source update functions
local function switch_window(scene_item, new_account)
    local source_obj = obs.obs_sceneitem_get_source(scene_item)
    local current_settings = obs.obs_source_get_settings(source_obj)
    local current_window = obs.obs_data_get_string(current_settings, "window")

    local new_window = string.gsub(current_window, "(RuneLite %- )([^:]*)(:.*)", "%1" .. new_account .. "%3")
    local settings = obs.obs_data_create()
    obs.obs_data_set_string(settings, "window", new_window)
    obs.obs_source_update(source_obj, settings)

    obs.obs_data_release(current_settings)
    obs.obs_data_release(settings)
end

local function update_source()
    local focused_window = get_active_window_title()
    if not focused_window then return end

    local new_account = string.match(focused_window, "RuneLite %- (.*)")
    
    if not new_account or new_account == last_account then return end
    last_account = new_account

    local current_scene_as_source = obs.obs_frontend_get_current_scene()
    local current_scene = obs.obs_scene_from_source(current_scene_as_source)
    
    local scene_item = obs.obs_scene_find_source_recursive(current_scene, source)
    if scene_item then
        switch_window(scene_item, new_account)
    end

    if audio and audio_source and audio_source ~= "" then
        local audio_scene_item = obs.obs_scene_find_source_recursive(current_scene, audio_source)
        if audio_scene_item then
            switch_window(audio_scene_item, new_account)
        end
    end

    obs.obs_source_release(current_scene_as_source)
end

local function update_source_task()
    if not active then return end
    update_source()
end

-- Script settings defaults/updating
function script_description()
    return [[Updates the target window of the specified window capture source, and optional audio capture source, as you change RuneLite client.

Only switches to clients that are logged in.

RuneLite's "Show display name in title" must be enabled. Click the 'help' button for instructions.]]
end

function script_update(settings)
    active = obs.obs_data_get_bool(settings, "active") -- Overall toggle for Switchlite being active
    audio = obs.obs_data_get_bool(settings, "audio") -- Toggle for only audio switching
    source = obs.obs_data_get_string(settings, "source") -- Window Capture source
    audio_source = obs.obs_data_get_string(settings, "audio_source") -- Application Audio Capture source
    interval = obs.obs_data_get_int(settings, "interval") -- Check interval
    last_account = obs.obs_data_get_string(settings, "last_account") or "" -- RSN of last known focused RL client, if any

    obs.timer_remove(update_source_task)
    if source ~= "" and active then
        obs.timer_add(update_source_task, interval)
    end
end

function script_defaults(settings)
    obs.obs_data_set_default_int(settings, "interval", 100)
    obs.obs_data_set_default_bool(settings, "active", false)
    obs.obs_data_set_default_bool(settings, "audio", false)
    obs.obs_data_set_default_string(settings, "last_account", "")
end

-- no op callback for URL buttons
function no_op(prop, p)
    return
end

function script_properties()
    local props = obs.obs_properties_create()

    -- Window Capture source for video
    local p = obs.obs_properties_add_list(props, "source", "RuneLite Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
    obs.obs_property_set_long_description(p, "The Window Capture source used for RuneLite video.")
    local sources = obs.obs_enum_sources()
    if sources then
        for _, src in ipairs(sources) do
            local source_id = obs.obs_source_get_unversioned_id(src)
            if source_id == "window_capture" then
                local name = obs.obs_source_get_name(src)
                obs.obs_property_list_add_string(p, name, name)
            end
        end
    end

    -- Application Audio Capture source for audio
    local a = obs.obs_properties_add_list(props, "audio_source", "RuneLite Audio Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
    obs.obs_property_set_long_description(a, "The Application Audio Capture source used for RuneLite game sounds.")
    if sources then
        for _, src in ipairs(sources) do
            local source_id = obs.obs_source_get_unversioned_id(src)
            if source_id == "wasapi_process_output_capture" then
                local name = obs.obs_source_get_name(src)
                obs.obs_property_list_add_string(a, name, name)
            end
        end
        obs.source_list_release(sources)
    end

    -- Check interval. OBS doesn't seem to support long descriptions for int inputs.
    local interval_op = obs.obs_properties_add_int(props, "interval", "Update Interval (ms)", 50, 3000, 25)

    -- Active toggles
    local enable_op = obs.obs_properties_add_bool(props, "active", "Enable Switching")
    local enable_audio_op = obs.obs_properties_add_bool(props, "audio", "Enable Audio Switching")
    obs.obs_property_set_long_description(enable_op, "Enable if you want Switchlite to automatically switch sources to target the currently focused RuneLite client. Disable if you want Switchlite to stop.")
    obs.obs_property_set_long_description(enable_audio_op, "Enable this if you want Switchlite to switch the audio source target in addition to video. Only functions if Enable Switching is also checked.")

    -- Help buttons
    local info_button = obs.obs_properties_add_button(props, "open_github", "Help", no_op)
    local issue_button = obs.obs_properties_add_button(props, "report_issue", "Issues", no_op)
    obs.obs_property_button_set_type(info_button, obs.OBS_BUTTON_URL)
    obs.obs_property_button_set_type(issue_button, obs.OBS_BUTTON_URL)
    obs.obs_property_button_set_url(info_button, "https://github.com/mlgudi/switchlite")
    obs.obs_property_button_set_url(issue_button, "https://github.com/mlgudi/switchlite/issues")

    return props
end

-- Timer must be removed on script unload, otherwise OBS hangs when closed.
function script_unload()
    obs.timer_remove(update_source_task)
end
