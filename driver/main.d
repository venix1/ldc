//===-- driver/main.d - D entry point -----------------------------*- D -*-===//
//
//                         LDC – the LLVM D compiler
//
// This file is distributed under the BSD-style LDC license. See the LICENSE
// file for details.
//
//===----------------------------------------------------------------------===//
//
// D entry point for LDC/LDMD, just forwarding to cppmain().
//
//===----------------------------------------------------------------------===//

module driver.main;

// In driver/main.cpp or driver/ldmd.cpp
extern(C++) int cppmain();

/+ We use this manual D main for druntime initialization via a manual
 + _d_run_main() call in the C main() in driver/{main,ldmd}.cpp.
 +/
extern(C) int _Dmain(string[])
{
    version (Windows)
        switchConsoleCodePageToUTF8();

    return cppmain();
}

extern(C) void do_lowmem()
{
    import core.runtime : Runtime;

    // Get args and append -lowmem
    auto commandLine = Runtime.args ~ "-lowmem";
    version (Posix)
    {
        import std.process;
        execv(commandLine[0], commandLine);
        throw new Exception("Failed to restart with -lowmem");
    }
    /* Should work but needs testing
    else version (Windows)
    {
        import core.stdc.stdlib : _Exit;
        _Exit(wait(spawnProcess(commandLine)));
    }
    */
    else
    {
        // no more silently ignoring this
        throw new Exception("-lowmem cannot be set in configuration file for this platform");
    }
}

// We use UTF-8 for narrow strings, on Windows too.
version (Windows)
{
    import core.sys.windows.wincon;
    import core.sys.windows.windef : UINT;

    private:

    __gshared UINT originalCP, originalOutputCP;

    void switchConsoleCodePageToUTF8()
    {
        import core.stdc.stdlib : atexit;
        import core.sys.windows.winnls : CP_UTF8;

        originalCP = GetConsoleCP();
        originalOutputCP = GetConsoleOutputCP();

        SetConsoleCP(CP_UTF8);
        SetConsoleOutputCP(CP_UTF8);

        // atexit handlers are also called when exiting via exit() etc.;
        // that's the reason this isn't a RAII struct.
        atexit(&resetConsoleCodePage);
    }

    extern(C) void resetConsoleCodePage()
    {
        SetConsoleCP(originalCP);
        SetConsoleOutputCP(originalOutputCP);
    }
}

// TLS bracketing symbols required for our custom TLS emulation on Android
// as we don't have a D main() function for LDC and LDMD.
version (Android)
{
    import ldc.attributes;

    extern(C) __gshared
    {
        @section(".tdata")
        int _tlsstart = 0;
        @section(".tcommon")
        int _tlsend = 0;
    }
}
