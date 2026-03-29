#Requires AutoHotkey v2.0

; 全局变量
global g_running := false
global g_paused := false
global g_stop := false

; --- GUI 创建 ---
MyGui := Gui("+AlwaysOnTop", "自动打字机 @24YAN")
MyGui.OnEvent("Close", (*) => ExitApp())

MyGui.Add("Text", "w380", "1. 把要输入的内容粘贴到下面框里：")
global MyEdit := MyGui.Add("Edit", "w380 h150 vInputText", "把你要交的作业粘贴在这里...")

MyGui.Add("Text", "w380 y+15", "2. 设置打字速度和换行方式：")
global SpeedSlider := MyGui.Add("Slider", "w200 vSpeed ToolTip", 50)
MyGui.Add("Text", "x+10 yp", "打字速度 (左快右慢)")
global ShiftEnterChk := MyGui.Add("Checkbox", "w380 xm vUseShiftEnter Checked", "换行时使用 Shift+Enter (防聊天框直接发送)")

MyGui.Add("Text", "w380 y+20 cBlue", "【使用说明】")
MyGui.Add("Text", "w380 y+5", "方式一：点“准备打字”后，你有 3 秒钟时间把光标点进目标输入框！")
MyGui.Add("Text", "w380 y+5", "方式二（推荐）：提前把光标点进输入框，直接按【F7】开始打字！")
MyGui.Add("Text", "w380 y+5", "随时按【F8】紧急停止，按【F9】暂停/继续。")

BtnStart := MyGui.Add("Button", "w380 h40 y+15 Default", "准备打字 (点我后3秒开始，或直接按 F7 开始)")
BtnStart.OnEvent("Click", StartTypingFromGui)

MyGui.Show("w420")

; --- 快捷键 ---
F7::StartTypingShortcut()
F9::TogglePause()
F8::StopTyping()

; --- 逻辑函数 ---
StartTypingShortcut(*) {
	global g_running
	if g_running
		return
	
	text := MyGui.Submit(false).InputText
	if (text = "" || text = "把你要交的作业粘贴在这里...") {
		MsgBox "你还没填内容呢！", "提示", "Icon!"
		return
	}
	
	; 快捷键启动，直接开始（无需3秒倒计时），因为用户肯定已经把光标放在目标框里了
	DoTyping(text)
}

StartTypingFromGui(*) {
	global g_running
	
	if g_running {
		MsgBox "已经在打字了，请先按 F8 停止！", "提示", "Iconi"
		return
	}
	
	text := MyGui.Submit(false).InputText
	if (text = "" || text = "把你要交的作业粘贴在这里...") {
		MsgBox "你还没填内容呢！", "提示", "Icon!"
		return
	}
	
	; 按钮启动，给3秒倒计时
	ToolTip "准备... 3"
	Sleep 1000
	ToolTip "准备... 2"
	Sleep 1000
	ToolTip "准备... 1"
	Sleep 1000
	
	DoTyping(text)
}

DoTyping(text) {
	global g_running, g_paused, g_stop
	g_running := true
	g_paused := false
	g_stop := false
	
	ToolTip "开始打字！(F8停止，F9暂停)"
	
	TypeText(text)
	
	g_running := false
	ToolTip
	MsgBox "打字完成！", "提示", "Iconi T2"
}

TogglePause() {
	global g_running, g_paused
	if !g_running
		return
	g_paused := !g_paused
	if g_paused
		ToolTip "【已暂停】按 F9 继续，F8 停止"
	else
		ToolTip "开始打字！(F8停止，F9暂停)"
}

StopTyping() {
	global g_running, g_stop
	if !g_running
		return
	g_stop := true
	ToolTip "【已停止】"
	Sleep 1000
	ToolTip
}

TypeText(text) {
	global g_paused, g_stop
	
	; 从 GUI 获取设置
	saved := MyGui.Submit(false)
	BaseDelayMs := saved.Speed
	JitterMs := 20
	PunctExtraMs := 100
	UseShiftEnter := saved.UseShiftEnter
	
	chars := StrSplit(text, "")
	for _, ch in chars {
		if g_stop
			break
			
		while g_paused {
			if g_stop
				return
			Sleep 50
		}
		
		if (ch = "`r")
			continue
			
		if (ch = "`n") {
			if UseShiftEnter
				Send "+{Enter}"
			else
				Send "{Enter}"
			Sleep RandDelay(BaseDelayMs, JitterMs) + 100
			continue
		}
		
		if (ch = "`t") {
			SendText "    "
			Sleep RandDelay(BaseDelayMs, JitterMs)
			continue
		}
		
		SendText ch
		delay := RandDelay(BaseDelayMs, JitterMs)
		if InStr("，。！？；：,.!?;:", ch)
			delay += PunctExtraMs
		Sleep delay
	}
}

RandDelay(base, jitter) {
	if (jitter <= 0)
		return base
	return base + Random(0, jitter)
}
