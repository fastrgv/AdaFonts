#!/bin/sh
#
# Mac OS-X compile script for GNAT2015
# ...this script should work on any recent
# standard configuration of OS-X so long as
# the 2015 GNU Ada compiler, gnatmake, is installed,
# along with Xcode and its g++ compiler.
#
# uses SDL2,SFML static libraries since they are unusual
#
# important note:
# on linux, gcc requires libstdc++ but here on OSX,
# gcc == clang++, which requires libc++


if [ -d ./obj/ ]; then
	rm ./obj/*
else
	mkdir obj
fi


###################
# use AdaCore2018:
export PATH=$HOME/opt/GNAT/2018/bin:$PATH


gnatmake $1 -O3  \
-o $1_osx \
-D $PWD/obj \
-I$PWD/adautils \
-I$PWD/adabindings/gl \
-I$PWD/adabindings/sdl208ada \
-I$PWD/adabindings/AdaPngLib \
-I$PWD/adabindings/FreeTypeAda \
-largs -lm -lz \
-lc++ \
$PWD/libs/osx/libSDL2-208x.a \
$PWD/libs/osx/libiconv.a \
$PWD/libs/osx/libfreetype.a \
$PWD/libs/osx/libpng16.a \
$PWD/libs/osx/libbz2.a \
\
-framework OpenGL \
-framework ForceFeedback \
-framework CoreFoundation \
-framework Carbon \
-framework Cocoa \
-framework QuartzCore \
-framework IOKit \
-framework CoreAudio \
-framework AudioUnit \
-framework AudioToolBox \
-pthread



# -- Copyright (C) 2015  <fastrgv@gmail.com>
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

