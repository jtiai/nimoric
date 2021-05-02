version     = "0.1"
author      = "Jani Tiainen"
description = "Oric Emulator"
license     = "BSD-3"

srcDir      = "src"
bin         = @["nimoric"]
skipExt     = @["nim"]

requires "nim >= 1.4.4"
requires "https://github.com/nimgl/imgui.git"
requires "with"
requires "fusion"
requires "sdl2_nim"
