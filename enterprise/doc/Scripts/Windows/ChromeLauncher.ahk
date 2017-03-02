Run %LocalAppData%\Google\Chrome\Application\chrome.exe %1% --kiosk --disable-translate --allow-running-insecure-content --no-default-browser-check --no-message-box --noerrdialogs --reload-killed-tabs --disable-desktop-notifications --disk-cache-size 5221225472
Sleep 10000
if WinExist("ahk_class Chrome_WidgetWin_0")
    WinActivate
Send {F5}
Loop {
	Sleep 10000
	if WinExist("ahk_class Chrome_WidgetWin_0")
		WinActivate
	else
		break  ;
}
