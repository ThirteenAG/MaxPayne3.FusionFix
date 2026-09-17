// Fullscreen pass-through vertex shader used by every PostFX pass.
// Position and texcoord are supplied in clip space, the SMAA offsets are
// derived from the texcoord in the pixel shaders themselves so that a single
// vertex shader serves all passes on all renderers.

#include "PostFXCommon.hlsl"

PostFXVSOutput VSMain(PostFXVSInput In)
{
    PostFXVSOutput Out;

    Out.Position = In.Position;
    Out.TexCoord = In.TexCoord;

    return Out;
}
