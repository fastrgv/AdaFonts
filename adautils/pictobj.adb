
--
-- Copyright (C) 2019  <fastrgv@gmail.com>
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

with system;
with gl, gl.binding, gl.pointers;
with glu, glu.binding, glu.pointers;
with glext, glext.binding, glext.pointers;

with interfaces.c;
use type interfaces.c.unsigned_short;


with ada.finalization;
with unchecked_deallocation;


	with text_io;

package body pictobj is -- for textured rectangular exterior, eg. partition wall

-- maps texture coordinates UV to cover the full extent of a side;
-- thus the whole *.png file is visible



procedure initialize( rect: in out pictangle ) is
begin
	rect.vert := new varray;
	rect.txuv := new tarray;
	rect.elem := new earray;
end initialize;

procedure vfree is new unchecked_deallocation(varray,vap);
procedure tfree is new unchecked_deallocation(tarray,tap);
procedure efree is new unchecked_deallocation(earray,eap);

procedure finalize( rect: in out pictangle ) is
begin
	vfree( rect.vert );
	tfree( rect.txuv );
	efree( rect.elem );
	--text_io.put_line("rect Free");
end finalize;





procedure setrect( rect: pictangle;
xc,yc,zc, xr,yr,zr : float ) is

xm,xp,ym,yp,zm,zp : float;

	k, ejj, j : integer := 0;
	jj : glushort;
begin

	xm  := xc-xr;
	xp  := xc+xr;
	ym  := yc-yr;
	yp  := yc+yr;
	zm  := zc-zr;
	zp  := zc+zr;

	-- front
	rect.vert(k+ 1):=xm;  rect.vert(k+ 2):=ym;  rect.vert(k+ 3):=zp;
	rect.vert(k+ 4):=xp;  rect.vert(k+ 5):=ym;  rect.vert(k+ 6):=zp;
	rect.vert(k+ 7):=xp;  rect.vert(k+ 8):=yp;  rect.vert(k+ 9):=zp;
	rect.vert(k+10):=xm;  rect.vert(k+11):=yp;  rect.vert(k+12):=zp;
	k:=k+12;

	-- back
	rect.vert(k+ 1):=xp;  rect.vert(k+ 2):=ym;  rect.vert(k+ 3):=zm;
	rect.vert(k+ 4):=xm;  rect.vert(k+ 5):=ym;  rect.vert(k+ 6):=zm;
	rect.vert(k+ 7):=xm;  rect.vert(k+ 8):=yp;  rect.vert(k+ 9):=zm;
	rect.vert(k+10):=xp;  rect.vert(k+11):=yp;  rect.vert(k+12):=zm;
	k:=k+12;


	-- top
	rect.vert(k+ 1):=xm;  rect.vert(k+ 2):=yp;  rect.vert(k+ 3):=zp;
	rect.vert(k+ 4):=xp;  rect.vert(k+ 5):=yp;  rect.vert(k+ 6):=zp;
	rect.vert(k+ 7):=xp;  rect.vert(k+ 8):=yp;  rect.vert(k+ 9):=zm;
	rect.vert(k+10):=xm;  rect.vert(k+11):=yp;  rect.vert(k+12):=zm;
	k:=k+12;

	-- bottom
	rect.vert(k+ 1):=xm;  rect.vert(k+ 2):=ym;  rect.vert(k+ 3):=zm;
	rect.vert(k+ 4):=xp;  rect.vert(k+ 5):=ym;  rect.vert(k+ 6):=zm;
	rect.vert(k+ 7):=xp;  rect.vert(k+ 8):=ym;  rect.vert(k+ 9):=zp;
	rect.vert(k+10):=xm;  rect.vert(k+11):=ym;  rect.vert(k+12):=zp;
	k:=k+12;


	-- left
	rect.vert(k+ 1):=xm;  rect.vert(k+ 2):=ym;  rect.vert(k+ 3):=zm;
	rect.vert(k+ 4):=xm;  rect.vert(k+ 5):=ym;  rect.vert(k+ 6):=zp;
	rect.vert(k+ 7):=xm;  rect.vert(k+ 8):=yp;  rect.vert(k+ 9):=zp;
	rect.vert(k+10):=xm;  rect.vert(k+11):=yp;  rect.vert(k+12):=zm;
	k:=k+12;

	-- right
	rect.vert(k+ 1):=xp;  rect.vert(k+ 2):=ym;  rect.vert(k+ 3):=zp;
	rect.vert(k+ 4):=xp;  rect.vert(k+ 5):=ym;  rect.vert(k+ 6):=zm;
	rect.vert(k+ 7):=xp;  rect.vert(k+ 8):=yp;  rect.vert(k+ 9):=zm;
	rect.vert(k+10):=xp;  rect.vert(k+11):=yp;  rect.vert(k+12):=zp;

	-- 14dec14 changed so that "nose" of image is always at the same
	--         end of object whether looking from left or right.
	--         See palm trees no longer "shift", and fish always
	--         swim with their nose leading.
	--
	-- texture UV coords for cube:
	for i in 0..5 loop
		j := i*8;

		if( (i=0) or (i=2) or (i=4) ) then
			rect.txuv(j+1):=0.0;  rect.txuv(j+2):=0.0;
			rect.txuv(j+3):=1.0;  rect.txuv(j+4):=0.0;
			rect.txuv(j+5):=1.0;  rect.txuv(j+6):=1.0;
			rect.txuv(j+7):=0.0;  rect.txuv(j+8):=1.0;
		else
			rect.txuv(j+1):=1.0;  rect.txuv(j+2):=0.0;
			rect.txuv(j+3):=0.0;  rect.txuv(j+4):=0.0;
			rect.txuv(j+5):=0.0;  rect.txuv(j+6):=1.0;
			rect.txuv(j+7):=1.0;  rect.txuv(j+8):=1.0;
		end if;
	end loop;

	-- element indices:
	for i in 0..5 loop
		jj:=glushort(i*4);
		j := i*6;
		rect.elem(j+1):=jj+0;
		rect.elem(j+2):=jj+1;
		rect.elem(j+3):=jj+2;
		rect.elem(j+4):=jj+2;
		rect.elem(j+5):=jj+3;
		rect.elem(j+6):=jj+0;
	end loop;


end setrect;



--
-- note:  the shaders for these objects must have two 
-- input "layouts", as well as whatever uniforms are needed:
--
-- layout(location=0) in vec3 vertPosName
-- layout(location=1) in vec3 vertRgbName
--
-- ...where their actual names can be whatever is convenient
--

use gl;
use glext;
use glext.binding;
use gl.binding;

procedure draw( rect: pictangle; vertbuff, uvbuff, elembuff : gluint ) is
begin

	-- 0th attribute:  vertices
	glBindBuffer(gl_array_buffer, vertbuff);
	glBufferData(gl_array_buffer, glsizeiptr(4*nvert), rect.vert(1)'address, gl_static_draw);
	glEnableVertexAttribArray(0);
	glVertexAttribPointer(0,3,gl_float,gl_false,0, system.null_address);

	-- 1st attribute:  texture UV
	glBindBuffer(gl_array_buffer, uvbuff);
	glBufferData(gl_array_buffer, glsizeiptr(4*nuv), rect.txuv(1)'address, gl_static_draw);
	glEnableVertexAttribArray(1);
	glVertexAttribPointer(1,2,gl_float,gl_false,0, system.null_address);

	-- element indices:
	glBindBuffer(gl_element_array_buffer, elembuff);
	glBufferData(gl_element_array_buffer, glsizeiptr(2*nelm), rect.elem(1)'address, gl_static_draw);

	glEnable(gl_blend);
	glBlendFunc(gl_src_alpha, gl_one_minus_src_alpha);


	glDrawElements( gl_triangles, glint(nvert), gl_unsigned_short, system.null_address );


	glDisableVertexAttribArray(0);
	glDisableVertexAttribArray(1);

end draw;






end pictobj;

