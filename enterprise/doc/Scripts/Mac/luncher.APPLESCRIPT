do shell script "'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' --disable-translate --allow-running-insecure-content --no-default-browser-check --no-message-box --noerrdialogs --reload-killed-tabs --disable-desktop-notifications --disk-cache-size 5221225472 > /dev/null 2>&1 &" 
delay 5
try
    tell application "Google Chrome.app" 
        activate
        delay 2
        if not (exists window 1) then make new window
        tell window 1
            set URL of active tab to "https://signage.flinders.edu.au/en/displays/3/present.html" 
        end tell
    end tell
on error
    delay 5
    tell application "Google Chrome.app" 
        activate
        delay 3
        if not (exists window 1) then make new window
        delay 1
        tell window 1
            set URL of active tab to "https://signage.flinders.edu.au/en/displays/3/present.html" 
        end tell
    end tell
end try
tell application "Google Chrome.app" 
    activate
    tell application "System Events" 
        keystroke "f" using {command down, shift down}
        delay 1
        keystroke "r" using command down
    end tell
end tell