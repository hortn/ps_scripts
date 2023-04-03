#GPL v.3
#
#
# v.0.1 04.05.2022
# Ку! Скрипт удаляет 16 офис. x86 или x64 - значения не имеет. + установка 19 офиса по сети. т.ч. расчитывайте что займет прилично времени, особенно если канал никакой.
#
# v.0.2 05.05.2022
# Теперь получаем список установленных продуктов через WMI, а не из реестра. т.к. возникли проблемы на части пк - офис установлен, но в реестре нет инфо.
# Работает это медленнее, но зато работает.
# Добавил запись лога в C:\PSLogs\Office_Magic.log
# 
#
#
#
#
#
#
#
#############################################################################################################################################################################################

# Именем Админа!!!! 
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

# Начинаем вести летопись.
Start-Transcript -Append C:\PSLogs\Office_Magic.log

Function CreateXml { # Создать XML файл конфиг. обязательно указывайте свитч.
  param (
    [switch]$lync,
    [switch]$Office2016,
    [switch]$Visio2016,
    [switch]$Project2016)


  if ($lync.IsPresent) {
    $XmlFileName = 'lync_uninstall_config.xml'
    $XmlContent = '<Configuration Product="Lync">
    <Display Level="None" CompletionNotice="no" SuppressModal="yes" AcceptEula="yes" /> 
    <Setting Id="SETUP_REBOOT" Value="ReallySuppress" />
</Configuration>'
  }
  Elseif ($Office2016.IsPresent) {
    $XmlFileName = 'office_uninstall_config.xml'
    $XmlContent = '<Configuration Product="ProPlus">
    <Display Level="None" CompletionNotice="no" SuppressModal="yes" AcceptEula="yes" /> 
    <Setting Id="SETUP_REBOOT" Value="ReallySuppress" />
</Configuration>'
  }
  Elseif ($Visio2016.IsPresent) {
    $XmlFileName = 'visio_uninstall_config.xml'
    $XmlContent = '<Configuration Product="VisPro">
    <Display Level="None" CompletionNotice="no" SuppressModal="yes" AcceptEula="yes" /> 
    <Setting Id="SETUP_REBOOT" Value="ReallySuppress" />
</Configuration>'
  }

  Elseif ($Project2016.IsPresent) {
    $XmlFileName = 'project_uninstall_config.xml'
    $XmlContent = '<Configuration Product="PrjPro">
    <Display Level="None" CompletionNotice="no" SuppressModal="yes" AcceptEula="yes" /> 
    <Setting Id="SETUP_REBOOT" Value="ReallySuppress" />
</Configuration>'
  }

  New-Item "C:\temp\$XmlFileName" -ItemType File
  Set-Content "C:\temp\$XmlFileName"  "$XmlContent"
}

Function RemoveOffice2016 {  # Функция удаления офиса. 
  Write-Host "ВНИМАНИЕ!!! СОХРАНИТЕ ДОКУМЕНТЫ!!! Все офисные приложения будут закрыты. " -ForegroundColor Red
  Write-Host "Для продолжения нажмите ENTER " -ForegroundColor Red
  Pause
  $proc = @('MSACCESS'
    'ONENOTE'
    'OUTLOOK'
    'EXCEL'
    'lync'
    'WINWORD'
    'POWERPNT')

  Stop-Process -Name $proc -ErrorAction SilentlyContinue


  if (test-path -path 'C:\Program Files (x86)\Common Files\Microsoft Shared\OFFICE16\Office Setup Controller\Setup.exe') {
    $path = 'C:\Program Files (x86)\Common Files\Microsoft Shared\OFFICE16\Office Setup Controller\Setup.exe'
  }
  Else {
    $path = 'C:\Program Files\Common Files\microsoft shared\OFFICE16\Office Setup Controller\Setup.exe'
    
  }

  $InstallAppList = (Get-WmiObject -Class Win32_Product |  Where-Object { $_.Name -like "Microsoft Office Professional Plus 2016"`
        -or $_.Name -like "Microsoft Skype for Business MUI (Russian) 2016"`
        -or $_.Name -like "Microsoft Project Professional 2016"`
        -or $_.Name -like "Microsoft Visio Professional 2016" }).Name

  Write-Host "На ПК Установлены:" -BackgroundColor White -ForegroundColor Red
  $InstallAppList

  foreach ($App in $InstallAppList) {
    if ($App -like "Microsoft Office Professional Plus 2016") {
      CreateXml -Office2016
      $SetupArgs = "/uninstall ProPlus /dll OSETUP.DLL /config C:\temp\office_uninstall_config.xml"
    }
  
    Elseif ($App -like "Microsoft Visio Professional 2016") {
      CreateXml -Visio2016
      $SetupArgs = "/uninstall VisPro /dll OSETUP.DLL /config C:\temp\visio_uninstall_config.xml"
    }

    Elseif ($App -like "Microsoft Project Professional 2016") {
      CreateXml -Project2016
      $SetupArgs = "/uninstall PrjPro /dll OSETUP.DLL /config C:\temp\project_uninstall_config.xml"
    }

    Elseif ($App -like "Microsoft Skype for Business MUI (Russian) 2016") {
      CreateXml -lync
      $SetupArgs = "/uninstall LYNCENTRY /dll OSETUP.DLL /config C:\temp\lync_uninstall_config.xml"
    }
    Write-Host "Удаляем $App, Ждите..."
    Start-Process -FilePath "$path" -ArgumentList "$SetupArgs" -Verb RunAs -Wait -Verbose -ErrorAction SilentlyContinue 

  }

  
  Write-Host "Удаление завершено. Проверяем статус..."

  [array]$Status = (Get-WmiObject -Class Win32_Product |  Where-Object { $_.Name -like "Microsoft Office Professional Plus 2016"`
        -or $_.Name -like "Microsoft Skype for Business MUI (Russian) 2016"`
        -or $_.Name -like "Microsoft Project Professional 2016"`
        -or $_.Name -like "Microsoft Visio Professional 2016" }).Name
  
  if ($Status -notcontains "Microsoft Office Professional Plus 2016"`
      -and $Status -notcontains "Microsoft Skype for Business MUI (Russian) 2016"`
      -and $Status -notcontains "Microsoft Project Professional 2016"`
      -and $Status -notcontains "Microsoft Visio Professional 2016") {
    Write-Host 'Офисный пакет 2016 успешно удален'
  }
  else {
    Write-Host 'Офисный пакет 2016 или его компонент не удалены. Удаляйте руками' -BackgroundColor Red
  }

  Remove-Item -Path "C:\temp\*.xml" -Force -ErrorAction SilentlyContinue
}

function SetupOffice2019 {  # Функция установки офиса 2019. Мапим в "P:\" папку "\\my_domain.local\support\install\Other\Office\office_2019_x64\office"
  param (                   # Следовательно XML конфиги для установки лежат там же.
    [switch]$OfficeOnly,
    [switch]$OfficeVisioProject,
    [switch]$VisioProjec,
    [switch]$VisioOnly,
    [switch]$ProjectOnly)
  
  if ($OfficeOnly.IsPresent) {
    $SetupArgs2019 = "/configure configuration_office_only.xml"
  }
  
  elseif ($OfficeVisioProject.IsPresent) {
    $SetupArgs2019 = "/configure configuration.xml"
  }

  elseif ($VisioProjec.IsPresent) {
    $SetupArgs2019 = "/configure configuration_visio+project.xml"
  }
  
  elseif ($VisioOnly.IsPresent) {
    $SetupArgs2019 = "/configure configuration_visio.xml"
  }

  elseif ($ProjectOnly.IsPresent) {
    $SetupArgs2019 = "/configure configuration_project.xml"
  }

  new-psdrive -name P -psprovider FileSystem -root "\\my_domain.local\support\install\Other\Office\office_2019_x64\office" | Out-Null
  Set-Location "P:"
  Write-Host "Начинаем Установку... Ожидайте завершения..." -ForegroundColor Green
  Start-Process .\setup.exe -ArgumentList "$SetupArgs2019" -Verb RunAs -Wait -Verbose -ErrorAction SilentlyContinue 
  Remove-PSDrive -Name 'P' -Force | Out-Null
  Write-Host "Установка завершена" -ForegroundColor Green

}





function SelectAction { # Тут просто метод Switch в функции. чтоб зациклить. Да, да не красиво. Работает и хрен с ним.
  
  Write-Host
  Write-Host "выберите действие" -BackgroundColor White -ForegroundColor Red
  Write-Host 

  Write-Host "1. Удалить офис 2016\Скайп для бизнеса \project \ visio " -ForegroundColor Green
  Write-Host "2. Установка офис 2019x64_Rus" -ForegroundColor Green
  Write-Host "3. Удалить офис 2016 и все компоненты + Установка офис 2019x64_Rus" -ForegroundColor Green
  Write-Host "4. Установка офис 2019x64_Rus + Visio + Project" -ForegroundColor Green
  Write-Host "5. Установка Visio 2019x64" -ForegroundColor Green
  Write-Host "6. Установка Project 2019x64" -ForegroundColor Green
  Write-Host "7. Выход" -ForegroundColor Green
  Write-Host
  $choice = Read-Host "Выберите пункт меню"

  Switch ($choice) {
    1 { RemoveOffice2016 }
    2 { SetupOffice2019 -OfficeOnly }
    3 {
      RemoveOffice2016
      SetupOffice2019 -OfficeOnly
    }
    4 { SetupOffice2019 -OfficeVisioProject }
    5 { SetupOffice2019 -VisioOnly }
    6 { SetupOffice2019 -ProjectOnly }
    7 {
      Stop-Transcript  # Заканчиваем  вести летопись.
      exit 
    }
    default { Write-Host "Нет! Выбери еще раз!" -ForegroundColor Red }

 
  
  }
  SelectAction
}
SelectAction
