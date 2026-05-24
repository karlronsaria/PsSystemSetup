cd %SystemDrive%\tools

:: Retrieved: 2026-01-06
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg

.\bootstrap-vcpkg.bat
.\vcpkg integrate install
