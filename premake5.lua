newoption {
    trigger     = "with-version",
    value       = "STRING",
    description = "Current version",
}

workspace "MaxPayne3.FusionFix"
   configurations { "Release", "Debug" }
   architecture "x86"
   location "build"
   cppdialect "C++latest"
   kind "SharedLib"
   language "C++"
   targetdir "bin/%{cfg.buildcfg}"
   targetextension ".asi"
   buildoptions { "/dxifcInlineFunctions-" }

   defines { "rsc_CompanyName=\"MaxPayne3.FusionFix\"" }
   defines { "rsc_LegalCopyright=\"MIT license\""}
   defines { "rsc_InternalName=\"%{prj.name}\"", "rsc_ProductName=\"%{prj.name}\"", "rsc_OriginalFilename=\"%{cfg.buildtarget.name}\"" }
   defines { "rsc_FileDescription=\"MaxPayne3.FusionFix\"" }
   defines { "rsc_UpdateUrl=\"https://github.com/ThirteenAG/MaxPayne3.FusionFix\"" }

   local major = os.date("%d")
   local minor = os.date("%m")
   local build = os.date("%Y")
   local revision = os.date("%H") .. os.date("%M")

   if _OPTIONS["with-version"] then
      local t = {}
      for i in _OPTIONS["with-version"]:gmatch("([^.]+)") do
         t[#t + 1], _ = i:gsub("%D+", "")
      end
      while #t < 4 do t[#t + 1] = 0 end
      major    = math.min(tonumber(t[1]), 255)
      minor    = math.min(tonumber(t[2]), 255)
      build    = math.min(tonumber(t[3]), 65535)
      revision = math.min(tonumber(t[4]), 65535)
   end

   local githash = ""
   local f = io.popen("git rev-parse --short HEAD")
   if f then
      githash = f:read("*a"):gsub("%s+", "")
      f:close()
   end

   local productVersion = major .. "." .. minor .. "." .. build .. "." .. revision
   if githash ~= "" then
      productVersion = productVersion .. "-" .. githash
   end

   defines { "rsc_FileVersion_MAJOR=" .. major }
   defines { "rsc_FileVersion_MINOR=" .. minor }
   defines { "rsc_FileVersion_BUILD=" .. build }
   defines { "rsc_FileVersion_REVISION=" .. revision }
   defines { "rsc_FileVersion=\"" .. major .. "." .. minor .. "." .. build .. "\"" }
   defines { "rsc_ProductVersion=\"" .. productVersion .. "\"" }
   defines { "rsc_GitSHA1=\"" .. githash .. "\"" }
   defines { "rsc_GitSHA1W=L\"" .. githash .. "\"" }

   defines { "_CRT_SECURE_NO_WARNINGS" }

   includedirs { "source" }
   includedirs { "source/includes" }
   includedirs { "source/ledsdk" }
   includedirs { "source/dxsdk" }
   libdirs { "source/ledsdk" }
   libdirs { "source/dxsdk" }
   files { "source/**.h", "source/*.hpp", "source/*.cpp", "source/*.hxx", "source/**.ixx" }
   files { "source/resources/Versioninfo.rc" }
   files { "source/resources/Shaders.rc" }
   links { "LogitechLEDLib.lib" }

   includedirs { "external/hooking" }
   includedirs { "external/injector/include" }
   includedirs { "external/injector/safetyhook/include" }
   includedirs { "external/injector/zydis" }
   includedirs { "external/inireader" }
   files { "external/hooking/Hooking.Patterns.h", "external/hooking/Hooking.Patterns.cpp" }
   files { "external/injector/safetyhook/include/**.hpp", "external/injector/safetyhook/src/**.cpp" }
   files { "external/injector/zydis/**.h", "external/injector/zydis/**.c" }
   files { "data/plugins/*.ini" }

   characterset ("Unicode")

   os.mkdir("shaders/external/gamma/asm")
   os.mkdir("source/resources/shaders/win32_30")
   os.mkdir("source/resources/shaders/win32_40")
   os.mkdir("source/resources/shaders/win32_41")
   os.mkdir("source/resources/shaders/win32_50")

   prebuildcommands {
      "\"../source/dxsdk/lib/x86/fxc.exe\" /T vs_3_0 /nologo /E VSMain /Fo \"../source/resources/shaders/win32_30/VS_BlitXenonGammaDX9.cso\" /Fc \"../shaders/external/gamma/asm/VS_BlitXenonGammaDX9.asm\" \"../shaders/external/gamma/hlsl/XenonGammaDX9.hlsl\" && \"../source/dxsdk/lib/x86/fxc.exe\" /T ps_3_0 /E PSMain /Fo \"../source/resources/shaders/win32_30/PS_BlitXenonGammaDX9.cso\" /Fc \"../shaders/external/gamma/asm/PS_BlitXenonGammaDX9.asm\" \"../shaders/external/gamma/hlsl/XenonGammaDX9.hlsl\"",
      "\"../source/dxsdk/lib/x86/fxc.exe\" /T vs_3_0 /nologo /E VSMain /Fo \"../source/resources/shaders/win32_30/VS_BlitCellGammaDX9.cso\"  /Fc \"../shaders/external/gamma/asm/VS_BlitCellGammaDX9.asm\"  \"../shaders/external/gamma/hlsl/CellGammaDX9.hlsl\"  && \"../source/dxsdk/lib/x86/fxc.exe\" /T ps_3_0 /E PSMain /Fo \"../source/resources/shaders/win32_30/PS_BlitCellGammaDX9.cso\"  /Fc \"../shaders/external/gamma/asm/PS_BlitCellGammaDX9.asm\"  \"../shaders/external/gamma/hlsl/CellGammaDX9.hlsl\"",

      "\"../source/dxsdk/lib/x86/fxc.exe\" /T vs_4_0 /nologo /E VSMain /Fo \"../source/resources/shaders/win32_40/VS_BlitXenonGammaDX10.cso\" /Fc \"../shaders/external/gamma/asm/VS_BlitXenonGammaDX10.asm\" \"../shaders/external/gamma/hlsl/XenonGammaDX11.hlsl\" && \"../source/dxsdk/lib/x86/fxc.exe\" /T ps_4_0 /E PSMain /Fo \"../source/resources/shaders/win32_40/PS_BlitXenonGammaDX10.cso\" /Fc \"../shaders/external/gamma/asm/PS_BlitXenonGammaDX10.asm\" \"../shaders/external/gamma/hlsl/XenonGammaDX11.hlsl\"",
      "\"../source/dxsdk/lib/x86/fxc.exe\" /T vs_4_0 /nologo /E VSMain /Fo \"../source/resources/shaders/win32_40/VS_BlitCellGammaDX10.cso\"  /Fc \"../shaders/external/gamma/asm/VS_BlitCellGammaDX10.asm\"  \"../shaders/external/gamma/hlsl/CellGammaDX11.hlsl\"  && \"../source/dxsdk/lib/x86/fxc.exe\" /T ps_4_0 /E PSMain /Fo \"../source/resources/shaders/win32_40/PS_BlitCellGammaDX10.cso\"  /Fc \"../shaders/external/gamma/asm/PS_BlitCellGammaDX10.asm\"  \"../shaders/external/gamma/hlsl/CellGammaDX11.hlsl\"",

      "\"../source/dxsdk/lib/x86/fxc.exe\" /T vs_4_1 /nologo /E VSMain /Fo \"../source/resources/shaders/win32_41/VS_BlitXenonGammaDX10_1.cso\" /Fc \"../shaders/external/gamma/asm/VS_BlitXenonGammaDX10_1.asm\" \"../shaders/external/gamma/hlsl/XenonGammaDX11.hlsl\" && \"../source/dxsdk/lib/x86/fxc.exe\" /T ps_4_1 /E PSMain /Fo \"../source/resources/shaders/win32_41/PS_BlitXenonGammaDX10_1.cso\" /Fc \"../shaders/external/gamma/asm/PS_BlitXenonGammaDX10_1.asm\" \"../shaders/external/gamma/hlsl/XenonGammaDX11.hlsl\"",
      "\"../source/dxsdk/lib/x86/fxc.exe\" /T vs_4_1 /nologo /E VSMain /Fo \"../source/resources/shaders/win32_41/VS_BlitCellGammaDX10_1.cso\"  /Fc \"../shaders/external/gamma/asm/VS_BlitCellGammaDX10_1.asm\"  \"../shaders/external/gamma/hlsl/CellGammaDX11.hlsl\"  && \"../source/dxsdk/lib/x86/fxc.exe\" /T ps_4_1 /E PSMain /Fo \"../source/resources/shaders/win32_41/PS_BlitCellGammaDX10_1.cso\"  /Fc \"../shaders/external/gamma/asm/PS_BlitCellGammaDX10_1.asm\"  \"../shaders/external/gamma/hlsl/CellGammaDX11.hlsl\"",

      "\"../source/dxsdk/lib/x86/fxc.exe\" /T vs_5_0 /nologo /E VSMain /Fo \"../source/resources/shaders/win32_50/VS_BlitXenonGammaDX11.cso\" /Fc \"../shaders/external/gamma/asm/VS_BlitXenonGammaDX11.asm\" \"../shaders/external/gamma/hlsl/XenonGammaDX11.hlsl\" && \"../source/dxsdk/lib/x86/fxc.exe\" /T ps_5_0 /E PSMain /Fo \"../source/resources/shaders/win32_50/PS_BlitXenonGammaDX11.cso\" /Fc \"../shaders/external/gamma/asm/PS_BlitXenonGammaDX11.asm\" \"../shaders/external/gamma/hlsl/XenonGammaDX11.hlsl\"",
      "\"../source/dxsdk/lib/x86/fxc.exe\" /T vs_5_0 /nologo /E VSMain /Fo \"../source/resources/shaders/win32_50/VS_BlitCellGammaDX11.cso\"  /Fc \"../shaders/external/gamma/asm/VS_BlitCellGammaDX11.asm\"  \"../shaders/external/gamma/hlsl/CellGammaDX11.hlsl\"  && \"../source/dxsdk/lib/x86/fxc.exe\" /T ps_5_0 /E PSMain /Fo \"../source/resources/shaders/win32_50/PS_BlitCellGammaDX11.cso\"  /Fc \"../shaders/external/gamma/asm/PS_BlitCellGammaDX11.asm\"  \"../shaders/external/gamma/hlsl/CellGammaDX11.hlsl\"",
   }

   pbcommands = { 
      "setlocal EnableDelayedExpansion",
      --"set \"path=" .. (gamepath) .. "\"",
      "set file=$(TargetPath)",
      "FOR %%i IN (\"%file%\") DO (",
      "set filename=%%~ni",
      "set fileextension=%%~xi",
      "set target=!path!!filename!!fileextension!",
      "if exist \"!target!\" copy /y \"!file!\" \"!target!\"",
      ")" }

   function setpaths (gamepath, exepath, scriptspath)
      scriptspath = scriptspath or "scripts/"
      if (gamepath) then
         cmdcopy = { "set \"path=" .. gamepath .. scriptspath .. "\"" }
         table.insert(cmdcopy, pbcommands)
         postbuildcommands (cmdcopy)
         debugdir (gamepath)
         if (exepath) then
            debugcommand (gamepath .. exepath)
            dir, file = exepath:match'(.*/)(.*)'
            debugdir (gamepath .. (dir or ""))
         end
      end
      targetdir ("bin")
   end

   filter "configurations:Debug"
      defines { "DEBUG" }
      symbols "On"

   filter "configurations:Release"
      defines { "NDEBUG" }
      optimize "On"
      staticruntime "On"

project "MaxPayne3.FusionFix"
   setpaths("Z:/WFP/Games/Max Payne/Max Payne 3/", "MaxPayne3.exe", "plugins/")