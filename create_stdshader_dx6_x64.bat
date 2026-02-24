@ECHO OFF
Setlocal EnableDelayedExpansion

REM Check MSBuild present in PATH.
MSBuild.exe /? >NUL
IF ERRORLEVEL 1 (
  ECHO MsBuild not found in PATH. Please, start from Developer Command Prompt or add MSVC MsBuild directory to the PATH.
  EXIT /B 1
)

SET CMAKE_MSVC_ARCH_NAME=x64
SET MSBUILD_PLATFORM=x64

ECHO "Generating stdshader_dx6 solution for x64"

REM Set CMake / MSVC generator / architecture / platform.
SET CMAKE_MSVC_GEN_NAME="Visual Studio 17 2022"

REM Generate version info, etc.
MKDIR out 2>NUL
PUSHD out
cmake ..\CMakeLists.txt
if ERRORLEVEL 1 (
  ECHO cmake version generation failed.
  EXIT /B 1
)
POPD

REM Build VPC.
MSBuild.exe /m /p:Platform=x64 /p:Configuration=Release external/vpc/vpc.sln
if ERRORLEVEL 1 (
  ECHO MSBuild Release x64 for external/vpc/vpc.sln failed.
  EXIT /B 1
)

REM Create solution with stdshader_dx6 and all its dependencies.
REM Dependencies: mathlib, shaderlib, tier0, tier1, vstdlib
REM /windows flag tells VPC to generate for x64
devtools\bin\vpc.exe /2022 /windows /define:WORKSHOP_IMPORT_DISABLE /define:SIXENSE_DISABLE /define:NO_X360_XDK /define:RAD_TELEMETRY_DISABLED /define:DISABLE_ETW /define:NO_STEAM /define:NO_ATI_COMPRESS /define:NO_NVTC /define:LTCG /no_ceg /nofpo +tier0 +tier1 +vstdlib +mathlib +shaderlib +stdshader_dx6 /mksln stdshader_dx6_x64.sln
if ERRORLEVEL 1 (
  ECHO VPC for stdshader_dx6_x64.sln failed.
  EXIT /B 1
)

ECHO.
ECHO Successfully generated stdshader_dx6_x64.sln
ECHO Open stdshader_dx6_x64.sln in Visual Studio to build.
