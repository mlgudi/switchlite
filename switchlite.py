import re
import obspython as obs
from win32gui import GetWindowText, GetForegroundWindow

hotkey_id, active, audio, source, audio_source, interval, last_account = None, False, True, "", "", 100, ""

def update_source():
    global last_account, active
    if not active: return

    focused_window = GetWindowText(GetForegroundWindow())
    match = re.search(r'RuneLite - (.*)', focused_window)
    if not match: return

    new_account = match.group(1)
    if new_account == last_account: return
    last_account = new_account

    current_scene_as_source = obs.obs_frontend_get_current_scene()
    current_scene = obs.obs_scene_from_source(current_scene_as_source)
    scene_item = obs.obs_scene_find_source_recursive(current_scene, source)

    if scene_item:
        switch_window(scene_item, new_account)
        if audio:
            scene_item = obs.obs_scene_find_source_recursive(current_scene, audio_source)
            if scene_item: switch_window(scene_item, new_account)
    
    obs.obs_source_release(current_scene_as_source)

def switch_window(scene_item, new_account):
    source_obj = obs.obs_sceneitem_get_source(scene_item)
    current_settings = obs.obs_source_get_settings(source_obj)
    current_window = obs.obs_data_get_string(current_settings, "window")

    new_window = re.sub(r'(RuneLite - )(.*?)(:.*)', fr'\1{new_account}\3', current_window)
    settings = obs.obs_data_create()
    obs.obs_data_set_string(settings, "window", new_window)
    obs.obs_source_update(source_obj, settings)

    obs.obs_data_release(current_settings)
    obs.obs_data_release(settings)

def on_auto_rl_hotkey(pressed):
    global active
    if pressed:
        active = not active
        settings = obs.obs_data_create()
        obs.obs_data_set_bool(settings, "active", active)
        script_update(settings)
        obs.obs_data_release(settings)

def script_description():
    return '''Updates RuneLite window capture as you change client.
Can be toggled active/inactive using a hotkey. Set the hotkey in OBS settings.
Requires pywin32'''

def script_load(settings):
    global hotkey_id
    hotkey_id = obs.obs_hotkey_register_frontend(script_path(), "Toggle RuneLite Switcher", on_auto_rl_hotkey)
    hotkey_save_array = obs.obs_data_get_array(settings, "auto_rl_hotkey")
    obs.obs_hotkey_load(hotkey_id, hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)

def script_save(settings):
    global hotkey_id
    hotkey_save_array = obs.obs_hotkey_save(hotkey_id)
    obs.obs_data_set_array(settings, "auto_rl_hotkey", hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)

def script_update(settings):
    global active, audio, source, audio_source, interval, last_account
    active = obs.obs_data_get_bool(settings, "active")
    audio = obs.obs_data_get_bool(settings, "audio")
    source = obs.obs_data_get_string(settings, "source")
    audio_source = obs.obs_data_get_string(settings, "audio_source")
    interval = obs.obs_data_get_int(settings, "interval")
    last_account = obs.obs_data_get_string(settings, "last_account")

    obs.timer_remove(update_source)
    if source != "":
        obs.timer_add(update_source, interval)

def script_defaults(settings):
    obs.obs_data_set_default_int(settings, "interval", 100)

def script_properties():
    props = obs.obs_properties_create()
    p = obs.obs_properties_add_list(props, "source", "RuneLite Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
    sources = obs.obs_enum_sources()
    if sources:
        for source in sources:
            source_id = obs.obs_source_get_unversioned_id(source)
            if source_id == "window_capture":
                name = obs.obs_source_get_name(source)
                obs.obs_property_list_add_string(p, name, name)
        obs.source_list_release(sources)
    
    ap = obs.obs_properties_add_list(props, "audio_source", "App Audio Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
    audio_sources = obs.obs_enum_sources()
    if audio_sources:
        for source in audio_sources:
            source_id = obs.obs_source_get_unversioned_id(source)
            if source_id == "wasapi_process_output_capture":
                name = obs.obs_source_get_name(source)
                obs.obs_property_list_add_string(ap, name, name)
        obs.source_list_release(audio_sources)
    
    obs.obs_properties_add_int(props, "interval", "Update Interval (ms)", 50, 3000, 25)
    obs.obs_properties_add_bool(props, "active", "Active")
    obs.obs_properties_add_bool(props, "audio", "Application Audio")
    return props
