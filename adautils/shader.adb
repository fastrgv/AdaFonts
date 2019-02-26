
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

use gl;




with Interfaces.C;
with interfaces.c.strings;
use  type interfaces.c.unsigned;
use  type interfaces.c.int;
with text_io; use text_io;
with system; use system;

with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;


package body shader is

shader_error: exception;

function read2ustring( fpath : string ) return unbounded_string is
	tfil: file_type;
	lineoftext : string(1..160);
	linelen : natural;
	outstr : unbounded_string;
begin

	text_io.open( tfil, text_io.in_file, fpath );

	while not end_of_file(tfil) loop
		text_io.get_line(tfil, lineoftext, linelen);

		append( outstr, lineoftext(1..linelen) & ascii.lf );

	end loop;
	append( outstr, character'Val(0) );

	text_io.close( tfil );

	return outstr;

end read2ustring;



use glext;
use glext.binding;
use gl.binding;


function loadshaders(vertpath,fragpath: string) return gluint is
	pid : interfaces.c.unsigned;
	vscode, fscode : unbounded_string;
	vshaderid, fshaderid	 : aliased gluint;

	vstr : string := to_string( read2ustring(vertpath) );
	avs : system.address := vstr'address;

	fstr : string := to_string( read2ustring(fragpath) );
	afs : system.address := fstr'address;

	result : aliased glint := gl_false;
	infologlength : aliased glint := 0;
	errmsg : interfaces.c.strings.chars_ptr;
	amsg : interfaces.c.strings.char_array_access;
	bufsize : glsizei;
	tbufsize : interfaces.c.size_t;
	nulptr : gl.pointers.glsizei_pointer := null;

	error_found: boolean := false;

begin -- loadshaders

	vshaderid := glcreateshader(gl_vertex_shader);
	fshaderid := glcreateshader(gl_fragment_shader);




	glshadersource(vshaderid, 1, avs'address, system'to_address(0));
	glcompileshader(vshaderid);

	--// Check Vertex Shader
	glGetShaderiv(VShaderID, GL_COMPILE_STATUS, Result'address);
	glGetShaderiv(VShaderID, GL_INFO_LOG_LENGTH, InfoLogLength'address);
	if result=gl_false then
		new_line;
		put_line("Failure to compile VertexShader");
		if infologlength>0 then
			bufsize := glsizei(infologlength+1); -- need nul @ end
			tbufsize := interfaces.c.size_t(infologlength+1);

			amsg := new interfaces.c.char_array(1..tbufsize);

			errmsg := interfaces.c.strings.new_char_array(amsg.all);

			glgetshaderinfolog(vshaderid,bufsize,nulptr,errmsg);
			put_line( interfaces.c.strings.value(errmsg) );
			interfaces.c.strings.free(errmsg);
		end if;
		error_found:=true;
	end if;




	glshadersource(fshaderid, 1, afs'address, system'to_address(0) );
	glcompileshader(fshaderid);

	--// Check Fragment Shader
	glGetShaderiv(fShaderID, GL_COMPILE_STATUS, Result'address);
	glGetShaderiv(fShaderID, GL_INFO_LOG_LENGTH, InfoLogLength'address);
	if result=gl_false then
		new_line;
		put_line("Failure to compile FragmentShader");
		if infologlength>0 then
			bufsize := glsizei(infologlength+1); -- need nul @ end
			tbufsize := interfaces.c.size_t(infologlength+1);

			amsg := new interfaces.c.char_array(1..tbufsize);

			errmsg := interfaces.c.strings.new_char_array(amsg.all);

			glgetshaderinfolog(vshaderid,bufsize,nulptr,errmsg);
			put_line( interfaces.c.strings.value(errmsg) );
			interfaces.c.strings.free(errmsg);
		end if;
		error_found:=true;
	end if;




	pid := glcreateprogram;
	glattachshader(pid, vshaderid);
	glattachshader(pid, fshaderid);
	gllinkprogram(pid);

	--// Check Shader Program Link
	glGetProgramiv(pid, GL_link_STATUS, Result'address);
	glGetProgramiv(pid, GL_INFO_LOG_LENGTH, InfoLogLength'address);
	if result=gl_false then
		put_line("Failure to Link Shader Program");
		new_line;
		if infologlength>0 then
			bufsize := glsizei(infologlength+1); -- need nul @ end
			tbufsize := interfaces.c.size_t(infologlength+1);

			amsg := new interfaces.c.char_array(1..tbufsize);

			errmsg := interfaces.c.strings.new_char_array(amsg.all);

			glgetprograminfolog(pid,bufsize,nulptr,errmsg);
			put_line( interfaces.c.strings.value(errmsg) );
			interfaces.c.strings.free(errmsg);
		end if;
		--raise shader_error;
		error_found:=true;
	end if;




	gldeleteshader(vshaderid);
	gldeleteshader(fshaderid);

	if error_found then
		--raise shader_error;
		null;
	end if;

	return pid;

end loadshaders;


end shader;

