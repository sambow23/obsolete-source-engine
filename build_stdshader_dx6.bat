@ECHO OFF
Setlocal EnableDelayedExpansion

REM Try to find MSBuild automatically if not already in PATH.
MSBuild.exe /? >NUL 2>NUL
IF ERRORLEVEL 1 (
  REM Try vswhere to locate VS 2022 MSBuild.
  SET "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
  IF EXIST "!VSWHERE!" (
    FOR /F "tokens=*" %%i IN ('"!VSWHERE!" -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe') DO (
      SET "MSBUILD_PATH=%%~dpi"
    )
  )

  IF DEFINED MSBUILD_PATH (
    ECHO Found MSBuild at !MSBUILD_PATH!
    SET "PATH=!MSBUILD_PATH!;!PATH!"
  ) ELSE (
    ECHO MSBuild not found. Please install Visual Studio 2022 with C++ workload or run from Developer Command Prompt.
    EXIT /B 1
  )
)

REM Also ensure cl.exe / cmake are available by loading vcvarsall if needed.
where cl.exe >NUL 2>NUL
IF ERRORLEVEL 1 (
  SET "VCVARSALL="
  SET "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
  IF EXIST "!VSWHERE!" (
    FOR /F "tokens=*" %%i IN ('"!VSWHERE!" -latest -property installationPath') DO (
      SET "VCVARSALL=%%i\VC\Auxiliary\Build\vcvarsall.bat"
    )
  )

  IF DEFINED VCVARSALL IF EXIST "!VCVARSALL!" (
    ECHO Loading Visual Studio environment...
    CALL "!VCVARSALL!" x64 >NUL
  ) ELSE (
    ECHO Warning: Could not find vcvarsall.bat. cmake may not be available.
  )
)

SET "CONFIG=Release"
SET "PLATFORM=x64"
SET "SLN=stdshader_dx6_x64.sln"
SET "VPC_WINDOWS=/windows"

REM Parse arguments
:parse_args
if ["%~1"]==[""] goto done_args
if /I ["%~1"]==["debug"] SET "CONFIG=Debug"
if /I ["%~1"]==["release"] SET "CONFIG=Release"
if /I ["%~1"]==["x86"] SET "PLATFORM=Win32"& SET "SLN=stdshader_dx6.sln"& SET "VPC_WINDOWS= "
if /I ["%~1"]==["x64"] SET "PLATFORM=x64"& SET "SLN=stdshader_dx6_x64.sln"& SET "VPC_WINDOWS=/windows"
shift
goto parse_args
:done_args

REM Set CMake / MSVC generator.
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

REM Generate solution with stdshader_dx6 and all its dependencies.
ECHO Generating %SLN%...
devtools\bin\vpc.exe /2022 %VPC_WINDOWS% /define:WORKSHOP_IMPORT_DISABLE /define:SIXENSE_DISABLE /define:NO_X360_XDK /define:RAD_TELEMETRY_DISABLED /define:DISABLE_ETW /define:NO_STEAM /define:NO_ATI_COMPRESS /define:NO_NVTC /define:LTCG /no_ceg /nofpo +tier0 +tier1 +vstdlib +mathlib +shaderlib +stdshader_dx6 /mksln %SLN%
if ERRORLEVEL 1 (
  ECHO VPC for %SLN% failed.
  EXIT /B 1
)

REM Build the solution.
ECHO.
ECHO Building %SLN% [%CONFIG%^|%PLATFORM%]
ECHO.

MSBuild.exe /m /p:Platform=%PLATFORM% /p:Configuration=%CONFIG% %SLN%
IF ERRORLEVEL 1 (
  ECHO.
  ECHO Build FAILED.
  EXIT /B 1
)

ECHO.
ECHO Build SUCCEEDED [%CONFIG%^|%PLATFORM%].
