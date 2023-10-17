extends Resource

class_name Settings

@export var sun_angle: float = 0.0
@export var ssr: bool = false
@export var ssao: bool = false
@export var ssil: bool = false
@export var sdfgi: bool = false
@export var night_shadows: bool = false
@export var msaa: Viewport.MSAA = Viewport.MSAA_DISABLED
@export var fxaa: RenderingServer.ViewportScreenSpaceAA = RenderingServer.VIEWPORT_SCREEN_SPACE_AA_DISABLED
@export var scaling: RenderingServer.ViewportScaling3DMode = RenderingServer.VIEWPORT_SCALING_3D_MODE_BILINEAR
