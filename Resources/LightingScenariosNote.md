## Baked Lighting
MainScene.exr is a placeholder, an actual bake is around 250 MB and cannot be uploaded to Github. You'll have to bake yourself if you want to used baked lighting.  
  
To bake lighting:  
1. Select the Light Change Utility node and select Load Baked Lighting  
2. Select the LightmapGI node that gets loaded and click Bake Lightmaps  
  
Why is this process a bit convoluted?  
Having a LightmapGI node in the inspector, even when `visible` is disabled, prevents SDFGI from working. Both in game and in editor.  
So to keep SDFGI on, the LightmapGI node needs to be deleted.  
Make sure to Unload Baked Lighting before launching the game from the editor - the in game lightmap loader/unloader cannot unload the lightmap loaded *in* editor, so SDFGI just won't work in game if you forget to Unload Baked Lighting.  
  
## Luminosity Notes
We use "filmic" color temps and sun angles (except for noon), since the level is surrounded by tall buildings and realistic sun angles would leave all of the level in shadow. Luminosity values are still reference though.  
For night time, we start from a reference of dim residential area streetlights at 3000 lumens and futz good looking luminosities from the other lights in the scene. So night light values aren't fully reference, but they should still be roughly realistic.  
For moonlight as well, we use non-realistic "filmic" luminosity values in addition to the "filmic" color temp... reference values for night time are 0.3 lux for the moon with a 4000k temp, and 0.09 nits for the sky. It goes much lower than that when it isn't a full moon, or if it's a cloudy night.  
Godot can handle those values just fine... it's just that they don't look very good.
