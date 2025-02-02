@echo off
setlocal enabledelayedexpansion
set "version=2.1"
set "repo_url=https://raw.githubusercontent.com/yourusername/yourrepo/main"
set "update_url=%repo_url%/USB_Formatter.bat"
set "version_url=%repo_url%/version.txt"

:check_admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo �������ԱȨ��...
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit
)

:main_menu
cls
echo ==============================
echo    USB��ʽ������ v%version%    
echo ==============================
echo 1. ��ʽ��U��
echo 2. ������
echo 3. �˳�
echo ==============================

choice /c 123 /n /m "��ѡ�����: "
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
echo ����ɨ����ƶ�������...
echo ------------------------------
set count=0
for /f "skip=1 tokens=1,2" %%a in ('wmic logicaldisk get caption^,drivetype 2^>nul') do (
    if "%%b"=="2" (
        set /a count+=1
        set "drive[!count!]=%%a"
        echo [!count!] ������ %%a
    )
)

if %count%==0 (
    echo δ�ҵ����ƶ���������
    pause
    exit /b
)

:select_drive
set /p "drive_num=��ѡ��Ҫ��ʽ������������: "
if not defined drive[%drive_num%] (
    echo ��Ч��ѡ��
    goto select_drive
)

set "selected_drive=!drive[%drive_num%]!"
echo ������ʽ�������� %selected_drive%
echo ���棺�⽫ɾ�����������ϵ��������ݣ�
choice /c YN /n /m "ȷ�ϸ�ʽ����(Y/N)"

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
echo        ��ʽ����������
echo ==============================
echo [��ǰ����]
echo �ļ�ϵͳ  : %fs_type%
echo ���䵥Ԫ  : %unit_size%
echo ��ʽ������: %quick:quick=����%
echo �������  : %volume_label%
echo ------------------------------
echo 1. ѡ���ļ�ϵͳ
echo 2. ���÷��䵥Ԫ��С
echo 3. �л���ʽ������
echo 4. ���þ������
echo 5. ��ʼ��ʽ��
echo 0. �������˵�
echo ==============================

choice /c 123450 /n /m "��ѡ��������: "
goto format_option_%errorlevel%

:format_option_1
cls
echo ��ѡ���ļ�ϵͳ��
echo 1. NTFS��Ĭ�ϣ�
echo 2. FAT32
echo 3. exFAT
choice /c 123 /n /m "ѡ��: "
if %errorlevel%==1 set fs_type=NTFS
if %errorlevel%==2 set fs_type=FAT32
if %errorlevel%==3 set fs_type=exFAT
goto format_menu

:format_option_2
cls
echo ���䵥Ԫ��Сʾ����
echo NTFS��512/1024/2048/4096
echo FAT32��4096/8192/16384
echo exFAT��4096/8192/1048576
set /p "unit_size=�������С���س�ʹ��Ĭ�ϣ���"
if defined unit_size (
    set "unit_param=unit=!unit_size!"
) else (
    set "unit_param="
)
goto format_menu

:format_option_3
cls
choice /c YN /n /m "�л���ʽ�����ͣ���ǰΪ%quick:quick=����%��Y=����/N=������"
if %errorlevel%==1 (set "quick=quick") else (set "quick=")
goto format_menu

:format_option_4
cls
set /p "volume_label=�������꣨�س����������32�ַ�����"
goto format_menu

:format_option_5
echo ���ڴ�����ʽ���ű�...
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

echo ���ڸ�ʽ��...��������Ҫ�����ӣ�
diskpart /s format_script.txt >nul
del format_script.txt

echo ��ʽ����ɣ�
echo ------------------------------
echo ���ո�ʽ��������
echo �ļ�ϵͳ��!fs_type!
echo ���䵥Ԫ��!unit_size!
echo ��ʽ�����ͣ�!quick:quick=����!
echo ������ƣ�!volume_label!
pause
exit /b

:format_option_0
goto main_menu

:update_check
echo ���ڼ�����...
powershell -Command "(New-Object Net.WebClient).DownloadFile('%version_url%', 'temp_version.txt')" 2>nul

if not exist "temp_version.txt" (
    echo �޷���ȡ�汾��Ϣ
    goto :update_fail
)

set /p new_version=<temp_version.txt
del temp_version.txt

if "%new_version%" gtr "%version%" (
    echo �����°汾 v%new_version%
    choice /c YN /n /m "�Ƿ�Ҫ���£�(Y/N)"
    if %errorlevel% neq 1 goto :update_fail
    call :perform_update
) else (
    echo �Ѿ������°汾
)
pause
exit /b

:perform_update
echo ���������°汾...
powershell -Command "(New-Object Net.WebClient).DownloadFile('%update_url%', 'USB_Formatter_new.bat')" 2>nul

if not exist "USB_Formatter_new.bat" (
    echo ����ʧ��
    goto :update_fail
)

echo ����Ӧ�ø���...
move /Y "USB_Formatter_new.bat" "%~nx0" >nul
echo ���³ɹ�����������������...
start "" "%~nx0"
exit

:update_fail
echo �Զ�����ʧ�ܣ�������������
pause
exit /b