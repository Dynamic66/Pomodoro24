<#
    .SYNOPSIS
        A simple Pomodoro Timer script that helps users stay focused and on track.
        The Pomodoro Technique is based on the idea of breaking down study sessions into short, focused intervals (typically 25 minutes) called "Pomodoros," separated by short breaks.

    .DESCRIPTION
        What is the Pomodoro Technique?
        1. Choose a task: Select a task you want to work on, such as studying for an exam, writing an essay, or practicing a new skill.
        2. Set the timer: Set a timer for 25 minutes (or another length of time that works for you). This is your Pomodoro interval.
        3. Work on the task: Focus exclusively on the task at hand during the Pomodoro interval. Avoid interruptions, emails, phone calls, or any other distractions.
        4. Take a break: When the timer goes off, take a 5-minute break. Stand up, stretch, move around, or do something relaxing to recharge.
        5. Repeat the cycle: After four Pomodoros, take a longer break of 15-30 minutes.

    .FUNCTIONALITY
        - To start the timer, simply click on the PowerShell window. The timer will begin counting down from the default 30-minute interval.
        - To pause the timer, click on the PowerShell window again. The timer will freeze at its current value.
        - To adjust the timer length, right-click on the PowerShell window to open the context menu. Select 'Set Timer Length' and enter a new value in minutes.

    .PARAMETER TimerLength (OPTIONAL)
        Specifies the length of the timer in seconds. The default value is 30 seconds.

    .PARAMETER AlarmFilePath (OPTIONAL)
        Specifies the file path of the .wav file to play as the alarm sound. The file path must end with the .wav extension. The default value is C:\Windows\Media\Alarm03.wav.

    .NOTES
        Benefits of the Pomodoro Technique
        - Improved focus: By dedicating a set amount of time to a task, you can eliminate distractions and stay focused.
        - Increased productivity: By working in focused intervals, you can complete tasks more efficiently and make the most of your study time.
        - Better time estimation: The Pomodoro Technique helps you estimate the time required for tasks more accurately, allowing you to plan your study schedule more effectively.
        - Reduced burnout: Regular breaks help prevent mental fatigue and reduce the likelihood of burnout.
        - Enhanced creativity: The breaks between Pomodoros can help you recharge and come back to your task with a fresh perspective.
#>



function Show-Timer {
    param(
        [int]$TimerLength = 30,
        [ValidatePattern('^[a-zA-Z0-9_\-]+\.wav$')] # pass .wav files only
        [string]$AlarmFilePath = 'C:\Windows\Media\Alarm03.wav',
        [Validatepattern('^([Ss]izable|[Nn]one|[Ff]ixed[Ss]ingle)$')]
        $FormBorderStyle = 'FixedSingle'
    )
    #region Declaration
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()
    
    $alarm = New-Object System.Media.SoundPlayer($AlarmFilePath)

    $fUI = New-Object system.windows.forms.form
    $lDisplay = New-Object System.Windows.Forms.Label #scriptcope because its used in a function and i cant be bother with importing it every time its called
    $lPomodoros = New-Object System.Windows.Forms.Label


    $tUIUpdater = New-Object System.Windows.forms.timer 
    $tdelay = New-Object System.Windows.Forms.Timer

    $Contextmenue = New-Object System.Windows.Forms.ContextMenuStrip
    $lMin = New-Object System.Windows.Forms.ToolStripLabel
    $tMin = New-Object System.Windows.Forms.ToolStripTextBox
    $bExit = New-Object System.Windows.Forms.ToolStripButton
    $bReset = New-Object System.Windows.Forms.ToolStripButton
    $bNewTimer = New-Object System.Windows.Forms.ToolStripButton
    $bTopmost = New-Object System.Windows.Forms.ToolStripButton

    $script:state = '▶'
    $alarm.LoadAsync()


    function Update-DisplayString {
        # $lDisplay.SuspendLayout() #suspending and resuming the layout prevents the text from fickering 
        $lDisplay.Text = "$script:state`n$('{0:mm\:ss}' -f (New-TimeSpan -Seconds $script:counter))" #formats seconds to a 00:00 format
        #$lDisplay.Refresh() #causes flicker befor unfreezing the layout
        #$lDisplay.ResumeLayout()
    }
    #endregion

    #region Contextmenu
    $bTopmost.add_click({
            if ($fui.topmost) {
                $fui.topmost = $false
                $bTopmost.text = '📌  Topmost: disbaled'
            }
            else {
                $fui.topmost = $true
                $bTopmost.text = '📌  Topmost: enabled'
            }
        })
    $bTopmost.text = '📌  Topmost: disbaled'


    $bNewTimer.add_click({
            Start-Process powershell.exe -WindowStyle Hidden -ArgumentList "-file $$"
        })
    $bNewTimer.Text = '⏲  Open another timer'

    $lMin.Text = '⏳   Set timer minutes'

    $tmin.add_TextChanged({
            $tmin.text = $tMin.Text -Replace ('\D')
            $script:Counter = 60 * $tMin.Text 
            Update-DisplayString
        })
    $tMin.Text = $timerLength
    $tMin.MaxLength = 4
    $tMin.Margin = '20,0,0,0'
    $tMin.BackColor = 'whitesmoke'
    
    $bReset.add_click({
            $script:Counter = 60 * $tMin.Text
            $script:pomodorocounter = 0
            $lPomodoros.Text = "$script:pomodoroCounter/$pomodoroMaximum"
            Update-DisplayString
        })
    $bReset.text = '↩  Reset'
    $bReset.Dock = 'fill'
    $bReset.ForeColor = 'darkblue'
    $bReset.TextAlign = 'MiddleLeft'
    
    $bExit.add_click({ $fui.Close() })
    $bExit.text = '❌  Exit'
    $bExit.TextAlign = 'MiddleLeft'
    $bExit.ForeColor = 'darkred'
    $bExit.Dock = 'fill'
    
    $Contextmenue.BackColor = 'whitesmoke'
    $Contextmenue.Opacity = 0.95
    $Contextmenue.ShowCheckMargin = $false
    $Contextmenue.ShowImageMargin = $false
    $Contextmenue.ShowItemToolTips = $false
    
    [void]$Contextmenue.Items.add($lMin)
    [void]$Contextmenue.Items.add($tMin)
    [void]$Contextmenue.Items.add($bTopmost)
    [void]$Contextmenue.Items.add($bNewTimer)
    [void]$Contextmenue.Items.add($bReset)
    [void]$Contextmenue.Items.add($bExit)
    #endregion

    #region MoveControl
    $lDisplay.add_mousedown({
            $script:isMoving = $false
            $tdelay.Start()
            $script:initialPosition = $args[1] | Select-Object x, y
        }) 
    $lDisplay.add_MouseMove({
            if ($script:moved) {
                if ($args.Button -eq [System.Windows.Forms.MouseButtons]::Left) {

                    $script:isMoving = $true   
                    $fUI.Cursor = [System.Windows.Forms.Cursors]::SizeAll
                    $currentPos = [System.Windows.Forms.Cursor]::Position
                    #grabs the form at the point when there mouse was clicked and moves it at this point #-10 because the controlbox is in flat format 
                    $fUI.Location = [System.Drawing.Point]::new([int]$currentPos.x - $script:initialPosition.x - 5, [int]$currentPos.y - $script:initialPosition.y - 5)  
                    # $fUI.Location = [System.Drawing.Point]::new([int]$currentPos.x - $script:initialPosition.x, [int]$currentPos.y - $script:initialPosition.y)  

                }
            }
        })



    $lDisplay.add_MouseUp({
            if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
                $script:moved = $false
                $fUI.Cursor = [System.Windows.Forms.Cursors]::Default
            }
        })
    
    $tdelay.Add_Tick({
            $Script:moved = $true
            $tdelay.Stop()
        })
    $tdelay.Interval = 100 
    #endregion

    #region UI
    $script:pomodoroCounter = 0
    $script:pomodoroMaximum = 4
    $lPomodoros.Text = "$script:pomodoroCounter/$pomodoroMaximum"
    $lPomodoros.dock = 'bottom'
    $lPomodoros.TextAlign = 'topcenter'
    

    $lDisplay.add_click({
            if ($args.button -eq 'left') {
                if (-not $script:isMoving) {
                    #reset timer
                    if ($script:Counter -le 0) {
                        $script:Counter = 60 * $tMin.Text
                        $script:pomodoroCounter++
                        $lPomodoros.Text = "$script:pomodoroCounter/$pomodoroMaximum"
                    }
                    #start timer
                    if ($tUIUpdater.Enabled) {
                        $tUIUpdater.Enabled = $false
                        $script:state = '▶'
                    }
                    #pause timer
                    else {
                        $tUIUpdater.Enabled = $true
                        $script:state = '⏸'
                    }
                    #Update Timer
                    Update-DisplayString
                }
            }
        })
    $lDisplay.dock = 'fill'
    $lDisplay.TextAlign = 'middlecenter'
    #$lDisplay.Font = 'arial,20'
    $lDisplay.Font = 'microsoft Yi Baiti,20' 
    $lDisplay.ContextMenuStrip = $Contextmenue
    Update-DisplayString #load initial display
    
    $tUIUpdater.add_tick({  
            if ($Counter -gt 0) {
                $script:Counter = $Counter - 1
            }
            else {
                $script:state = '↩'
                $tUIUpdater.Enabled = $false
                $fUI.TopMost = $true
                $fUI.TopMost = $false
                & { $alarm.Play() }
            }
            Update-DisplayString
        })
    $tUIUpdater.Interval = 1000

    $fui.add_shown({
            $fUI.TopMost = $true
            $fUI.TopMost = $false
        })
    $fUI.BackColor = 'whitesmoke'
    $fUI.ShowIcon = $false
    $fUI.MaximizeBox = $false
    $fUI.ControlBox = $false
    $fUI.Opacity = 0.85
    $fui.FormBorderStyle = $FormBorderStyle 
    $fUI.Size = '140,140'
    $fui.SizeGripStyle = 'show'
    $fUI.AutoScaleMode = 'Font'
    $fUI.StartPosition = 'CenterScreen'
    

    $fUI.controls.Add($lDisplay)
    $fUI.controls.Add($lPomodoros)

    #endregion
    #region start app
    [void]$fUI.ShowDialog()

    #cleanup
    $tUIUpdater.Stop() # mb not needed? had problems witht htis in onther projects
    $tUIUpdater.Dispose()
    $tdelay.Stop() # mb not needed? had problems witht htis in onther projects
    $tdelay.Dispose()
    #endregion
}

Show-Timer
