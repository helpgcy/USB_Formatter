@echo off
setlocal enabledelayedexpansion
set "version=2.1"
set "repo_url=https://raw.githubusercontent.com/yourusername/yourrepo/main"
set "update_url=%repo_url%/USB_Formatter.bat"
set "version_url=%repo_url%/version.txt"

:check_admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 请求管理员权限...
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit
)

:main_menu
cls
echo ==============================
echo    USB格式化工具 v%version%    
echo ==============================
echo 1. 格式化U盘
echo 2. 检查更新
echo 3. 退出
echo ==============================

choice /c 123 /n /m "请选择操作: "
goto option_%errorlevel%

:option_1
call :format_drive
goto main_menu

:option_2
call :update_check
goto main_menu

:option_3
exit

:format_drive
cls
echo 正在扫描可移动驱动器...
echo ------------------------------
set count=0
for /f "skip=1 tokens=1,2" %%a in ('wmic logicaldisk get caption^,drivetype 2^>nul') do (
    if "%%b"=="2" (
        set /a count+=1
        set "drive[!count!]=%%a"
        echo [!count!] 驱动器 %%a
    )
)

if %count%==0 (
    echo 未找到可移动驱动器！
    pause
    exit /b
)

:select_drive
set /p "drive_num=请选择要格式化的驱动器号: "
if not defined drive[%drive_num%] (
    echo 无效的选择！
    goto select_drive
)

set "selected_drive=!drive[%drive_num%]!"
echo 即将格式化驱动器 %selected_drive%
echo 警告：这将删除该驱动器上的所有数据！
choice /c YN /n /m "确认格式化吗？(Y/N)"

if %errorlevel% neq 1 (
    exit /b
)

:format_options
set "fs_type=NTFS"
set "unit_size="
set "quick=quick"
set "volume_label="

:format_menu
cls
echo ==============================
echo        格式化参数设置
echo ==============================
echo [当前设置]
echo 文件系统  : %fs_type%
echo 分配单元  : %unit_size%
echo 格式化类型: %quick:quick=快速%
echo 卷标名称  : %volume_label%
echo ------------------------------
echo 1. 选择文件系统
echo 2. 设置分配单元大小
echo 3. 切换格式化类型
echo 4. 设置卷标名称
echo 5. 开始格式化
echo 0. 返回主菜单
echo ==============================

choice /c 123450 /n /m "请选择设置项: "
goto format_option_%errorlevel%

:format_option_1
cls
echo 请选择文件系统：
echo 1. NTFS（默认）
echo 2. FAT32
echo 3. exFAT
choice /c 123 /n /m "选择: "
if %errorlevel%==1 set fs_type=NTFS
if %errorlevel%==2 set fs_type=FAT32
if %errorlevel%==3 set fs_type=exFAT
goto format_menu

:format_option_2
cls
echo 分配单元大小示例：
echo NTFS：512/1024/2048/4096
echo FAT32：4096/8192/16384
echo exFAT：4096/8192/1048576
set /p "unit_size=请输入大小（回车使用默认）："
if defined unit_size (
    set "unit_param=unit=!unit_size!"
) else (
    set "unit_param="
)
goto format_menu

:format_option_3
cls
choice /c YN /n /m "切换格式化类型：当前为%quick:quick=快速%（Y=快速/N=完整）"
if %errorlevel%==1 (set "quick=quick") else (set "quick=")
goto format_menu

:format_option_4
cls
set /p "volume_label=请输入卷标（回车跳过，最多32字符）："
goto format_menu

:format_option_5
echo 正在创建格式化脚本...
(
echo select volume !selected_drive:~0,1!
echo clean
echo create partition primary
echo format fs=!fs_type! !quick! !unit_param!
echo assign
) > format_script.txt

if defined volume_label (
    echo label=!volume_label! >> format_script.txt
)

echo 正在格式化...（可能需要几分钟）
diskpart /s format_script.txt >nul
del format_script.txt

echo 格式化完成！
echo ------------------------------
echo 最终格式化参数：
echo 文件系统：!fs_type!
echo 分配单元：!unit_size!
echo 格式化类型：!quick:quick=快速!
echo 卷标名称：!volume_label!
pause
exit /b

:format_option_0
goto main_menu

:update_check
echo 正在检查更新...
powershell -Command "(New-Object Net.WebClient).DownloadFile('%version_url%', 'temp_version.txt')" 2>nul

if not exist "temp_version.txt" (
    echo 无法获取版本信息
    goto :update_fail
)

set /p new_version=<temp_version.txt
del temp_version.txt

if "%new_version%" gtr "%version%" (
    echo 发现新版本 v%new_version%
    choice /c YN /n /m "是否要更新？(Y/N)"
    if %errorlevel% neq 1 goto :update_fail
    call :perform_update
) else (
    echo 已经是最新版本
)
pause
exit /b

:perform_update
echo 正在下载新版本...
powershell -Command "(New-Object Net.WebClient).DownloadFile('%update_url%', 'USB_Formatter_new.bat')" 2>nul

if not exist "USB_Formatter_new.bat" (
    echo 更新失败
    goto :update_fail
)

echo 正在应用更新...
move /Y "USB_Formatter_new.bat" "%~nx0" >nul
echo 更新成功，重新启动程序中...
start "" "%~nx0"
exit

:update_fail
echo 自动更新失败，请检查网络连接
pause
exit /b