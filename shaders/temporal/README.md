# Deferred motion vectors

These containers were copied from MaxPayne3.FusionShaders. Only deferred
geometry programs are changed; the remaining programs are included because
the compiler rebuilds complete containers.

Vertex shaders evaluate the previous clip position using previous draw
constants. Pixel shaders store previous-minus-current UV motion in a separate
R16G16F target. The game's four G-buffer outputs remain unchanged, including
the fourth target's emissive lighting and stencil information.
The pixel parameters contain inverse viewport size followed by current-minus-
previous projection jitter in UV units. Both the current and previous object
transforms must include their respective camera projection jitter.

Projection jitter is applied only to the render queue's viewport copies. The
game camera and its culling projection remain unchanged. The scene camera is
the viewport bound at the frame's first G-buffer draw. Every perspective
viewport with the scene camera's lens uses the frame's sample until the
resolve. TAA reconstructs current color and saved
depth onto the unjittered pixel grid, including frames without valid history.

On DX11, `TemporalPrevious` and `TemporalPixel` use the highest available
constant-buffer slot in each program. Previous variable names encode the
original buffer slot and byte offset, for example
`Temporal_b0_o128_gWorldViewProj`. Runtime reflection must use each compiled
program's actual binding and variable offsets.
Motion vectors use `SV_Target4`, attached alongside the four native targets.

Tessellated geometry carries previous vertex attributes through the hull
stage. The domain shader evaluates the previous surface at the same domain
location using previous constants and resources, including displacement.
Dynamic resources, including cloth buffers, receive previous-frame copies.

The runtime tracks draws by entity, geometry and shader, uploads previous
constants to the reflected bindings, and restores the game's bindings after
each draw. New draws and incomplete histories produce invalid motion; the
resolve then uses camera motion from depth. Disabling temporal AA preserves the original output.

Low-quality and displacement profiles share unchanged sources with the base
profile through relative paths in the container XML. Temporal AA requires the
DX11 renderer and MSAA off. Multisample and stereo profiles are excluded.

HDR uses an FP16 flip-model swap chain with linear scRGB presentation. The
game composites its scene and interface before the final output conversion;
paper white and peak brightness are saved in the plugin settings. HDR can only
be chosen on the DirectX 11 renderer with the game window on a display in
Windows HDR mode; otherwise the game starts with its SDR swap chain. A display
that leaves HDR mode during the session receives clamped SDR color in linear
scRGB.

TAA, DLAA and FSR resolve the linear scene buffer that the game's post
processing reads, after the subsample-alpha combine. Subsample-alpha and
stippled transparency keep the game's original patterns. DLSS receives the colour through a
reversible max-channel compression, which keeps small highlights; FSR receives
linear HDR colour. Bloom, tone mapping, menu compositing and
the interface run afterwards. The swap-chain image is never fed back through
temporal AA. SDR and HDR presentation share this linear scene resolve; the SDR
console gamma presets are bypassed while HDR output is active.
