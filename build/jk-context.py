#!/usr/bin/env python3
"""jk-context - Thunar right-click custom actions ka helper.
Usage: jk-context <terminal|powershell|gitbash|gitgui|code|admin> <path>
Path file ho to uska folder use hota hai."""
import os, subprocess, sys
def main():
    if len(sys.argv) < 3: return 1
    mode, path = sys.argv[1], sys.argv[2]
    d = path if os.path.isdir(path) else os.path.dirname(os.path.abspath(path))
    if mode == "terminal":
        subprocess.Popen(["xfce4-terminal", "--working-directory", d])
    elif mode == "powershell":
        subprocess.Popen(["xfce4-terminal", "--working-directory", d, "-e", "pwsh"])
    elif mode == "gitbash":
        subprocess.Popen(["xfce4-terminal", "--working-directory", d, "--title", "Git Bash", "-e", "bash"])
    elif mode == "gitgui":
        ok = subprocess.run(["git", "-C", d, "rev-parse", "--git-dir"], capture_output=True).returncode == 0
        if ok: subprocess.Popen(["git", "-C", d, "gui"])
        else: subprocess.Popen(["zenity", "--info", "--text", "Ye folder Git repository nahi hai.\n(This folder is not a Git repository.)"])
    elif mode == "code":
        subprocess.Popen(["codium", d])
    elif mode == "admin":
        subprocess.Popen(["pkexec", "thunar", path])
    return 0
if __name__ == "__main__": sys.exit(main())
