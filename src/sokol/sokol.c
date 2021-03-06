#define SOKOL_IMPL
#define SOKOL_ZIG_BINDINGS
#define SOKOL_NO_ENTRY
#if defined(_WIN32)
    #define SOKOL_WIN32_FORCE_MAIN
    #define SOKOL_D3D11 // can't disable vsync on d3d11
    //#define SOKOL_GLCORE33
    #define SOKOL_LOG(msg) OutputDebugStringA(msg)
#elif defined(__APPLE__)
    #define SOKOL_METAL
#else
    #define SOKOL_GLCORE33
#endif
#include "c/sokol_app.h"
#include "c/sokol_gfx.h"
#include "c/sokol_time.h"
#include "c/sokol_audio.h"

#define CIMGUI_DEFINE_ENUMS_AND_STRUCTS
#include "c/cimgui.h"
#define SOKOL_IMGUI_IMPL
#include "c/sokol_imgui.h"
