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

