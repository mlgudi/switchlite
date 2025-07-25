# switchlite for OBS
OBS script for switching between multiple RuneLite clients without setting up a scene/source for each client/account.

Once set up, you will never need to create new scenes/sources for additional accounts. With the script active, OBS should detect and switch to your currently focused RuneLite client (if you are logged in).

![image](/img/switchlite_example.gif)

The new version has been lightly tested with OBS version 30 on Windows 10 and 11. If you encounter problems, please [submit an issue](https://github.com/mlgudi/switchlite/issues).

### Why

Auto scene switcher requires a new scene and window capture for every OSRS account you wish to record. This is a pain, especially if you change account names and regularly have to update your triggers/scenes.

This script requires only one scene and one window capture source. An application audio source can also be set up.

It updates the target of the window/audio capture, rather than switching to a different scene. It records any currently focused and logged in RuneLite client.

## Setup

Getting Switchlite up and running takes very little time. Everything you might need to do is listed below, including instructions for installing the script in OBS.

### Configuring RuneLite

For Switchlite to function, you must enable RuneLite's "Show display name in title" option.

This can be found in the main RuneLite plugin configuration:

![image](/img/show_display_name_in_title.png)

### Creating Compatible Sources

Switchlite supports only two kinds of OBS sources: Window Capture and Application Audio Capture.

Both can be added by right-clicking inside the "Sources" panel, then hovering the "Add" option:

![image](/img/add_sources.png)

**Window Match Priority**

To ensure your sources can be used by Switchlite, select "Window title must match" for the "Window Match Priority" property of the source(s):

![image](/img/window_match_priority.png)

**Capture Audio (BETA)**

Recent versions of OBS include a "Capture Audio (BETA)" property for window capture sources.

I recommend **disabling** this option and, instead, manually creating an application audio capture source. It doesn't seem to reliably update when the target window is modified by Switchlite.

### Switchlite Setup

With your sources set up, installing Switchlite only takes a few seconds. Do the following:

1. **Download the script**: Download [switchlite.lua](switchlite.lua) and save it anywhere. Ideally, somewhere you won't lose or accidentally delete it.

2. **Open the Scripts UI**: In the menu bar at the top of OBS, select Tools -> Scripts. A small scripts UI will appear.

![image](/img/tools_scripts.png)

3. **Load the script**: Click the + button in the bottom left of the scripts UI and select switchlite.lua.

![image](/img/scripts_ui.png)

4. **Select your sources and enable**: Select your RuneLite window capture source from the "RuneLite Source" drop down, and application audio capture source from the "RuneLite Audio Source" drop down if capturing audio. Finally, check the "Enable Switching" checkbox - as well as the "Enable Audio Switching" if you have an audio source.

![image](/img/script_ui_setup.png)

With all that done, you should be good to go. Clicking between two RuneLite clients - both logged in - should result in the targeted window being captured.

If you have any problems, [drop me a tweet](https://x.com/MLGudi) or [submit an issue](https://github.com/mlgudi/switchlite/issues).

### Linux

Most OSRS players/content creators run Windows, including myself, so it was written to work on Windows.

I do have a version of Switchlite functional on Linux Mint 22.1, but I haven't thoroughly tested it and didn't want to bloat a minimal script for one imaginary Linux user.

If there is anyone who might actually make use of it, let me know.
