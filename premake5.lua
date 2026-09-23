newoption {
    trigger     = "with-version",
    value       = "STRING",
    description = "Current version",
}

-- The folder a project is deployed to, and the game it is started from when debugging,
-- is the path of one machine and does not belong in the repository. It is read from a
-- `.env` file next to this script, which is not tracked by git and holds one
-- `<KEY>=<folder>` line per game (quotes and a trailing slash are optional), see the
-- readme. A project whose key is missing is not deployed at all.
local envkeys = nil
function envdir(key)
   if not envkeys then
      envkeys = {}
      local text = io.readfile(path.join(_SCRIPT_DIR, ".env")) or ""
      for line in text:gmatch("[^\r\n]+") do
         local k, v = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
         if k and v ~= "" then
            v = v:gsub('^"', ""):gsub('"$', ""):gsub("^'", ""):gsub("'$", "")
            envkeys[k] = v
         end
      end
   end

   local value = envkeys[key]
   if not value then return nil end

   value = value:gsub("[%s\\/]+$", "")
   if value == "" then return nil end

   return path.translate(value)
end

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

   os.mkdir("source/resources/shaders/win32_30")
   os.mkdir("source/resources/shaders/win32_40")
   os.mkdir("source/resources/shaders/win32_41")
   os.mkdir("source/resources/shaders/win32_50")

   -- Shaders are compiled by fxc as a prebuild step, one set per DirectX
   -- version, and are embedded as RCDATA (source/resources/Shaders.rc):
   --   win32_30 (Direct3D 9, shader model 3.0), win32_40 (10, sm 4.0),
   --   win32_41 (10.1, sm 4.1) and win32_50 (11, sm 5.0).
   -- POSTFX_DX9 selects the shader model 3 syntax in the shared postfx sources.
   local fxc = "\"../source/dxsdk/lib/x86/fxc.exe\""

   local shaderProfiles = {
      { dir = "win32_30", vs = "vs_3_0", ps = "ps_3_0", define = "/DPOSTFX_DX9" },
      { dir = "win32_40", vs = "vs_4_0", ps = "ps_4_0", define = "" },
      { dir = "win32_41", vs = "vs_4_1", ps = "ps_4_1", define = "" },
      { dir = "win32_50", vs = "vs_5_0", ps = "ps_5_0", define = "" },
   }

   -- Every post processing shader, one source each, compiled once per profile.
   -- Shaders that need more than one variant name it in define, which is how
   -- the console gamma gets its presets: another console is one more row here
   -- with the next preset number, nothing else has to change.
   local postfxSources = {
      { stage = "vs", file = "VS_PostFX.hlsl",                   entry = "VSMain",           output = "VS_PostFX" },
      { stage = "ps", file = "PS_PostFX_SMAAEdgeDetection.hlsl", entry = "PSMain",           output = "PS_PostFX_SMAAEdgeDetection" },
      { stage = "ps", file = "PS_PostFX_SMAABlendWeight.hlsl",   entry = "PSMain",           output = "PS_PostFX_SMAABlendWeight" },
      { stage = "ps", file = "PS_PostFX_SMAAOutput.hlsl",        entry = "PSMain",           output = "PS_PostFX_SMAAOutput" },
      { stage = "ps", file = "PS_PostFX_Blur.hlsl",              entry = "PSBlurHorizontal", output = "PS_PostFX_BlurHorizontal" },
      { stage = "ps", file = "PS_PostFX_Blur.hlsl",              entry = "PSBlurVertical",   output = "PS_PostFX_BlurVertical" },
      { stage = "ps", file = "PS_PostFX_Gamma.hlsl",             entry = "PSMain",           output = "PS_PostFX_GammaXenon", define = "/DPOSTFX_GAMMA_PRESET=1" },
      { stage = "ps", file = "PS_PostFX_Gamma.hlsl",             entry = "PSMain",           output = "PS_PostFX_GammaCell",  define = "/DPOSTFX_GAMMA_PRESET=2" },
   }

   local prebuildShaderCommands = {}
   for _, profile in ipairs(shaderProfiles) do
      local commands = {}

      local function compile(stage, source, entry, output, define)
         local target = (stage == "vs") and profile.vs or profile.ps
         define = define ~= "" and (define .. " ") or ""
         table.insert(commands, string.format("%s /T %s /nologo %s/E %s /Fo \"../source/resources/shaders/%s/%s.cso\" \"%s\"",
            fxc, target, define, entry, profile.dir, output, source))
      end

      for _, shader in ipairs(postfxSources) do
         local define = table.concat({ shader.define or "", profile.define }, " ")
         compile(shader.stage, "../shaders/postfx/" .. shader.file, shader.entry, shader.output, define)
      end

      table.insert(prebuildShaderCommands, table.concat(commands, " && "))
   end


   prebuildcommands (prebuildShaderCommands)

   -- Deploys the built .asi into the folder that `key` names in the .env file, and
   -- starts the game from there when debugging. Only a plugin that is already installed
   -- in the game folder is replaced, a folder without one is left alone.
   function setpaths (key, exepath, scriptspath)
      scriptspath = scriptspath or "scripts/"
      local gamepath = envdir(key)
      if gamepath then
         local target = gamepath .. "\\" .. path.translate(scriptspath)
         postbuildcommands {
            "if exist \"" .. target .. "$(TargetFileName)\" copy /y \"$(TargetPath)\" \"" .. target .. "\"",
         }
         debugdir (gamepath)
         if (exepath) then
            debugcommand (gamepath .. "\\" .. path.translate(exepath))
            local dir = exepath:match'(.*/)(.*)'
            debugdir (gamepath .. "\\" .. path.translate(dir or ""))
         end
      end
      targetdir ("bin")
   end

   filter "configurations:Debug"
      defines { "DEBUG" }
      symbols "On"
      -- /MDd breaks the compilation of module units when they are combined
      -- with header units, the compiler reports C2079 on std::basic_istream
      -- (microsoft/STL#6389), so the static runtime is used here like in
      -- Release, which also keeps the debug CRT out of the shipped plugin
      staticruntime "On"

   filter "configurations:Release"
      defines { "NDEBUG" }
      optimize "On"
      staticruntime "On"

project "MaxPayne3.FusionFix"
   setpaths("MAX_PAYNE_3_DIR", "MaxPayne3.exe", "plugins/")