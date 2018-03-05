function Set-ProcessWindows {
	<#
	.LINK
	https://gist.github.com/jakeballard/11240204
	#>

	[CmdletBinding(DefaultParameterSetName = 'InputObject')]
	param(
		[Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True)]
		[Object[]] $InputObject,
		[Parameter(Position = 1)]
		[ValidateSet('FORCEMINIMIZE', 'HIDE', 'MAXIMIZE', 'MINIMIZE', 'RESTORE', 'SHOW', 'SHOWDEFAULT', 'SHOWMAXIMIZED', 'SHOWMINIMIZED', 'SHOWMINNOACTIVE', 'SHOWNA', 'SHOWNOACTIVATE', 'SHOWNORMAL')]
		[string] $Style = 'SHOW'
	)

	BEGIN {
		$WindowStates = @{
			'FORCEMINIMIZE'   = 11
			'HIDE'            = 0
			'MAXIMIZE'        = 3
			'MINIMIZE'        = 6
			'RESTORE'         = 9
			'SHOW'            = 5
			'SHOWDEFAULT'     = 10
			'SHOWMAXIMIZED'   = 3
			'SHOWMINIMIZED'   = 2
			'SHOWMINNOACTIVE' = 7
			'SHOWNA'          = 8
			'SHOWNOACTIVATE'  = 4
			'SHOWNORMAL'      = 1
		}

$Win32ShowWindowAsync = Add-Type -MemberDefinition @'
[DllImport("user32.dll")] 
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow); 
'@ -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru
	
	}

	PROCESS {
		foreach ($process in $InputObject) {
		    $Win32ShowWindowAsync::ShowWindowAsync($process.MainWindowHandle, $WindowStates[$Style]) | Out-Null
		    Write-Verbose ("Set Window Style '{1} on '{0}'" -f $MainWindowHandle, $Style)
		}
	}
}

function Show-Process($Process, [Switch]$Maximize)
{
  $sig = '
    [DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern int SetForegroundWindow(IntPtr hwnd);
  '
  
  if ($Maximize) { $Mode = 3 } else { $Mode = 4 }
  $type = Add-Type -MemberDefinition $sig -Name WindowAPI -PassThru
  $hwnd = $process.MainWindowHandle
  $null = $type::ShowWindowAsync($hwnd, $Mode)
  $null = $type::SetForegroundWindow($hwnd) 
}

Function Set-Window {

    [OutputType('System.Automation.WindowInfo')]
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipelineByPropertyName=$True)]
        $ProcessName,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [switch]$Passthru
    )
    Begin {
        Try{
            [void][Window]
        } Catch {
        Add-Type @"
              using System;
              using System.Runtime.InteropServices;
              public class Window {
                [DllImport("user32.dll")]
                [return: MarshalAs(UnmanagedType.Bool)]
                public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

                [DllImport("User32.dll")]
                public extern static bool MoveWindow(IntPtr handle, int x, int y, int width, int height, bool redraw);
              }
              public struct RECT
              {
                public int Left;        // x position of upper-left corner
                public int Top;         // y position of upper-left corner
                public int Right;       // x position of lower-right corner
                public int Bottom;      // y position of lower-right corner
              }
"@
        }
    }
    Process {
        $Rectangle = New-Object RECT
        $Handle = [system.intptr](Get-Process -Name $Processname | select -ExpandProperty MainWindowHandle)
        $Return = [Window]::GetWindowRect($Handle,[ref]$Rectangle)
        If (-NOT $PSBoundParameters.ContainsKey('Width')) {            
            $Width = $Rectangle.Right - $Rectangle.Left            
        }
        If (-NOT $PSBoundParameters.ContainsKey('Height')) {
            $Height = $Rectangle.Bottom - $Rectangle.Top
        }
        If ($Return) {
            $Return = [Window]::MoveWindow($Handle, $x, $y, $Width, $Height,$True)
        }
        If ($PSBoundParameters.ContainsKey('Passthru')) {
            $Rectangle = New-Object RECT
            $Return = [Window]::GetWindowRect($Handle,[ref]$Rectangle)
            If ($Return) {
                $Height = $Rectangle.Bottom - $Rectangle.Top
                $Width = $Rectangle.Right - $Rectangle.Left
                $Size = New-Object System.Management.Automation.Host.Size -ArgumentList $Width, $Height
                $TopLeft = New-Object System.Management.Automation.Host.Coordinates -ArgumentList $Rectangle.Left, $Rectangle.Top
                $BottomRight = New-Object System.Management.Automation.Host.Coordinates -ArgumentList $Rectangle.Right, $Rectangle.Bottom
                If ($Rectangle.Top -lt 0 -AND $Rectangle.LEft -lt 0) {
                    Write-Warning "Window is minimized! Coordinates will not be accurate."
                }
                $Object = [pscustomobject]@{
                    ProcessName = $ProcessName
                    Size = $Size
                    TopLeft = $TopLeft
                    BottomRight = $BottomRight
                }
                $Object.PSTypeNames.insert(0,'System.Automation.WindowInfo')
                $Object            
            }
        }
    }
}

#Check for current resolution before running these commands

#Set the window positions
Get-Process "ts3client_win64"  | Set-WindowStyle -Style SHOW
Get-Process "ts3client_win64" | Set-Window -x 2908 -y 12
Show-Process "steam"
Get-Process "steam" | Set-Window -x 3284 -y 12


