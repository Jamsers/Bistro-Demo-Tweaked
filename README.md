# Bistro-Demo-Tweaked
Bistro demo for [Godot](https://github.com/godotengine/godot) showcasing lighting and high quality assets.

https://github.com/Jamsers/Bistro-Demo-Tweaked/assets/39361911/67493ad0-d19c-40ab-ad07-4014dbd654a5

Includes [Godot-Human-For-Scale](https://github.com/Jamsers/Godot-Human-For-Scale) to run around the level, and an interface for changing the time of day, resolution scaling, and quality scaling. Appropriate objects in the level are set to dynamic and are physics enabled, to see the effects of lighting on dynamic objects as well.

## Usage
1. Clone or download the Github repository.
2. Download [Godot 4.x](https://godotengine.org/download/) and open the repository folder with Godot.
3. Run the project. (Play button on the upper right corner of Godot's interface)

## Releases
Windows: [Bistro-Demo-Tweaked-Windows.zip](https://github.com/Jamsers/Bistro-Demo-Tweaked/releases/download/v1.0/Bistro-Demo-Tweaked-Windows.zip)  
Mac: [Bistro-Demo-Tweaked-Mac.zip](https://github.com/Jamsers/Bistro-Demo-Tweaked/releases/download/v1.0/Bistro-Demo-Tweaked-Mac.zip)  
Linux: [Bistro-Demo-Tweaked-Linux.zip](https://github.com/Jamsers/Bistro-Demo-Tweaked/releases/download/v1.0/Bistro-Demo-Tweaked-Linux.zip)

To get past the "Apple cannot check it for malicious software" warning on Mac, follow the instructions [here](https://support.apple.com/guide/mac-help/mchleab3a043).

## Controls
- **ESCAPE** to capture/uncapture mouse  
  **H** to hide/unhide control panel UI

- **W-A-S-D** to move  
  **SHIFT** to sprint  
  **SPACE** to jump  
  **TILDE(~)** to noclip  

- **V** to switch third person/first person  
  **RIGHT CLICK** to zoom/focus

## *.res Files Reimported
When opening the project for the first time, you may notice hundreds of *.res files get modified in your source control. This is a quirk of the Godot importer and these changes can be safely discarded once project has already been opened once.

## Extra Options
Use the Light Change Utility node to change lighting scenarios in editor.  
Includes a profiler to see performance details. [RAM counter not available in release builds](https://docs.godotengine.org/en/stable/classes/class_performance.html#enumerations).  
You can turn music on or off in editor.

![lightchangeutility](https://github.com/Jamsers/Bistro-Demo-Tweaked/assets/39361911/09c0a406-e942-467e-8ecc-fb2eafc55f4e)

![ui](https://github.com/Jamsers/Bistro-Demo-Tweaked/assets/39361911/6d39b553-558b-4a63-8551-5e76681a9e90)

## Credits
Ported from [Amazon Lumberyard Bistro](https://developer.nvidia.com/orca/amazon-lumberyard-bistro).  
Original porting work done by [Logan Preshaw](https://github.com/WickedInsignia), original port can be found [here](https://github.com/godotengine/godot/issues/74965).  
Uses Creative Commons sounds, attributions are [here](https://github.com/Jamsers/Bistro-Demo-Tweaked/blob/main/Audio/ATTRIBUTION).
