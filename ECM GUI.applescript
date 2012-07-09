-- ECM GUI.applescript
-- ECM GUI

--  Created by Zack Schilling on Sat Oct 04 2003.
--  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
on clicked theObject
	
	if name of theObject is "select" then
		set contents of text field "filepath" of window "main" to POSIX path of (choose file with prompt "Select Output Destination") as string
	end if
	
	if name of theObject is "start" then
		if (state of button "terminal" of window "main") is 1 then
			
			if (current row of matrix "process" of window "main") = 1 then
				set processType to "ecm"
			else
				set processType to "unecm"
			end if
			
			
			set jobCommand to ("\"" & POSIX path of (path to me) & "Contents/Resources/" & processType & "\" \"" & (contents of text field "filepath" of window "main") & "\"")
			tell window "main"
				set contents of text field "statusText" to "Sending job to Terminal"
			end tell
			
			tell application "Terminal"
				do script with command jobCommand
			end tell
			
			tell window "main"
				set contents of text field "statusText" to "Ready"
			end tell
		else
			if (current row of matrix "process" of window "main") = 1 then
				set processType to "ecm"
			else
				set processType to "unecm"
			end if
			
			set jobCommand to ("\"" & POSIX path of (path to me) & "Contents/Resources/" & processType & "\" \"" & (contents of text field "filepath" of window "main") & "\"")
			tell window "main"
				set contents of text field "statusText" to "Processing files in shell"
			end tell
			do shell script jobCommand
			tell window "main"
				set contents of text field "statusText" to "Ready"
			end tell
			
		end if
		
		
		
	end if
	
end clicked
on open theObject
	set contents of text field "filepath" of window "main" to POSIX path of theObject as string
end open