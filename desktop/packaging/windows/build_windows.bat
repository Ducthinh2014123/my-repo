@echo off
REM ============================================================
REM Build WhisperSub cho Windows -> file setup.exe
REM Cach dung:  build_windows.bat cpu   (hoac: build_windows.bat gpu)
REM Yeu cau: Python 3.10-3.12, Inno Setup 6, ffmpeg.exe trong desktop\bin\
REM ============================================================
setlocal
set VARIANT=%1
if "%VARIANT%"=="" set VARIANT=cpu

cd /d "%~dp0..\.."

REM --- Kiem tra ffmpeg bundle ---
if not exist "bin\ffmpeg.exe" (
    echo [!] Thieu bin\ffmpeg.exe — tai ban static tu https://www.gyan.dev/ffmpeg/builds/
    echo     roi copy ffmpeg.exe vao thu muc desktop\bin\
    exit /b 1
)

REM --- Tao venv rieng cho tung variant ---
python -m venv venv-%VARIANT%
call venv-%VARIANT%\Scripts\activate.bat
pip install --upgrade pip
pip install -r requirements-%VARIANT%.txt
pip install pyinstaller

REM --- PyInstaller (onedir, KHONG dung --onefile vi torch qua nang) ---
pyinstaller main.py --name WhisperSub --noconsole --noconfirm ^
  --icon assets\icon.ico ^
  --add-binary "bin\ffmpeg.exe;bin" ^
  --collect-data whisper ^
  --collect-all transformers ^
  --collect-all torch

if errorlevel 1 exit /b 1

REM --- Inno Setup -> setup.exe ---
set ISCC="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if not exist %ISCC% (
    echo [!] Chua cai Inno Setup 6: https://jrsoftware.org/isdl.php
    exit /b 1
)
%ISCC% /DVARIANT=%VARIANT% packaging\windows\installer.iss

echo.
echo ==== XONG! File setup nam o desktop\dist-installer\WhisperSub-Setup-%VARIANT%-1.0.0.exe ====
endlocal
