# AdaFonts

**ver 1.0 -- 27feb19**

## Description

Ada Fonts is a minimalistic example of using truetype 
fonts in OpenGL Ada applications using Felix Krause's 
FreeTypeAda package 

It is intended to be the modern version of the "glut font" 
demos from a previous era.

It also uses Stephen Sangwine's PNG-IO package, and
thin bindings to OpenGL, SDL2.

More importantly, it shows how to encapsulate the scripts 
and runtime libraries necessary to easily compile and run 
on any computer running Windows, OS-X, or GNU/Linux.  
The only 3rd-party tool required is an Ada compiler.

## Setup & Running:
The application's root directory [~/adafonts/] contains files 
for deployment on 3 platforms:  1)OS-X, 2)linux, 3)Windows, 
in addition to all the source code.

Unzip the archive.

Open a commandline terminal, and cd to the install directory.

To initiate, type:

.) binw32\fontbtns (Windows)
.) fontbtns_osx (OSX)
.) fontbtns_gnu (linux)

=======================================================
## Build Instructions

Compiling from a commandline terminal:

.) wcmp.bat on Windows
.) ocmpss.sh on OSX
.) lcmp.sh on linux


=======================================================================
AdaFonts is covered by the GNU GPL v3 as indicated in the sources:

 Copyright (C) 2019  fastrgv@gmail.com

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You may read the full text of the GNU General Public License
 at <http://www.gnu.org/licenses/>.

