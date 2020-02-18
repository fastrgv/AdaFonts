# compile script for seven
# using shared libs only
#
# uses rpath to tell runtime linker to look also in
# ./libs/ for any needed *.so files not found elsewhere
#
# either elliminate this next line or
# make it match your configuration
# so that "gnatmake" can be found:


# this is newest compiler 2018 from AdaCore:
export PATH=$HOME/opt/GNAT/2018/bin:$PATH



gnatmake $1 \
-o $1_gnu \
-O3 -gnat12 \
-D obj \
-Iadautils \
-Iadabindings/gl \
-Iadabindings/sdl208ada \
-Iadabindings/AdaPngLib \
-Iadabindings/sfmlAudio \
-Iadabindings/FreeTypeAda \
-largs \
-lGL -lstdc++ \
-Wl,-rpath,'$ORIGIN/libs/gnu' \
-L$PWD/libs/gnu \
-lz -lm -lfreetype -lSDL2

#NOTE:  final line above has libs that need not be explicitly
#       mentioned, yet are used and may be non-standard




# -- Copyright (C) 2018  <fastrgv@gmail.com>
# --
# -- This program is free software: you can redistribute it and/or modify
# -- it under the terms of the GNU General Public License as published by
# -- the Free Software Foundation, either version 3 of the License, or
# -- (at your option) any later version.
# --
# -- This program is distributed in the hope that it will be useful,
# -- but WITHOUT ANY WARRANTY; without even the implied warranty of
# -- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# -- GNU General Public License for more details.
# --
# -- You may read the full text of the GNU General Public License
# -- at <http://www.gnu.org/licenses/>.

