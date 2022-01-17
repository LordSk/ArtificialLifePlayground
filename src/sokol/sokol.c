#define SOKOL_IMPL
#define SOKOL_ZIG_BINDINGS
#define SOKOL_NO_ENTRY
#if defined(_WIN32)
    #define SOKOL_WIN32_FORCE_MAIN
    #define SOKOL_D3D11
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
