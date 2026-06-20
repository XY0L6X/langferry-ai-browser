@echo off
REM WebLingo 运行脚本 — 确保 Flutter 在 PATH 中
REM 如果 flutter 命令不可用，请将 Flutter bin 目录添加到系统 PATH
cd /d "%~dp0"
flutter pub get
flutter run
pause
