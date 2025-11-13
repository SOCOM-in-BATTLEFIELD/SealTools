#pragma once

/* System */
#include <Windows.h>
#include <iostream>
#include <string>
#include <vector>

/* JSON for exporting */

/* Rendering */
#include <imgui.h>
#include <imgui_impl_win32.h>
#include <imgui_impl_dx11.h>
#include <d3d11.h>
#include <tchar.h>

#pragma comment(lib, "d3d11.lib")

#define CRC_PATTERN "8B 35 ? ? ? ? 48 8D 0D ? ? ? ? E8 ? ? ? ? 85 C0 0F 85 ? ? ? ? 81 3D ? ? ? ? ? ? ? ? 0F 84 ? ? ? ? 8B 3D"

// Render Data
static ID3D11Device*            g_pd3dDevice = nullptr;
static ID3D11DeviceContext*     g_pd3dDeviceContext = nullptr;
static IDXGISwapChain*          g_pSwapChain = nullptr;
static bool                     g_SwapChainOccluded = false;
static UINT                     g_ResizeWidth = 0, g_ResizeHeight = 0;
static UINT						g_WindowWidth = 0, g_WindowHeight = 0;
static ID3D11RenderTargetView*  g_mainRenderTargetView = nullptr;

// Forward declarations of helper functions
bool CreateDeviceD3D(HWND hWnd);
void CleanupDeviceD3D();
void CreateRenderTarget();
void CleanupRenderTarget();
LRESULT WINAPI WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);
void SetupFrame();
void EndFrame();
void SocomHelper();

// Forward declare message handler from imgui_impl_win32.cpp
extern IMGUI_IMPL_API LRESULT ImGui_ImplWin32_WndProcHandler(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

/* ENUMS */
enum E_SEAL_GAME
{
	E_SEAL_S1 = 0,
	E_SEAL_S2,
	E_SEAL_S3,
	E_SEAL_CA
};

/* STRUCTURES */

/* container for position coordinates among other things */
typedef struct _VEC_3
{
	float x, y, z;

	_VEC_3 operator+(const _VEC_3& v) const
	{
		return { x + v.x, y + v.y, z + v.z };
	}

	_VEC_3 operator-(const _VEC_3& v) const
	{
		return { x - v.x, y - v.y, z - v.z };
	}

	_VEC_3 operator*(float f) const
	{
		return { x * f, y * f, z * f };
	}

	_VEC_3 operator/(float f) const
	{
		return { x / f, y / f, z / f };
	}
} VEC3_T, * PVEC3_T;

/* player object container */
typedef struct _CZ_SEAL
{
	__int32 vfTable; //0x0000
	char pad_0004[16]; //0x0004
	__int32 pName; //0x0014
	char pad_0018[4]; //0x0018
	VEC3_T mOrigin; //0x001C	<----- player position
	char pad_0028[176]; //0x0028
	uint32_t mTeamID; //0x00D8
} CZSEAL_T , * PCZSEAL_T; //Size: 0x00DC
static_assert(sizeof(_CZ_SEAL) == 0xDC);

/* OFFSETS */

static constexpr unsigned __int32 gCRC[] =
{
	0x6F4056DB,		// S1
	0x0F6FC6CF,		// S2
	0x75ED4282,		// S3
	0xD7CFDCCF		// CA
};

/* pointer to local player object 
	type: CZSEAL_T
*/
static constexpr unsigned __int32 pLocalSeal[] = 
{
	0x48D548,		// S1
	0x44D648,		// S2
	0x0,			// S3 (not supported)
	0x709D98		// CA
};

/* instruction which can be manipulated to force start the match */
static constexpr unsigned __int32 iForceStart[] = 
{
	0x1F66F4,		// S1
	0x408868, 		// S2
	0x0,			// S3 (not supported)
	0xA7675C		// CA
};

/* original bytes */
static constexpr unsigned __int32 iForceStart_original[] =
{
	0x24845900,		// S1
	0x0027DD00, 	// S2
	0x0,			// S3 (not supported)
	0x1				// CA
};

/* patched bytes */
static constexpr unsigned __int32 iForceStart_patch[] =
{ 
	0x00000000,		// S1
	0x0027E280, 	// S2
	0x0,			// S3 (not supported)
	0x2 			// CA
};