    function Set-Mize() {
    
        [CmdletBinding()]
        param([parameter]
            [object]$Process,
            [parameter]
            [switch]$Maximize,
            [parameter]
            [switch]$Minimize)
            
        [string]$user32_assembly_import =  '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
        [string]$user32_assembly_import += '[DllImport("user32.dll")] public static extern int SetForegroundWindow(IntPtr hwnd);'
        $user32_dll = Add-Type -MemberDefinition $user32_assembly_import -name NativeMethods -namespace Win32
        
        if($Maximize){ $option = 3 }
        if($Minimize){ $option = 4 }
        $hwnd = $process.MainWindowHandle
        [Win32.NativeMethods]::ShowWindowAsync($hwnd, $option)
        [Win32.NativeMethods]::SetForegroundWindow($hwnd) 

        }

    function Set-WindowPosition {

        [OutputType('System.Automation.WindowInfo')]
        [CmdletBinding()]
        Param (
            [parameter(ValueFromPipelineByPropertyName=$True)]
            [object]$Process,
            [parameter(ValueFromPipelineByPropertyName=$True)]
            [int]$X,
            [parameter(ValueFromPipelineByPropertyName=$True)]
            [int]$Y,
            [parameter(ValueFromPipelineByPropertyName=$True)]
            [int]$Width,
            [parameter(ValueFromPipelineByPropertyName=$True)]
            [int]$Height,
            [parameter(ValueFromPipelineByPropertyName=$True)]
            [switch]$Passthru )

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
            $Processname = $Process.name 
            $Rectangle = New-Object RECT
            $Handle = [system.intptr]$Process.MainWindowHandle
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
    
    #Additional function
    function Start-ProcessToForeground{

        [CmdletBinding()]
        Param ( [string]$FilePath,
                [string]$ArgumentList
                )
        Start-Process -FilePath $FilePath | Wait-Process
        $process = (Get-Process | Where-Object { $_.Path -eq $FilePath })
        $process_name = $process.processname 

        Set-Mize $process -Minimize
        Set-Mize $process -Maximize

        }
        
    #Example run
    #$proc = get-process -name *chrome*
    #Set-Mize -Process $proc -Maximize }
    #Set-WindowPosition -Process $proc -x 2625 -y 0 -Width 439 -Height 1087


