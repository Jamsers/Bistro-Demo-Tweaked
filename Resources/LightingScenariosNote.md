MainScene.exr is a placeholder, an actual bake is around 250 MB and cannot be uploaded to Github. You'll have to bake yourself if you want to used baked lighting.  
  
To bake lighting:  
1. Select the Light Change Utility node and select Load Baked Lighting  
2. Right click the LightmapGI node that gets loaded and select Make Local  
3. Select the LightmapGI node and click Bake Lightmaps  
4. Once baking is done, right click the LightmapGI node and click Save Branch as Scene  
5. Overwrite Scenes/Lightmap.tscn  
6. Delete the LightmapGI node in the inspector  
7. Select the Light Change Utility node and select Unload Baked Lighting  
  
Why this convoluted ass process? Having a LightmapGI node in the inspector, even when `visible` is disabled, prevents SDFGI from working. Both in game and in editor.  
  
We use "filmic" color temps and sun angles (except for noon), since the level is surrounded by tall buildings and realistic sun angles would leave all of the level in shadow. Luminosity values are still reference though.  
For night time, we start from a reference of dim residential area streetlights at 3000 lumens and futz good looking luminosities from the other lights in the scene. So night light values aren't fully reference, but they should still be roughly realistic.  
For moonlight as well, we use non-realistic "filmic" luminosity values in addition to the "filmic" color temp... reference values for night time are 0.3 lux for the moon with a 4000k temp, and 0.09 nits for the sky. It goes much lower than that when it isn't a full moon, or if it's a cloudy night.  
Godot can handle those values just fine... it's just that they don't look very good.
