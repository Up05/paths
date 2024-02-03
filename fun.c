#include <windows.h>

// Could, probably, be replaced with os.exists()/os.is_dir(), which would make the program more software independent, but I can't be botherred now...

// completely from: https://stackoverflow.com/questions/6218325/how-do-you-check-if-a-directory-exists-on-windows-in-c
BOOL dir_exists(LPCTSTR szPath)
{
  DWORD dwAttrib = GetFileAttributes(szPath);

  return (dwAttrib != INVALID_FILE_ATTRIBUTES && 
         (dwAttrib & FILE_ATTRIBUTE_DIRECTORY));
}
