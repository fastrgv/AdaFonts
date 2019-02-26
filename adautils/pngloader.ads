
--
-- Copyright (C) 2017  <fastrgv@gmail.com>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You may read the full text of the GNU General Public License
-- at <http://www.gnu.org/licenses/>.
--

with gl;


package pngloader is


type wraptype is (mirror, clamp, repeat);

-- always uses RGBA-mode:
function loadpng( wrap: wraptype; pngfilename: string ) return gl.gluint;

-- always uses RGBA-mode:
function loadpng( 
	wrap: wraptype; 
	pngfilename: string; 
	wid,hit: out gl.glint;
	debug : in boolean := false
	) return gl.gluint;


-- always uses RGBA-mode:
function loadCubePng( f1,f2,f3,f4,f5,f6 : string ) return gl.gluint;

end pngloader;
