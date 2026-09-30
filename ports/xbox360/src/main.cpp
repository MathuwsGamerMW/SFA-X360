#include <xtl.h>

static IDirect3D9* gDirect3D = NULL;
static IDirect3DDevice9* gDevice = NULL;

static HRESULT InitializeGraphics()
{
    gDirect3D = Direct3DCreate9(D3D_SDK_VERSION);
    if (gDirect3D == NULL)
    {
        return E_FAIL;
    }

    D3DPRESENT_PARAMETERS parameters;
    ZeroMemory(&parameters, sizeof(parameters));
    parameters.BackBufferWidth = 1280;
    parameters.BackBufferHeight = 720;
    parameters.BackBufferFormat = D3DFMT_A8R8G8B8;
    parameters.BackBufferCount = 1;
    parameters.MultiSampleType = D3DMULTISAMPLE_NONE;
    parameters.SwapEffect = D3DSWAPEFFECT_DISCARD;
    parameters.EnableAutoDepthStencil = TRUE;
    parameters.AutoDepthStencilFormat = D3DFMT_D24S8;
    parameters.PresentationInterval = D3DPRESENT_INTERVAL_ONE;

    return gDirect3D->CreateDevice(
        0,
        D3DDEVTYPE_HAL,
        NULL,
        D3DCREATE_HARDWARE_VERTEXPROCESSING,        &parameters,
        &gDevice);
}

static void RunFrame()
{
    gDevice->Clear(
        0,
        NULL,
        D3DCLEAR_TARGET | D3DCLEAR_ZBUFFER,
        D3DCOLOR_XRGB(16, 48, 96),
        1.0f,
        0);
    gDevice->Present(NULL, NULL, NULL, NULL);
}

int __cdecl main()
{
    OutputDebugStringA("SFA-X360 bootstrap: start\n");

    HRESULT result = InitializeGraphics();
    if (FAILED(result))
    {
        OutputDebugStringA("SFA-X360 bootstrap: graphics init failed\n");
        return 1;
    }

    OutputDebugStringA("SFA-X360 bootstrap: graphics ready\n");

    for (;;)
    {
        RunFrame();
    }
}