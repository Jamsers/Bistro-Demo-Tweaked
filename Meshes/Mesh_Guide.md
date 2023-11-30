## To create ColOcc:
 - Import GLB
 - Delete irrelevant meshes
 - Join all
 - Shade flat
 - Merge by distance
 - Degenerate dissolve
 - Delete loose
 - Decimate 0.15
 - Merge by distance
 - Degenerate dissolve
 - Delete loose
 - Set origin to center of mass
 
## *_Props.glb import:
 - Set light baking to dynamic
 - Should have meshes extracted since you'll have to break inheritance to create rigidbodies for them anyway
 
## *_ColOcc.glb import:
 - Generate physics
 - Occluder: Mesh + Occluder (physics don't get generated otherwise)
 - Shape type: Trimesh
