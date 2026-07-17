module;

#include <common.hxx>

export module consolegammadx9;

import common;
import settings;

#ifndef SAFE_RELEASE
#define SAFE_RELEASE(p) { if (p) { (p)->Release(); (p)=NULL; } }
#endif

// DX9 (Shader Model 3.0)
#define IDR_VS_BlitXenonGammaDX9 101
#define IDR_PS_BlitXenonGammaDX9 102

#define IDR_VS_BlitCellGammaDX9  103
#define IDR_PS_BlitCellGammaDX9  104

class ConsoleGammaDX9
{
private:

public:
	ConsoleGammaDX9()
	{
		FusionFix::onInitEventAsync() += []()
		{

		};
	}
} ConsoleGammaDX9;