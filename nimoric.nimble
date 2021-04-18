version     = "0.1"
author      = "Jani Tiainen"
description = "Oric Emulator"
license     = "BSD-3"

srcDir      = "src"
bin         = @["nimoric"]
skipExt     = @["nim"]

requires "nim >= 1.4.4"
requires "https://github.com/nimgl/imgui.git"
requires "nimgl"
requires "with"

task rom, "Compile ROM":
  withDir "src":
    exec "dasm rom.asm -f3 -lmikro.lst -smikro.sym -omikro.rom"

task test, "Run the tests!":
  withDir "tests":
    exec "nim c -r opcodes"
