# howto

## Policy for New Registry (*.reg) Items

- If a registry item was exported from Windows Registry
  - Scan item closely
  - If any part of the item
    - has sensitive information, or
    - is unreadable
  - Then
    - Do not put item here; put in a secure location for registry backups
  - Else
    - If item is a reverse of another saved item ``date_Verb-Object.reg``
      - Save to ``reverse`` as ``date_InverseVerb-Object.reg``
        - eg 1
          - item A: ``./2026-01-01_Remove-GameDvr.reg``
          - item B: ``./reverse/2026-01-01_Add-GameDvr.reg``
    - Else
      - Save to ``backup``
        - With ``date_Verb-Object.reg`` name format
- If a registry item was researched
  - Save the item as a file
    - With a link to the source, in its comments
    - With ``date_Verb-Object.reg`` name format
    - If to be applied now
      - If the file deletes a key
        - Export the key as a new registry item, and the reverse of ``date_Verb-Object.reg``
      - Save to the root of this folder
      - Log the change to a ``journal``, either here or in ``../doc``
    - Else
      - Save to ``suspend``

# link

## ElevenForums Windows Registry

| retrieved | resource | url |
|-----------|----------|-----|
| 2024-11-04 | Add-RecentFilesInFileExplorerHome.reg | <https://www.elevenforum.com/t/add-or-remove-recent-files-in-file-explorer-home-in-windows-11.6825/> |
|  | Remove-RecentFilesInFileExplorerHome.reg |  |

## ThioJoe: Old Windows Context Menu

- url
  - <https://github.com/ThioJoe>
  - <https://gist.github.com/ThioJoe>
  - <https://www.youtube.com/watch?v=JVoBbLfSinI>
- retrieved: 2024-10-06

### howto

1. Choose which version you want to use:
   - "Full Menu" Version: The same as the original one in the new context menu, and has multiple sub-menu items
   - Other Version: Doesn't have a sub-menu, it just directly opens the "Create Archive" menu. (The equivalent of clicking the "Additional Options" sub-item in the original)

2. Double click the "Add_" reg file of whichever version you choose

3. Restart Windows Explorer
   - You can restart it by opening Task Manager with Ctrl+Shift+Esc, then search it for "Windows Explorer", right click that and hit "Restart"
   - You can also just restart the whole computer of course

----------------------------------------------------------
Technical Explanation / Notes For Anyone Curious:

- This won't overwrite any existing registry entries or anything, it only creates a couple new ones
- You could add both versions and they'll both be there. They're independent, so if you add both, you'll need to remove both separately too using theire respective "Remove_" reg files.

- The tweak basically works by copying the registry entries that makes the command appear in the 'new' start menu, and adds them to the old menu as well
- Behind the scenes, the "Create Archive" menu is given the command name "Windows.CompressTo.Wizard" which exists at: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.CompressTo.Wizard
  - The full "Compress To" menu has the command name "Windows.CompressTo" which exists at: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Windows.CompressTo

