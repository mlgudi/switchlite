# switchlite for OBS
OBS script for switching between multiple RuneLite clients without setting up a scene/source for each client/account.

Once set up, you will never need to create new scenes/sources for additional accounts. With the script active, OBS should detect and switch to your currently focused RuneLite client (if you are logged in).

Only tested with Python 3.10 and OBS 29.1. Not a clue if this is compatible with other versions.

### Why

Auto scene switcher requires a new scene for every logged in account you wish to record. This is a pain, especially if you change account names and regularly have to update your triggers/scenes.

This script requires only one scene and one window capture source. It updates the target of the window capture rather than switching between scenes. It records any currently selected RuneLite (if it is logged in).

### Pre-requisites

You need Python 64-bit installed with the pywin32 library.

1. **Install Python**: If you don't have it, download and install Python from [python.org](https://www.python.org/downloads/).

2. **Install pywin32**: Open Command Prompt and run the following command:
    ```bash
    pip install pywin32
    ```
3. **Download the script**: Clone or download the [OBS script](https://github.com/mlgudi/switchlite/blob/main/switchlite.py).

**You must also set RuneLite to include display names in the window title for this script to work. This can be found in the RuneLite plugin configuration.**

### OBS Setup

You need to set your Python installation in OBS, load the script, and create the scene/source.

1. **Open OBS**

2. **Set Python installation**: Open Tools -> Scripts and go to the Python Settings tab. Ensure your Python installation path is selected. If it isn't, find where Python was installed and enter it.

3. **Load the script**: Go back to the Scripts tab and click + in the bottom left. Locate the script (switchlite.py) and select it.

4. **Create your RuneLite source**: Create a **window capture** source in a scene of your choosing. Set the Window Match Priority to "Match title, otherwise find window of same executable"

5. **Set the source in the script UI**: Open Tools -> Scripts and select switchlite.py. On the right, select your window capture as the RuneLite source. If you have an application audio capture for RuneLite, you can select that for the audio.

6. **Activate**: Ensure the "Active" checkbox is checked, as well as the "Application Audio" checkbox if you also have an application audio capture source.

With all that done, you should be good to go. If you have any problems, [drop me a tweet](https://twitter.com/MLGudi) and I will try to reply. Alternatively, submit an issue here, but I am not terribly active. If your issue is with Python/pywin32 installation, please ask ChatGPT to help you troubleshoot, as it will be much more helpful.

### Toggle Hotkey

You can set a hotkey to toggle the active state of the script, but it will not be reflected in the Tools -> Scripts UI.

Set the hotkey in the OBS settings menu under hotkeys. It is called "Toggle RuneLite Switcher".

To toggle it off indefinitely and across OBS sessions, use the Scripts -> Tools UI and uncheck the "Active" checkbox instead.
