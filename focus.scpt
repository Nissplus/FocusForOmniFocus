#!/usr/bin/osascript
# vim: set filetype=applescript :
-- Copyright (c) 2010 Gregory A Frascadore
-- Licensed under the Open Software License version 3.0

# from 
# http://forums.omnigroup.com/archive/index.php/t-7998.html

(* 
Run from Launchbar to refocus current window on any projects
whose names match a sub-string entered in Launchbar.

If the script is indexed in and summoned from Launchbar,
tapping spacebar will allow you enter enough of any substring 
of a project name to uniquely identify it. 

If the string entered turns out not to be unique, 
then a list of candidate projects will get the focus in the current window.

(Useful to me as I often have a small set of projects with related names)
*)
property pstrTitle : "Focus on project"
property pmaxProjCount : 20

on run (sProjName)

    -- if sProjName is missing we will focus on Inbox,
    -- but if the sProjName is Foo (including "Inbox") we will
    -- focus on projects containing Foo, not Inbox

    tell application id "com.omnigroup.OmniFocus"
        set oDoc to default document
        set oWin to my firstVisibleWindow(oDoc)
        if oWin is missing value then
            set oWin to make new document window with properties { ¬
                bounds: {0,0,800,1200}, ¬
                selected view mode identifier:"project" ¬
            }
        end

        set lstprojects to {}
        if length of sProjName > 0 then
            -- set lstprojects to lstprojects & my ProjectsByName(oDoc, sProjName)
            -- set lstprojects to my FoldersByName(oDoc, sProjName)
            -- set lstprojects to my TasksByName(oDoc, sProjName)
            -- set lstprojects to lstprojects & my SectionsByTaskName(oDoc, sProjName)
            set lstprojects to lstprojects & my projectsHavingname(sections of oDoc, sProjName)
        end

        tell oWin 
            if lstprojects is {} and length of sProjName > 0 then
                return "nothing found"
            end if

            if lstprojects is {} then
                set focus to {}
                tell sidebar to select inbox
                set selected sorting identifier of content to "modified"
                set selected task state filter identifier of content to "incomplete"
                set search term to ""
                set visible of oWin to true
                tell oWin to activate
                return {}
            else
                set search term to missing value
                set focus to lstprojects
                tell sidebar to select library
                set selected sorting identifier of content to "modified"
                set selected task state filter identifier of content to "incomplete"
                set search term to sProjName
                set visible of oWin to true
                tell oWin to activate
                return properties of oWin
            end
        end
    end 
    tell application "System Events"
       tell process "Dashboard"
        delay 0.3
        key code 111
    return lstprojects
    end
    end
end run

on firstVisibleWindow(oDoc)
    using terms from application "OmniFocus"
        set oWin to missing value
        set aWindows to document windows of oDoc
        repeat with oWin in aWindows
            if oWin is visible then
                exit repeat
            end if
        end repeat
        if oWin is missing value or oWin is not visible then
            tell oDoc to ¬
                set oWin to make new document window with properties { ¬
                    bounds: {0,0,800,1200}, ¬
                    visible: true, ¬
                    selected view mode identifier:"project" ¬
                }
        end
        return oWin
    end using terms from
end firstVisibleWindow

on ProjectsByName(oDoc, strName)
    using terms from application "OmniFocus"
    tell oDoc
        set lstMatches to (complete strName as project ¬
            maximum matches pmaxProjCount)
        set lstprojects to {}
        repeat with recMatch in lstMatches
        if name of recMatch contains strName then
            set end of lstprojects to project id (id of recMatch)
        end
        end repeat
        return lstprojects
    end tell
    end using terms from
end ProjectsByName

on FoldersByName(oParent, strName)
    using terms from application "OmniFocus"
    set lstMatches to folders of oParent where name contains strName
    if length of lstMatches > 0 then
        return lstMatches
    else
        set lstFolders to {}
        repeat with oFolder in folders of oParent
        set lstFolders to lstFolders & my FoldersByName(oFolder, strName)
        end repeat
    end if
    return lstFolders
    end using terms from
end FolderByName

on TasksByName(oParent, strName)
    using terms from application "OmniFocus"
    set lstMatches to tasks of contents of oParent where name contains strName
    if length of lstMatches > 0 then
        return first item of lstMatches
    else
        set lstFolders to folders of oParent
        repeat with oFolder in lstFolders
        set varResult to TasksByName(oFolder, strName)
        if varResult is not missing value then return varResult
        end repeat
    end if
    return missing value
    end using terms from
end TasksByName

on SectionsByTaskName(oParent, sName)
    using terms from application "OmniFocus"
    try
        -- set aMatches to get every project of oParent ¬
        set aMatches to get every section of oParent ¬
        where some task's name contains sName

        return aMatches
    on error
        set aMatches to {}
    end try
    set aFolders to folders of oParent
    repeat with oFolder in aFolders
        set aMatches to aMatches & my SectionsByTaskName(oFolder, sName)
    end repeat
    return aMatches
    end using terms from
end SectionsByTaskName

on projectsHavingName(aSections, sName)
    using terms from application "OmniFocus"
        local aResults
        set aResults to {}
        repeat with oSection in aSections
            try
                set aTasks to tasks of oSection
            on error
                set aTasks to {}
            end try
            if oSection's name contains sName then
                set beginning of aResults to oSection
            else if my someTaskHasName(aTasks, sName) then
                set beginning of aResults to oSection
            else
                try
                    set aResults to my projectsHavingName(sections of oSection, sName) & aResults
                on error
                    -- ignore
                end try
            end if
        end repeat
        return aResults
    end using terms from
end projectsHavingName

on someTaskHasName(aTasks, sName)
    local aSubTasks    
    using terms from application "OmniFocus"
        repeat with oTask in aTasks
            set aSubTasks to tasks of oTask
            if name of oTask contains sName then
                return true
            else if someTaskHasName(aSubTasks, sName)
                return true
            end
        end repeat
        return false
    end using terms from
end someTaskHasName

on classList(aSections)
    set aResults to {}
    repeat with oSection in aSections
        set aResults to class of oSection & aResults
    end repeat
    return aResults
end classList



