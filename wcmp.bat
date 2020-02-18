
rem -- Copyright (C) 2018  <fastrgv@gmail.com>
rem --
rem -- This program is free software: you can redistribute it and/or modify
rem -- it under the terms of the GNU General Public License as published by
rem -- the Free Software Foundation, either version 3 of the License, or
rem -- (at your option) any later version.
rem --
rem -- This program is distributed in the hope that it will be useful,
rem -- but WITHOUT ANY WARRANTY; without even the implied warranty of
rem -- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
rem -- GNU General Public License for more details.
rem --
rem -- You may read the full text of the GNU General Public License
rem -- at <http://www.gnu.org/licenses/>.


c:\gnat\2017\bin\gnatmake.exe %1 ^
 -O3 -gnat12 ^
 -D obj ^
 -Iadautils ^
 -Iadabindings\gl ^
 -Iadabindings\sdl208ada ^
 -Iadabindings\AdaPngLib ^
 -Iadabindings\FreeTypeAda ^
 -largs -lstdc++ ^
 -lOpenGL32 -lGdi32 -lwinmm ^
	-Llibs\w32ming\sdl208 ^
	-lSDL2 ^
	-Llibs\w32ming ^
	-lglext -lfreetype.dll ^
	-lz


move %1.exe .\binw32\

