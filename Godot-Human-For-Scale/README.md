# Godot-Human-For-Scale
Simple controllable character that you can use to run around in your level to get a sense of scale. No input bindings or camera set up necessary, just drag and drop into your scene. The character is 5'10. (177.8 cm)

https://github.com/Jamsers/Godot-Human-For-Scale/assets/39361911/ea40c6ec-47b0-43da-a2c2-1e5539d293f6

## How to use
1. Clone or download the Github repository.  
2. Move the repository folder (Godot-Human-For-Scale) to the root of your project.  
    ***The Godot-Human-For-Scale folder has to be at the root of your project for Godot-Human-For-Scale to work.***  
4. Drag and drop the player scene (Human-For-Scale.tscn) into the scene you want to walk around in.  
5. Run your scene.  

**Make sure your scene has colliders for the floor at least, or the player will just fall through the map!**

## Controls
ESCAPE to capture/uncapture mouse  

**Mouse is uncaptured on start!**  

WASD to move  
SHIFT to sprint  
SPACE to jump  
TILDE(~) to noclip  

V to switch third person/first person  
RIGHT CLICK to zoom/focus  
TAB to switch third person camera shoulders  

LEFT CLICK to shoot physics gun  

## Controls not working?

*Mouse look not working?* A Control node is likely capturing mouse input. Find that Control node, set its Mouse Filter to Pass/Ignore.  
*Keyboard controls not working?* A Control node is likely capturing keyboard input, most likely a button or text box. Find that Control node, set its Focus Mode to None.

## Extra Options

You can enable depth of field for the zoom functionality. No camera attributes setup necessary.  
You can disable the character's shadow in first person view.  
You can enable audio, which will enable the audio listener, footstep sounds, and physics interactions sounds.  
You can enable the physics gun, which throws a physics object of your choosing in front of you.

![human-for-scale-options](https://github.com/Jamsers/Godot-Human-For-Scale/assets/39361911/80a466c6-9890-41cf-8303-5225a2106b78)

## Credits

Uses the fantastic [mannequiny](https://github.com/GDQuest/godot-3d-mannequin/tree/master/godot/assets/3d/mannequiny) from GDQuest's [godot-3d-mannequin](https://github.com/GDQuest/godot-3d-mannequin).  
Uses Creative Commons sounds, attributions are [here](https://github.com/Jamsers/Godot-Human-For-Scale/blob/main/Assets/Audio/ATTRIBUTION).
