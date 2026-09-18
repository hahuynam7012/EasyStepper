Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Ezi_Motion - Stepper Control"
$form.Size = New-Object System.Drawing.Size(520, 640)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false

$script:serialPort = $null
$script:teachingList = [System.Collections.Generic.List[string]]::new()
$script:currentPos = 0.0
$script:loopCount = 0
$script:currentIndex = 0

$groupConnection = New-Object System.Windows.Forms.GroupBox
$groupConnection.Text = "Ket noi phan cung (ESP32-S3)"
$groupConnection.Location = New-Object System.Drawing.Point(15, 15)
$groupConnection.Size = New-Object System.Drawing.Size(475, 70)

$lblPort = New-Object System.Windows.Forms.Label
$lblPort.Text = "Cong COM:"
$lblPort.Location = New-Object System.Drawing.Point(15, 30)
$lblPort.AutoSize = $true
$groupConnection.Controls.Add($lblPort)

$comboPorts = New-Object System.Windows.Forms.ComboBox
$comboPorts.Location = New-Object System.Drawing.Point(90, 27)
$comboPorts.Size = New-Object System.Drawing.Size(120, 25)
$ports = [System.IO.Ports.SerialPort]::GetPortNames()
if ($ports.Length -gt 0) { $comboPorts.Items.AddRange($ports); $comboPorts.SelectedIndex = 0 }
$groupConnection.Controls.Add($comboPorts)

$btnConnect = New-Object System.Windows.Forms.Button
$btnConnect.Text = "Ket noi"
$btnConnect.Location = New-Object System.Drawing.Point(220, 25)
$btnConnect.Size = New-Object System.Drawing.Size(110, 28)
$groupConnection.Controls.Add($btnConnect)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Trang thai: Ngat"
$lblStatus.ForeColor = [System.Drawing.Color]::Red
$lblStatus.Location = New-Object System.Drawing.Point(340, 30)
$lblStatus.AutoSize = $true
$groupConnection.Controls.Add($lblStatus)
$form.Controls.Add($groupConnection)

$groupControl = New-Object System.Windows.Forms.GroupBox
$groupControl.Text = "Dieu khien thu cong & Thong so"
$groupControl.Location = New-Object System.Drawing.Point(15, 95)
$groupControl.Size = New-Object System.Drawing.Size(475, 130)

$lblStep = New-Object System.Windows.Forms.Label
$lblStep.Text = "Buoc nhay (Deg):"
$lblStep.Location = New-Object System.Drawing.Point(15, 30)
$lblStep.AutoSize = $true
$groupControl.Controls.Add($lblStep)

$txtStepSize = New-Object System.Windows.Forms.TextBox
$txtStepSize.Text = "45"
$txtStepSize.Location = New-Object System.Drawing.Point(130, 27)
$txtStepSize.Size = New-Object System.Drawing.Size(80, 25)
$groupControl.Controls.Add($txtStepSize)

$btnMinus = New-Object System.Windows.Forms.Button
$btnMinus.Text = "(-) Quay Nguoc"
$btnMinus.Location = New-Object System.Drawing.Point(15, 75)
$btnMinus.Size = New-Object System.Drawing.Size(140, 35)
$btnMinus.BackColor = [System.Drawing.Color]::LightCoral
$groupControl.Controls.Add($btnMinus)

$btnPlus = New-Object System.Windows.Forms.Button
$btnPlus.Text = "(+) Quay Xuoi"
$btnPlus.Location = New-Object System.Drawing.Point(165, 75)
$btnPlus.Size = New-Object System.Drawing.Size(140, 35)
$btnPlus.BackColor = [System.Drawing.Color]::LightGreen
$groupControl.Controls.Add($btnPlus)

$lblCurrent = New-Object System.Windows.Forms.Label
$lblCurrent.Text = "Vi tri hien tai: 0.0 deg"
$lblCurrent.Location = New-Object System.Drawing.Point(320, 30)
$lblCurrent.AutoSize = $true
$groupControl.Controls.Add($lblCurrent)
$form.Controls.Add($groupControl)

# --- GROUP TEACHING ---
$groupTeaching = New-Object System.Windows.Forms.GroupBox
$groupTeaching.Text = "Chuc nang Teaching (Lap trinh chu trinh)"
$groupTeaching.Location = New-Object System.Drawing.Point(15, 235)
$groupTeaching.Size = New-Object System.Drawing.Size(475, 355)

$listBoxSteps = New-Object System.Windows.Forms.ListBox
$listBoxSteps.Location = New-Object System.Drawing.Point(15, 25)
$listBoxSteps.Size = New-Object System.Drawing.Size(300, 260)
$groupTeaching.Controls.Add($listBoxSteps)

$btnAddTeach = New-Object System.Windows.Forms.Button
$btnAddTeach.Text = "Ghi Nho Buoc Nay"
$btnAddTeach.Location = New-Object System.Drawing.Point(330, 25)
$btnAddTeach.Size = New-Object System.Drawing.Size(130, 40)
$groupTeaching.Controls.Add($btnAddTeach)

$btnDeleteStep = New-Object System.Windows.Forms.Button
$btnDeleteStep.Text = "Xoa Buoc Chon"
$btnDeleteStep.Location = New-Object System.Drawing.Point(330, 75)
$btnDeleteStep.Size = New-Object System.Drawing.Size(130, 35)
$groupTeaching.Controls.Add($btnDeleteStep)

$btnClearTeach = New-Object System.Windows.Forms.Button
$btnClearTeach.Text = "Xoa Tat Ca"
$btnClearTeach.Location = New-Object System.Drawing.Point(330, 120)
$btnClearTeach.Size = New-Object System.Drawing.Size(130, 35)
$groupTeaching.Controls.Add($btnClearTeach)

$btnRunAuto = New-Object System.Windows.Forms.Button
$btnRunAuto.Text = "CHAY TU DONG (RUN)"
$btnRunAuto.Location = New-Object System.Drawing.Point(330, 170)
$btnRunAuto.Size = New-Object System.Drawing.Size(130, 60)
$btnRunAuto.BackColor = [System.Drawing.Color]::Gold
$groupTeaching.Controls.Add($btnRunAuto)

$lblLoopCount = New-Object System.Windows.Forms.Label
$lblLoopCount.Text = "So lan loop: 0"
$lblLoopCount.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblLoopCount.Location = New-Object System.Drawing.Point(330, 245)
$lblLoopCount.Size = New-Object System.Drawing.Size(130, 40)
$groupTeaching.Controls.Add($lblLoopCount)

$form.Controls.Add($groupTeaching)

# --- Timer tự động chạy không đơ giao diện ---
$autoTimer = New-Object System.Windows.Forms.Timer
$autoTimer.Interval = 1500

$autoTimer.Add_Tick({
    if ($script:teachingList.Count -eq 0) {
        $autoTimer.Stop()
        return
    }

    $angle = $script:teachingList[$script:currentIndex]
    
    if ($script:serialPort -ne $null -and $script:serialPort.IsOpen) {
        try {
            $script:serialPort.WriteLine($angle.ToString())
            $script:currentPos = [double]$angle
            $lblCurrent.Text = "Vi tri hien tai: $script:currentPos deg"
        } catch {}
    }

    $script:currentIndex++
    
    if ($script:currentIndex -ge $script:teachingList.Count) {
        $script:currentIndex = 0
        $script:loopCount++
        $lblLoopCount.Text = "So lan loop: $script:loopCount"
    }
})

$btnConnect.Add_Click({
    if ($script:serialPort -eq $null -or -not $script:serialPort.IsOpen) {
        try {
            $portName = $comboPorts.SelectedItem.ToString()
            $script:serialPort = New-Object System.IO.Ports.SerialPort($portName, 115200, [System.IO.Ports.Parity]::None, 8, [System.IO.Ports.StopBits]::One)
            $script:serialPort.Open()
            $btnConnect.Text = "Ngat ket noi"
            $lblStatus.Text = "Trang thai: Da ket noi"
            $lblStatus.ForeColor = [System.Drawing.Color]::Green
            $comboPorts.Enabled = $false
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Khong the ket noi cong COM: $_", "Loi", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    } else {
        try {
            $script:serialPort.Close()
            $btnConnect.Text = "Ket noi"
            $lblStatus.Text = "Trang thai: Ngat"
            $lblStatus.ForeColor = [System.Drawing.Color]::Red
            $comboPorts.Enabled = $true
        } catch {}
    }
})

function Send-Command($angle) {
    if ($script:serialPort -ne $null -and $script:serialPort.IsOpen) {
        try {
            $script:serialPort.WriteLine($angle.ToString())
            $script:currentPos = [double]$angle
            $lblCurrent.Text = "Vi tri hien tai: $script:currentPos deg"
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Loi truyen du lieu: $_", "Loi", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Chua ket noi phan cứng ESP32!", "Canh bao", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
}

$btnMinus.Add_Click({
    $step = 0.0
    if ([double]::TryParse($txtStepSize.Text, [ref]$step)) {
        $target = $script:currentPos - $step
        Send-Command $target
    }
})

$btnPlus.Add_Click({
    $step = 0.0
    if ([double]::TryParse($txtStepSize.Text, [ref]$step)) {
        $target = $script:currentPos + $step
        Send-Command $target
    }
})

$btnAddTeach.Add_Click({
    $stepItem = "Quay den vi tri: $script:currentPos deg"
    [void]$script:teachingList.Add($script:currentPos)
    [void]$listBoxSteps.Items.Add($stepItem)
})

$btnDeleteStep.Add_Click({
    $idx = $listBoxSteps.SelectedIndex
    if ($idx -ge 0) {
        $listBoxSteps.Items.RemoveAt($idx)
        $script:teachingList.RemoveAt($idx)
    } else {
        [System.Windows.Forms.MessageBox]::Show("Vui long chon mot buoc de xoa!", "Thong bao", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

$btnClearTeach.Add_Click({
    $autoTimer.Stop()
    $script:teachingList.Clear()
    $listBoxSteps.Items.Clear()
    $script:loopCount = 0
    $script:currentIndex = 0
    $lblLoopCount.Text = "So lan loop: 0"
    $btnRunAuto.Text = "CHAY TU DONG (RUN)"
    $btnRunAuto.BackColor = [System.Drawing.Color]::Gold
    $btnAddTeach.Enabled = $true
    $btnDeleteStep.Enabled = $true
    $btnClearTeach.Enabled = $true
    $btnMinus.Enabled = $true
    $btnPlus.Enabled = $true
})

$btnRunAuto.Add_Click({
    if (-not $autoTimer.Enabled) {
        if ($script:teachingList.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Chua co chu trình Teaching nao duoc ghi lai!", "Thong bao", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        if ($script:serialPort -eq $null -or -not $script:serialPort.IsOpen) {
            [System.Windows.Forms.MessageBox]::Show("Chua ket noi phan cứng ESP32!", "Loi", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }

        $script:currentIndex = 0
        $autoTimer.Start()
        
        $btnRunAuto.Text = "DUNG (STOP)"
        $btnRunAuto.BackColor = [System.Drawing.Color]::LightCoral
        $btnAddTeach.Enabled = $false
        $btnDeleteStep.Enabled = $false
        $btnClearTeach.Enabled = $false
        $btnMinus.Enabled = $false
        $btnPlus.Enabled = $false
    } else {
        $autoTimer.Stop()
        
        $btnRunAuto.Text = "CHAY TU DONG (RUN)"
        $btnRunAuto.BackColor = [System.Drawing.Color]::Gold
        $btnAddTeach.Enabled = $true
        $btnDeleteStep.Enabled = $true
        $btnClearTeach.Enabled = $true
        $btnMinus.Enabled = $true
        $btnPlus.Enabled = $true
    }
})

[void]$form.ShowDialog()
