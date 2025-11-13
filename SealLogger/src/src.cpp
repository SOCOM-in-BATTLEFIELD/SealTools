#include "def.h"
#include <exMemory/extensions/pcsx2/pcsx2Memory.hpp>

// Main code
int main()
{
    ImGui_ImplWin32_EnableDpiAwareness();
    float main_scale = ImGui_ImplWin32_GetDpiScaleForMonitor(::MonitorFromPoint(POINT{ 0, 0 }, MONITOR_DEFAULTTOPRIMARY));
    WNDCLASSEXW wc = { sizeof(wc), CS_CLASSDC, WndProc, 0L, 0L, GetModuleHandle(nullptr), nullptr, nullptr, nullptr, nullptr, L"SOCOM in BATTLEFIELD - COORDS GRABBER", nullptr };
    ::RegisterClassExW(&wc);
    g_WindowWidth = (int)(1280 * main_scale);
    g_WindowHeight = (int)(800 * main_scale);
    HWND hwnd = ::CreateWindowW(wc.lpszClassName, L"SOCOM in BATTLEFIELD", WS_OVERLAPPEDWINDOW, 100, 100, (int)(350 * main_scale), (int)(160 * main_scale), nullptr, nullptr, wc.hInstance, nullptr);
    if (!CreateDeviceD3D(hwnd))
    {
        CleanupDeviceD3D();
        ::UnregisterClassW(wc.lpszClassName, wc.hInstance);
        return 1;
    }
    ::ShowWindow(hwnd, SW_SHOWDEFAULT);
    ::UpdateWindow(hwnd);
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
    ImGui::StyleColorsDark();
    ImGuiStyle& style = ImGui::GetStyle();
    style.ScaleAllSizes(main_scale); 
    style.FontScaleDpi = main_scale; 
    ImGui_ImplWin32_Init(hwnd);
    ImGui_ImplDX11_Init(g_pd3dDevice, g_pd3dDeviceContext);
    bool done = false;
    while (!done)
    {
        MSG msg;
        while (::PeekMessage(&msg, nullptr, 0U, 0U, PM_REMOVE))
        {
            ::TranslateMessage(&msg);
            ::DispatchMessage(&msg);
            if (msg.message == WM_QUIT)
                done = true;
        }
        if (done)
            break;

        if (g_SwapChainOccluded && g_pSwapChain->Present(0, DXGI_PRESENT_TEST) == DXGI_STATUS_OCCLUDED)
        {
            ::Sleep(10);
            continue;
        }
        g_SwapChainOccluded = false;

        SetupFrame();
        {
            ImGui::SetNextWindowPos(ImVec2(0, 0));
            ImGui::SetNextWindowSize(ImVec2(g_WindowWidth, g_WindowHeight));
            ImGui::Begin("SOCOM in BATTLEFIELD - HELPER", (bool*)false, ImGuiWindowFlags_NoDecoration);
            SocomHelper();
            ImGui::End();
        }
        EndFrame();
    }
    ImGui_ImplDX11_Shutdown();
    ImGui_ImplWin32_Shutdown();
    ImGui::DestroyContext();
    CleanupDeviceD3D();
    ::DestroyWindow(hwnd);
    ::UnregisterClassW(wc.lpszClassName, wc.hInstance);
    return 0;
}

void SetupFrame()
{
    if (g_ResizeWidth != 0 && g_ResizeHeight != 0)
    {
        CleanupRenderTarget();
        g_pSwapChain->ResizeBuffers(0, g_ResizeWidth, g_ResizeHeight, DXGI_FORMAT_UNKNOWN, 0);
        g_WindowWidth = g_ResizeWidth;
        g_WindowHeight = g_ResizeHeight;
        g_ResizeWidth = g_ResizeHeight = 0;
        CreateRenderTarget();
    }
    ImGui_ImplDX11_NewFrame();
    ImGui_ImplWin32_NewFrame();
    ImGui::NewFrame();
}

void EndFrame()
{
    static const ImVec4 clear_color = ImVec4(0.45f, 0.55f, 0.60f, 1.00f);

    ImGui::Render();
    const float clear_color_with_alpha[4] = { clear_color.x * clear_color.w, clear_color.y * clear_color.w, clear_color.z * clear_color.w, clear_color.w };
    g_pd3dDeviceContext->OMSetRenderTargets(1, &g_mainRenderTargetView, nullptr);
    g_pd3dDeviceContext->ClearRenderTargetView(g_mainRenderTargetView, clear_color_with_alpha);
    ImGui_ImplDX11_RenderDrawData(ImGui::GetDrawData());
    HRESULT hr = g_pSwapChain->Present(1, 0);   // Present with vsync
    //HRESULT hr = g_pSwapChain->Present(0, 0); // Present without vsync
    g_SwapChainOccluded = (hr == DXGI_STATUS_OCCLUDED);
}

void SocomHelper()
{
    static pcsx2Memory mem = pcsx2Memory();	//	attach to pcsx2 "pcsx2-qt.exe
    static i64_t gCRCBase{ 0 };
    static int iSelectedGame{ -1 };
    static std::vector<VEC3_T> origins;
    static bool bRestoredForceStartPatch{ false };

    /* get process info */
    auto pInfo = mem.psxGetInfo();		//	gets pcsx2 process information
    if (!pInfo.bAttached)				//	check if attached
    {
        ImGui::TextColored(ImVec4(1, 1, 0, 1), "PCSX2 PROCESS NOT FOUND");
		mem = pcsx2Memory(); // attempt to reattach to pcsx2 process
        return;
    }

    /* find CRC base 
	FindPatternEx will search for the signature in the pcsx2 process and return the address of the CRC static variable
	This probably won't change as this static variable is used quite often in the pcsx2 codebase.
	We use the ASM_CMP instruction only because the FindPatternEx function uses it to calculate the offset to the variable.
	the ASM_MOV is expecting to move RAX / RCX which is not the case here and would return an incorrect offset. (+1)
    CMP works only because it offsets 6 bytes which is the size of our instruction.
     
     CRC_PATTERN: "8B 35 ? ? ? ? 48 8D 0D ? ? ? ? E8 ? ? ? ? 85 C0 0F 85 ? ? ? ? 81 3D ? ? ? ? ? ? ? ? 0F 84 ? ? ? ? 8B 3D"
        
		Assembly reference:
		.text:0000000140001A7E 8B 35 30 99 08 03        mov     esi, cs:m_CRC_3             <-- CRC static variable
        .text:0000000140001A84 48 8D 0D D5 98 08 03     lea     rcx, dword_14308B360 ; _Mtx_t
        .text:0000000140001A8B E8 10 EE B2 00           call    _Mtx_lock
    */

	/* find crc base if not found yet , should only be done once */
    if (!gCRCBase && !exMemory::FindPatternEx(pInfo.hProc, pInfo.dwModuleBase, CRC_PATTERN, &gCRCBase, 0, EASM::ASM_CMP))
    {
		ImGui::TextColored(ImVec4(1, 0, 0, 1), "FAILED TO FIND CRC BASE");
		mem = pcsx2Memory(); // attempt to reattach to pcsx2 process
        return;
    }

    /* get game */
	ImGui::Combo("SELECT GAME", &iSelectedGame, "SOCOM 1\0SOCOM 2\0SOCOM 3\0SOCOM CA\0");
    if (ImGui::IsItemHovered())
        ImGui::SetTooltip("select the current game running on pcsx2.");

    /* compare CRC with selected game */
	auto crc_base = mem.Read<unsigned __int32>(gCRCBase); // read crc value from memory
	if (!crc_base || crc_base != gCRC[iSelectedGame])
    {
        ImGui::TextColored(ImVec4(1, 1, 0, 1), "GAME CRC MISMATCH");
		ImGui::Text("EXPECTED: 0x%08X", gCRC[iSelectedGame]);
		ImGui::Text("FOUND:    0x%08X", crc_base);
        return;
    }

    /* handle unsupported games */
    switch (iSelectedGame)
    {
    case(E_SEAL_S1): break;
    case(E_SEAL_S2): break;
    case(E_SEAL_S3):
        ImGui::TextColored(ImVec4(1, 0, 0, 1), "SOCOM 3 NOT SUPPORTED");
        return;
    case(E_SEAL_CA): break;
    default:
        ImGui::TextColored(ImVec4(1, 1, 0, 1), "SELECT A GAME");
        return;
    }

    /* VARIABLES FOR DIFFERENT GAMES */
    auto addr = iForceStart[iSelectedGame];
    auto cmp = iForceStart_original[iSelectedGame];
    auto new_value = iForceStart_patch[iSelectedGame];

    /* Get Local Player */
    const auto pSEAL = mem.psxRead<unsigned __int32>(pLocalSeal[iSelectedGame]);
    if (pSEAL == 0) /* handle lobby state */
    {

        /* FORCE START */
        bool bPlayerInLobby{ false };

        switch (iSelectedGame)
        {
        case(E_SEAL_S1):
            bPlayerInLobby = mem.psxRead<unsigned __int32>(addr) == cmp;
			break;
        case(E_SEAL_S2):
            bPlayerInLobby = mem.psxRead<unsigned __int32>(addr) == cmp;
			break;
		case(E_SEAL_CA):
            bPlayerInLobby = mem.psxRead<unsigned __int8>(addr) == cmp;
            break;
        }

        /* */
        if (bPlayerInLobby) // user is in a lobby and waiting for players to ready up
        {
            ImGui::TextColored(ImVec4(1, 1, 0, 1), "PLAYER IN LOBBY");
            if (ImGui::Button("ENABLE FORCE START ( LAN )"))
            {
                bRestoredForceStartPatch = false;
                mem.psxWrite(addr, new_value); // force starts the match
                printf("[+] patched bytes to force start the match.\n");
            }
        }
        else
            ImGui::TextColored(ImVec4(1, 1, 0, 1), "WAITING FOR LOBBYSTATE OR LOCAL PLAYER");
        
        /* early return */
        return;
    }

    /* restore force start byte patch */
    // this is done only after the seal is valid (in-game) & force start patch is applied
    if (iSelectedGame == E_SEAL_S1 || iSelectedGame == E_SEAL_S2)
    {
        if (!bRestoredForceStartPatch && mem.psxRead<unsigned __int32>(addr) == new_value) // check if force start patch is applied
        {
            mem.psxWrite<unsigned __int32>(addr, cmp); // restore patches bytes so we can force start sometime later
            printf("restored patched bytes.\n");
            bRestoredForceStartPatch = true;
        }
    }

    /* GET SEAL OBJECT */
    const auto& SEAL = mem.psxRead<CZSEAL_T>(pSEAL);

    /* RENDER */
    static float scalar = 12.f;
    {
        if (ImGui::Button("ADD POSITION TO LIST"))
        {
            origins.push_back(SEAL.mOrigin);
            printf("[+] added position to list. new size: %d\n", origins.size());
        }
        ImGui::SameLine();
        ImGui::Text("%.2f, %.2f, %.2f", SEAL.mOrigin.x, SEAL.mOrigin.y, SEAL.mOrigin.z);

        if (ImGui::Button("LIST SAVED POSITIONS"))
        {
            if (origins.size() > 0)
            {
                system("CLS");
                printf("[+] dumping list of positions => (size=%d|scale=%.0f).\n", origins.size(), scalar);
                for (int i = 0; i < origins.size(); i++)
                {
                    const auto count = i + 1;

                    const auto origin = origins[i] / scalar; // apply scaling factor to origin

                    printf("%.2f,%.2f,%.2f\n", origin.x, origin.y, origin.z);
                }
            }
            else
                printf("[!] failed to dump list of saved positions as the container is empty.\n");
        }
        ImGui::SameLine();

        ImGui::SetNextItemWidth(ImGui::GetContentRegionAvail().x);
        ImGui::SliderFloat("##SCALE", &scalar, 1.f, 20.f, "%.0f");
        if (ImGui::IsItemHovered())
            ImGui::SetTooltip("\'CTRL + CLICK\' to set custom input");

        ImGui::Separator();
        if (ImGui::Button("CLEAR SAVED POSITIONS", ImVec2(ImGui::GetContentRegionAvail().x, ImGui::GetTextLineHeightWithSpacing())))
        {
            origins.clear();
            printf("[+] cleared the list of saved positions.\n");
        }
    }
}

// Helper functions

bool CreateDeviceD3D(HWND hWnd)
{
    // Setup swap chain
    // This is a basic setup. Optimally could use e.g. DXGI_SWAP_EFFECT_FLIP_DISCARD and handle fullscreen mode differently. See #8979 for suggestions.
    DXGI_SWAP_CHAIN_DESC sd;
    ZeroMemory(&sd, sizeof(sd));
    sd.BufferCount = 2;
    sd.BufferDesc.Width = 0;
    sd.BufferDesc.Height = 0;
    sd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    sd.BufferDesc.RefreshRate.Numerator = 60;
    sd.BufferDesc.RefreshRate.Denominator = 1;
    sd.Flags = DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;
    sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    sd.OutputWindow = hWnd;
    sd.SampleDesc.Count = 1;
    sd.SampleDesc.Quality = 0;
    sd.Windowed = TRUE;
    sd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;

    UINT createDeviceFlags = 0;
    //createDeviceFlags |= D3D11_CREATE_DEVICE_DEBUG;
    D3D_FEATURE_LEVEL featureLevel;
    const D3D_FEATURE_LEVEL featureLevelArray[2] = { D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_0, };
    HRESULT res = D3D11CreateDeviceAndSwapChain(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, createDeviceFlags, featureLevelArray, 2, D3D11_SDK_VERSION, &sd, &g_pSwapChain, &g_pd3dDevice, &featureLevel, &g_pd3dDeviceContext);
    if (res == DXGI_ERROR_UNSUPPORTED) // Try high-performance WARP software driver if hardware is not available.
        res = D3D11CreateDeviceAndSwapChain(nullptr, D3D_DRIVER_TYPE_WARP, nullptr, createDeviceFlags, featureLevelArray, 2, D3D11_SDK_VERSION, &sd, &g_pSwapChain, &g_pd3dDevice, &featureLevel, &g_pd3dDeviceContext);
    if (res != S_OK)
        return false;

    CreateRenderTarget();
    return true;
}

void CleanupDeviceD3D()
{
    CleanupRenderTarget();
    if (g_pSwapChain) { g_pSwapChain->Release(); g_pSwapChain = nullptr; }
    if (g_pd3dDeviceContext) { g_pd3dDeviceContext->Release(); g_pd3dDeviceContext = nullptr; }
    if (g_pd3dDevice) { g_pd3dDevice->Release(); g_pd3dDevice = nullptr; }
}

void CreateRenderTarget()
{
    ID3D11Texture2D* pBackBuffer;
    g_pSwapChain->GetBuffer(0, IID_PPV_ARGS(&pBackBuffer));
    g_pd3dDevice->CreateRenderTargetView(pBackBuffer, nullptr, &g_mainRenderTargetView);
    pBackBuffer->Release();
}

void CleanupRenderTarget()
{
    if (g_mainRenderTargetView) { g_mainRenderTargetView->Release(); g_mainRenderTargetView = nullptr; }
}

LRESULT WINAPI WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    if (ImGui_ImplWin32_WndProcHandler(hWnd, msg, wParam, lParam))
        return true;

    switch (msg)
    {
    case WM_SIZE:
        if (wParam == SIZE_MINIMIZED)
            return 0;
        g_ResizeWidth = (UINT)LOWORD(lParam); // Queue resize
        g_ResizeHeight = (UINT)HIWORD(lParam);
        return 0;
    case WM_SYSCOMMAND:
        if ((wParam & 0xfff0) == SC_KEYMENU) // Disable ALT application menu
            return 0;
        break;
    case WM_DESTROY:
        ::PostQuitMessage(0);
        return 0;
    }
    return ::DefWindowProcW(hWnd, msg, wParam, lParam);
}