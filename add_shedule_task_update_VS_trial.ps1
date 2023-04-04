<#
based on https://github.com/beatcracker/VSCELicense




#>


$script = {
	Start-Transcript -Path c:\pslogs\posh.log -Append
	
	Add-Type -AssemblyName 'System.Security'
	New-Variable -Name VSCELicenseMap -Value @{
		'2017'  = 'Licenses\5C505A59-E312-4B89-9508-E162F8150517\08878'
		'2019'  = 'Licenses\41717607-F34E-432C-A138-A3CFD7E25CDA\09278'
	} -Option Constant
	
	function Test-Elevation
	{
		[bool](
			(
				[System.Security.Principal.WindowsIdentity]::GetCurrent()
			).Groups -contains 'S-1-5-32-544'
		)
	}
	
	function ConvertTo-BinaryDate
	{
		[CmdletBinding()]
		Param (
			[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
			[datetime]$Date
		)
		
		Process
		{
			$Date.Year, $Date.Month, $Date.Day | ForEach-Object {
				[System.BitConverter]::GetBytes([uint16]$_)
			}
		}
	}
	
	function ConvertFrom-BinaryDate
	{
		[CmdletBinding()]
		Param (
			[Parameter(Mandatory = $true)]
			[ValidateCount(6, 6)]
			[uint16[]]$InputObject
		)
		
		End
		{
			Get-Date -Year (
				[System.BitConverter]::ToInt16(
					$InputObject[0 .. 1],
					0
				)
			) -Month (
				[System.BitConverter]::ToInt16(
					$InputObject[2 .. 3],
					0
				)
			) -Day (
				[System.BitConverter]::ToInt16(
					$InputObject[4 .. 6],
					0
				)
			) -Hour 0 -Minute 0 -Second 0
		}
	}
	
	function ConvertTo-BinaryDate
	{
		[CmdletBinding()]
		Param (
			[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
			[datetime]$Date
		)
		
		Process
		{
			$Date.Year, $Date.Month, $Date.Day | ForEach-Object {
				[System.BitConverter]::GetBytes([uint16]$_)
			}
		}
	}
	
	Function Open-HKCRSubKey
	{
		[CmdletBinding()]
		Param (
			[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
			[ValidateNotNullOrEmpty()]
			[string]$SubKey,
			[switch]$ReadWrite
		)
		
		Begin
		{
			if ($ReadWrite -and -not (Test-Elevation))
			{
				throw 'This action requires elevated permissions. Run PowerShell as Administrator.'
			}
		}
		
		Process
		{
			try
			{
				$HKCR = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
					[Microsoft.Win32.RegistryHive]::ClassesRoot,
					[Microsoft.Win32.RegistryView]::Default
				)
				
				$LicenseKey = $HKCR.OpenSubKey(
					$SubKey,
					$ReadWrite
				)
			}
			catch
			{
				throw $_
			}
			finally
			{
				$HKCR.Dispose()
			}
			
			if ($null -ne $LicenseKey)
			{
				$LicenseKey
			}
		}
	}
	
	function Get-VSCELicenseExpirationDate
	{
		[CmdletBinding()]
		Param (
			[ValidateSet('2013', '2015', '2017', '2019')]
			[string[]]$Version = @('2013', '2015', '2017', '2019')
		)
		
		End
		{
			foreach ($v in $Version)
			{
				if ($LicenseKey = Open-HKCRSubKey -SubKey $VSCELicenseMap.$v)
				{
					
					try
					{
						$LicenseBlob = [System.Security.Cryptography.ProtectedData]::Unprotect(
							$LicenseKey.GetValue($null),
							$null,
							[System.Security.Cryptography.DataProtectionScope]::LocalMachine
						)
					}
					catch
					{
						throw $_
					}
					finally
					{
						$LicenseKey.Dispose()
					}
					
					[PSCustomObject]@{
						Version		    = $v
						ExpirationDate  = ConvertFrom-BinaryDate $LicenseBlob[-16..-11] -ErrorAction Stop
					}
				}
			}
		}
	}
	
	function Set-VSCELicenseExpirationDate
	{
		[CmdletBinding()]
		Param (
			[ValidateSet('2013', '2015', '2017', '2019')]
			[string[]]$Version = @('2013', '2015', '2017', '2019'),
			[ValidateRange(0, 31)]
			[int]$AddDays = 31
		)
		
		End
		{
			foreach ($v in $Version)
			{
				if ($LicenseKey = Open-HKCRSubKey -SubKey $VSCELicenseMap.$v -ReadWrite)
				{
					
					try
					{
						$LicenseBlob = [System.Security.Cryptography.ProtectedData]::Unprotect(
							$LicenseKey.GetValue($null),
							$null,
							[System.Security.Cryptography.DataProtectionScope]::LocalMachine
						)
						
						$NewExpirationDate = [datetime]::Today.AddDays($AddDays)
						
						$LicenseKey.SetValue(
							$null,
							[System.Security.Cryptography.ProtectedData]::Protect(
								@(
									$LicenseBlob[- $LicenseBlob.Count .. -17]
									$NewExpirationDate | ConvertTo-BinaryDate -ErrorAction Stop
									$LicenseBlob[-10 .. -1]
								),
								$null,
								[System.Security.Cryptography.DataProtectionScope]::LocalMachine
							),
							[Microsoft.Win32.RegistryValueKind]::Binary
						)
					}
					catch
					{
						throw $_
					}
					finally
					{
						$LicenseKey.Dispose()
					}
					
					[PSCustomObject]@{
						Version		    = $v
						ExpirationDate  = $NewExpirationDate
					}
				}
			}
		}
	}
	
	Set-VSCELicenseExpirationDate -AddDays 31
	Get-VSCELicenseExpirationDate
	
	Stop-Transcript
	
	
}

New-Item -Path "c:\" -Name "pslogs" -ItemType "directory" -ErrorAction SilentlyContinue
New-Item -Path "C:\Program Files (x86)\Microsoft Visual Studio\update_VS_trial.ps1"
Set-Content -Path "C:\temp\update_VS_trial.ps1" -Value $script

$Trigger = New-ScheduledTaskTrigger -At 10:00am -DaysInterval 30
$User = "NT AUTHORITY\SYSTEM"
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Restricted -File 'C:\Program Files (x86)\Microsoft Visual Studio\update_VS_trial.ps1'"
Register-ScheduledTask -TaskName "update_VS_trial" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest –Force
pause
