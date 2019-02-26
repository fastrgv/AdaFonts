
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

with gl, gl.binding, gl.pointers;
with glu, glu.binding, glu.pointers;
with glext, glext.binding, glext.pointers;



with System;
with Interfaces.C;
use  type interfaces.c.unsigned;
with Interfaces.C.Pointers;
with interfaces.c.strings;

with text_io; use text_io;


with PNG_IO;

use gl;

with unchecked_deallocation;



package body pngloader is

	pngloader_assert_error : exception;

procedure myassert( condition : boolean ) is
begin
  if condition=false then
  		text_io.put_line("PngLoader: Assertion Failed!");
  		raise pngloader_assert_error;
  end if;
end myassert;




-- always uses RGBA-mode for textures:
function loadCubePng( f1,f2,f3,f4,f5,f6 : string ) return gluint is

use interfaces.c;
use interfaces.c.strings;
use glext.binding;
use gl.binding;

	package myint_io is new text_io.integer_io(integer);

	mychar : char;

	afil : file_type;
	ui : integer := 0;

	cmtexid : gluint;
	kount : interfaces.c.size_t := 0;

	F : png_io.PNG_File;

	crow, ccol : png_io.coordinate;

	chkxwidth, chkheight : interfaces.c.size_t;

	loadCube_error : exception;

begin

	binding.glgentextures(1, cmtexid'address);

	--binding.glactivetexture(gl_texture0); -- ??? is this needed ???

	binding.glbindtexture(gl_texture_cube_map, cmtexid);



  png_io.Open(F, f1);

  declare
   W : constant png_io.Dimension        := png_io.Width(F);
   H : constant png_io.Dimension        := png_io.Height(F);
	xwidth : constant interfaces.c.size_t := interfaces.c.size_t(W);
	xheight : constant interfaces.c.size_t := interfaces.c.size_t(H);

   T : constant png_io.Colour_Type_Code := png_io.Colour_Type(F);
	hasAlfa : constant boolean := png_io.ALPHA(T);

	bpp : constant interfaces.c.size_t := 4;
	maxK : constant interfaces.c.size_t := xheight*xwidth*bpp;

	subtype myrange is interfaces.c.size_t range 1..maxK;
	subtype atype is  char_array(myrange);
	type atype6 is  array(1..6) of atype;
	type a6p is access atype6;
	myuptr : a6p;

	procedure dispose is new unchecked_deallocation	(atype6,a6p);

  begin --declare


	myuptr := new atype6;

	myassert( xwidth = xheight );

   png_io.Close(F);


	for i in 1..6 loop

	case i is
		when 1 => png_io.Open( F, f1 );
		when 2 => png_io.Open( F, f2 );
		when 3 => png_io.Open( F, f3 );
		when 4 => png_io.Open( F, f4 );
		when 5 => png_io.Open( F, f5 );
		when 6 => png_io.Open( F, f6 );
		when others =>
			text_io.put_line("PngLoader.LoadCubePng: error Opening 6 png files!");
			raise loadcube_error;
	end case;

	chkxwidth := interfaces.c.size_t(  png_io.Width(F) );
	chkheight := interfaces.c.size_t( png_io.Height(F) );

	myassert( chkxwidth = xwidth );
	myassert( chkheight = xheight );


	kount := 0;

	for row in 0..xheight-1 loop
	crow := png_io.coordinate(row);

	for col in 0..xwidth-1 loop
	ccol := png_io.coordinate(col);

	   --red
		ui := png_io.Red_Value(F, crow,ccol );
		mychar := to_c( character'val(ui) );
		kount := kount+1;
		myuptr(i)(kount):=mychar;

	   --grn
		ui := png_io.Green_Value(F, crow, ccol );
		mychar := to_c( character'val(ui) );
		kount := kount+1;
		myuptr(i)(kount):=mychar;

	   --blu
		ui := png_io.Blue_Value(F, crow, ccol );
		mychar := to_c( character'val(ui) );
		kount := kount+1;
		myuptr(i)(kount):=mychar;

	   --alfa
	if hasAlfa then
		ui := png_io.Alpha_Value(F, crow, ccol );
		mychar := to_c( character'val(ui) );
		kount := kount+1;
		myuptr(i)(kount):=mychar;
	else
		--workaround necessary because some RGB mode pics do not display properly:
		mychar := to_c( character'val(255) ); --stuff a value of opacity=1.0
		kount := kount+1;
		myuptr(i)(kount):=mychar;
	end if;

	end loop; -- for col
	end loop; -- for row

	png_io.Close(F);



	binding.glteximage2d( 
 		gl_texture_cube_map_positive_x + interfaces.c.unsigned(i-1), 0,
		gl_rgba, interfaces.c.int(xwidth), interfaces.c.int(xheight), 0,	
		gl_rgba, gl_unsigned_byte, myuptr(i)'address);


	end loop; -- for i



	gltexparameteri(gl_texture_cube_map, gl_texture_wrap_s, gl_clamp_to_edge);
	gltexparameteri(gl_texture_cube_map, gl_texture_wrap_t, gl_clamp_to_edge);
	gltexparameteri(gl_texture_cube_map, gl_texture_wrap_r, gl_clamp_to_edge);

	gltexparameteri(gl_texture_cube_map, gl_texture_mag_filter, gl_linear);
	--gltexparameteri(gl_texture_cube_map, gl_texture_min_filter, gl_linear);
	gltexparameteri(gl_texture_cube_map, gl_texture_min_filter, gl_linear_mipmap_nearest);
	glgeneratemipmap(gl_texture_cube_map);

	dispose(myuptr);

  end; --declare

--minimal error test
if gl_no_error /= glGetError then
	--raise loadCube_error;
	put_line(" GLerror in pngLoader.LoadCubePng");
end if;

  return cmtexid;

end loadCubePng;







procedure pngType( 
	F : png_io.PNG_File; 
	wid,hit: out gl.glint; 
	hasAlfa: out boolean;
	debug : in boolean := false
	) is

	il: constant boolean := png_io.Interlaced(F);
	bd: constant png_io.Depth := png_io.Bit_Depth(F);
	ct: constant png_io.Colour_Type_Code := png_io.Colour_Type(F);
	std: constant boolean := png_io.Standard_RGB(F);
	hp: constant boolean := png_io.Palette(F);

   W : constant png_io.Dimension        := png_io.Width(F);
   H : constant png_io.Dimension        := png_io.Height(F);
	xwidth : constant interfaces.c.size_t := interfaces.c.size_t(W);
	xheight : constant interfaces.c.size_t := interfaces.c.size_t(H);
   T : constant png_io.Colour_Type_Code := png_io.Colour_Type(F);

begin

	hasAlfa := png_io.ALPHA(T);

	wid := gl.glint(W);
	hit := gl.glint(H);

  if debug then
  	put_line("loadpng: size: "&glint'image(wid)&"x"&glint'image(hit));
  	put_line("loadpng: hasAlfa: "&boolean'image(hasAlfa));

	put_line("loadpng: interlace: "&boolean'image(il));
	put_line("loadpng: bitdepth: "&png_io.Depth'image(bd));
	put_line("loadpng: coltype: "&png_io.Colour_Type_Code'image(ct));
	put_line("loadpng: StdRgb: "&boolean'image(std));
	put_line("loadpng: HasPalette: "&boolean'image(hp));

	new_line;
  end if;

end pngType;




-- always uses RGBA-mode for textures:
--type wraptype is (mirror, clamp, repeat);
function loadpng( 
	wrap: wraptype; 
	pngfilename: string; 
	wid,hit: out gl.glint;
	debug : in boolean := false
	) return gluint is

use interfaces.c;
use interfaces.c.strings;
use glext.binding;
use gl.binding;

	package myint_io is new text_io.integer_io(integer);

	mychar : char;
	afil : file_type;
	ui : integer := 0;
	textureid : gluint;
	kount : interfaces.c.size_t := 0;
	F : png_io.PNG_File;
	crow, ccol : png_io.coordinate;
	hasAlfa : boolean;

	loadpng1_error: exception;

begin

  if debug then
	new_line;
  	put_line("loadpng: file: "&pngfilename);
  	put_line("loadpng: wrap: "&wraptype'image(wrap));
  end if;

  png_io.Open(F, pngfilename);
  pngType(F,wid,hit,hasAlfa,debug);


  declare

	bpp : constant gl.glint := 4;
	maxK : constant interfaces.c.size_t := interfaces.c.size_t(hit*wid*bpp);

	subtype myrange is interfaces.c.size_t range 1..maxK;
	subtype atype is char_array(myrange);
	type axp is access atype;
	myuptr : axp;

	procedure dispose is new unchecked_deallocation	(atype,axp);


  begin -- declare


	myuptr := new atype;


	for row in 0..hit-1 loop
	crow := png_io.coordinate(row);
	for col in 0..wid-1 loop
	ccol := png_io.coordinate(col);
	   --red
		ui := png_io.Red_Value(F, crow,ccol );
		mychar := to_c( character'val(ui) );
		kount := kount+1;
		myuptr(kount):=mychar;
	   --grn
		ui := png_io.Green_Value(F, crow, ccol );
		mychar := to_c( character'val(ui) );
		kount := kount+1;
		myuptr(kount):=mychar;
	   --blu
		ui := png_io.Blue_Value(F, crow, ccol );
		mychar := to_c( character'val(ui) );
		kount := kount+1;
		myuptr(kount):=mychar;

	   --alfa
	if hasAlfa then
		ui := png_io.Alpha_Value(F, crow, ccol );
		mychar := to_c( character'val(ui) );
		kount := kount+1;
		myuptr(kount):=mychar;
	else
		--workaround necessary because some RGB mode pics do not display properly:
		mychar := to_c( character'val(255) ); --stuff a value of opacity=1.0
		kount := kount+1;
		myuptr(kount):=mychar;
	end if;

	end loop;
	end loop;


	png_io.Close(F);


	binding.glgentextures(1, textureid'address);
	binding.glbindtexture(gl_texture_2d, textureid);

	binding.glteximage2d( 
 		gl_texture_2d, 0,  -- target, level
		gl_rgba, wid,hit,0, -- inpfmt, hsiz, vsiz, border
		gl_rgba, gl_unsigned_byte, --outfmt, type
		myuptr(1)'address);  -- data

	if wrap=repeat then
		-- closest match to loadpng.cpp
		gltexparameteri(gl_texture_2d, gl_texture_wrap_s, gl_repeat);
		gltexparameteri(gl_texture_2d, gl_texture_wrap_t, gl_repeat);
		gltexparameteri(gl_texture_2d, gl_texture_mag_filter, gl_linear);
		gltexparameteri(gl_texture_2d, gl_texture_min_filter, gl_linear_mipmap_nearest);
		glgeneratemipmap(gl_texture_2d);
	elsif wrap=mirror then
		gltexparameteri(gl_texture_2d, gl_texture_wrap_s, gl_mirrored_repeat);
		gltexparameteri(gl_texture_2d, gl_texture_wrap_t, gl_mirrored_repeat);
		gltexparameteri(gl_texture_2d, gl_texture_mag_filter, gl_linear);
		gltexparameteri(gl_texture_2d, gl_texture_min_filter, gl_linear_mipmap_nearest);
		glgeneratemipmap(gl_texture_2d);
	elsif wrap=clamp then
		gltexparameteri(gl_texture_2d, gl_texture_wrap_s, gl_clamp_to_edge);
		gltexparameteri(gl_texture_2d, gl_texture_wrap_t, gl_clamp_to_edge);
		gltexparameteri(gl_texture_2d, gl_texture_mag_filter, gl_linear);
		gltexparameteri(gl_texture_2d, gl_texture_min_filter, gl_linear_mipmap_nearest);
		glgeneratemipmap(gl_texture_2d);
	end if;

	dispose(myuptr);

  end; --declare


--minimal error test
if gl_no_error /= glGetError then
	--raise loadpng1_error;
	put_line(" GLerror in pngLoader.LoadPng-A");
end if;


  return textureid;

end loadpng;







-- always uses RGBA-mode for textures:
--type wraptype is (mirror, clamp, repeat);
function loadpng( wrap: wraptype; pngfilename: string ) return gluint is

use interfaces.c;
use interfaces.c.strings;
use glext.binding;
use gl.binding;

	package myint_io is new text_io.integer_io(integer);

	mychar : char;
	afil : file_type;
	ui : integer := 0;
	textureid : gluint;
	kount : interfaces.c.size_t := 0;
	F : png_io.PNG_File;
	crow, ccol : png_io.coordinate;
	hasAlfa : boolean;
	wid,hit : gl.glint;

	loadpng2_error: exception;

begin

  png_io.Open(F, pngfilename);
  pngType(F,wid,hit,hasAlfa);

  declare

	bpp : constant gl.glint := 4;
	maxK : constant interfaces.c.size_t := interfaces.c.size_t(hit*wid*bpp);

	subtype myrange is interfaces.c.size_t range 1..maxK;
	subtype atype is  char_array(myrange);
	type axp is access atype;
	myuptr : axp;

	procedure dispose is new unchecked_deallocation	(atype,axp);


  begin -- declare


	myuptr := new atype;


	for row in 0..hit-1 loop
	crow := png_io.coordinate(row);

	for col in 0..wid-1 loop
	ccol := png_io.coordinate(col);

	   --red
		ui := png_io.Red_Value(F, crow,ccol );
		mychar := to_c( character'val(ui) );
		kount := kount+1;
		myuptr(kount):=mychar;

	   --grn
		ui := png_io.Green_Value(F, crow, ccol );
		mychar := to_c( character'val(ui) );
		kount := kount+1;
		myuptr(kount):=mychar;

	   --blu
		ui := png_io.Blue_Value(F, crow, ccol );
		mychar := to_c( character'val(ui) );
		kount := kount+1;
		myuptr(kount):=mychar;

	   --alfa
	if hasAlfa then -- rgba mode
		ui := png_io.Alpha_Value(F, crow, ccol );
		mychar := to_c( character'val(ui) );
		kount := kount+1;
		myuptr(kount):=mychar;
	else
		--workaround necessary because some RGB mode pics do not display properly:
		mychar := to_c( character'val(255) ); --stuff a value of opacity=1.0
		kount := kount+1;
		myuptr(kount):=mychar;
	end if;


	end loop; -- col
	end loop; -- row

	png_io.Close(F);


	binding.glgentextures(1, textureid'address);
	binding.glbindtexture(gl_texture_2d, textureid);


	binding.glteximage2d( 
 		gl_texture_2d, 0, 
		gl_rgba, wid,hit,0,
		gl_rgba, gl_unsigned_byte, myuptr(1)'address);


	if wrap=repeat then
		-- closest match to loadpng.cpp
		gltexparameteri(gl_texture_2d, gl_texture_wrap_s, gl_repeat);
		gltexparameteri(gl_texture_2d, gl_texture_wrap_t, gl_repeat);
		gltexparameteri(gl_texture_2d, gl_texture_mag_filter, gl_linear);
		gltexparameteri(gl_texture_2d, gl_texture_min_filter, gl_linear_mipmap_nearest);
		glgeneratemipmap(gl_texture_2d);
	elsif wrap=mirror then
		gltexparameteri(gl_texture_2d, gl_texture_wrap_s, gl_mirrored_repeat);
		gltexparameteri(gl_texture_2d, gl_texture_wrap_t, gl_mirrored_repeat);
		gltexparameteri(gl_texture_2d, gl_texture_mag_filter, gl_linear);
		gltexparameteri(gl_texture_2d, gl_texture_min_filter, gl_linear_mipmap_nearest);
		glgeneratemipmap(gl_texture_2d);
	elsif wrap=clamp then
		gltexparameteri(gl_texture_2d, gl_texture_wrap_s, gl_clamp_to_edge);
		gltexparameteri(gl_texture_2d, gl_texture_wrap_t, gl_clamp_to_edge);
		gltexparameteri(gl_texture_2d, gl_texture_mag_filter, gl_linear);
		gltexparameteri(gl_texture_2d, gl_texture_min_filter, gl_linear_mipmap_nearest);
		glgeneratemipmap(gl_texture_2d);
	end if;

	dispose(myuptr);

  end; --declare

--minimal error test
if gl_no_error /= glGetError then
	--raise loadpng2_error;
	put_line(" GLerror in pngLoader.LoadPng-B");
end if;

  return textureid;

end loadpng;












end pngloader;
