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

/* pointer to local player object 
	type: CZSEAL_T
*/
static constexpr std::pair<unsigned __int32, unsigned __int32> pLocalSeal = { 0x44D648, 0x709D98 };

/* instruction which can be manipulated to force start the match */
static constexpr std::pair<unsigned __int32, unsigned __int32> iForceStart = { 0x408868, 0xA7675C };
static constexpr std::pair<unsigned __int32, unsigned __int32> iForceStart_original = { 0x0027DD00, 0x1 };
static constexpr std::pair<unsigned __int32, unsigned __int32> iForceStart_patch = { 0x0027E280, 0x2 };