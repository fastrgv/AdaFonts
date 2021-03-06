
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

---------------------------------------------------------------------------


with gl, gl.binding, gl.pointers;
with glu, glu.binding, glu.pointers;
with glext, glext.binding, glext.pointers;

with sdl;  use sdl;

with matutils;
with stex;

with shader;  use shader;
with pictobj;
with pngloader;

---------------------------------------------------------------------------

with ada.calendar;
with ada.characters.handling;
with ada.strings.fixed;

with System;
with Interfaces.C;
use  type interfaces.c.unsigned;
with Interfaces.C.Pointers;
with interfaces.c.strings;

with unchecked_deallocation;
with ada.unchecked_conversion;
with Ada.Command_Line;
with Ada.Strings.Unbounded;
with Ada.Strings.Unbounded.Text_IO;

with ada.strings.fixed;

with ada.numerics.generic_elementary_functions;

with text_io;






procedure fonttf is


	use Ada.Strings.Unbounded;
	use Ada.Strings.Unbounded.Text_IO;

	use text_io;
	use pngloader;
	use matutils;

	use interfaces.c;
	use interfaces.c.strings;
	use glext;
	use glext.pointers;
	use glext.binding;
	use gl;
	use gl.binding;
	use gl.pointers;



	procedure myassert( 
		condition : boolean;  
		flag: integer:=0;
		msg: string := ""
		) is
	begin
	  if condition=false then
			put("ASSERTION Failed!  ");
			if flag /= 0 then
				put( "@ " & integer'image(flag) &" : " );
			end if;
			put_line(msg);
			new_line;
			raise program_error;
	  end if;
	end myassert;




------------------ begin los calculator specific data

	b1push, b2push, b3push : boolean := false;





	type vec3 is array(1..3) of float;


	mainWindow : access SDL_Window;
	mainGLContext : SDL_GLContext;

	contextFlags : sdl_windowflags;

	Nwid,Nhit,Mwid,Mhit,Wwid,Whit,  Fwid, Fhit : aliased interfaces.c.int;

	numkeys : aliased glint;


	--subtype keyindex is interfaces.c.int range 0..511;
	--type keyarraytype is array(keyindex) of Uint8;
	key_map : access sdl.keyarraytype;



	pmvp : chars_ptr := new_string("MVP"&ascii.nul);
	pmyts : chars_ptr := new_string("myTextureSampler"&ascii.nul);


	vertbuff, uvbuff, elembuff, rgbbuff, vertexarrayid : gluint;

	matrixid, uniftex : glint;

	picttexshadid,
	btnup_texid, btndn_texid, 
	floor_texid : gluint := 0;

	-- virtual screen:  (x,z) in [-1,+1]
	-- Button locations
	-- (x,?,z) have origin @ center...
	-- increasing rightward, downward

	bdx: constant float := 0.05; --0.1;
	bdz: constant float := 0.05;


	b1x: constant float := -0.92;
	b1z: constant float := -0.68;

	b2x: constant float := -0.92;
	b2z: constant float := -0.48;

	b3x: constant float := -0.92;
	b3z: constant float := -0.18;


	opict: pictobj.pictangle;


	package fmath is new
			Ada.Numerics.generic_elementary_functions( float );
	use fmath;

	package myint_io is new text_io.integer_io(integer);



	onepi : constant float     := 3.14159_26535_89793;
	halfpi : constant float    := onepi/2.0;
	fourthpi : constant float  := onepi/4.0;
	twopi : constant float     := onepi*2.0;
	deg2rad : constant float   := onepi/180.0;
	rad2deg : constant float   := 180.0/onepi;


	userexit, help : boolean := false;




procedure InitSDL( width, height : glint;  flags:Uint32;  name: string ) is

	profile, compflag,
	major, minor,
	error, cver : interfaces.c.int;
	bresult : SDL_bool;

	compiled, linked : aliased SDL_version;

	pms : char_array := To_C("GL_ARB_multisample");
	psampl : aliased glint;

begin

	-- Careful!  Only initialize what we use (otherwise exe won't run):
	error := SDL_Init(SDL_INIT_TIMER or SDL_INIT_EVENTS or SDL_INIT_VIDEO);

---------- begin 14feb15 insert -----------------------------------------
	SDL_SOURCEVERSION( compiled'access );
	put_line("We compiled against SDL version "
		&Uint8'image(compiled.major)&"."
		&Uint8'image(compiled.minor)&"."
		&Uint8'image(compiled.patch) );
	cver := SDL_COMPILEDVERSION;  
	put_line("SDL_compiledversion="&glint'image(cver));
	SDL_GetVersion( linked'access );
	put_line("We linked against SDL version "
		&Uint8'image(linked.major)&"."
		&Uint8'image(linked.minor)&"."
		&Uint8'image(linked.patch) );
---------- end 14feb15 insert ----------------------------------------

	bresult := SDL_SetHint( SDL_HINT_RENDER_VSYNC, "1" );
	myassert( bresult = SDL_TRUE ,1002 );
	bresult := SDL_SetHint( SDL_HINT_RENDER_SCALE_QUALITY, "1" );
	myassert( bresult = SDL_TRUE ,1003 );




	--// Turn on double buffering.
	error := SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
	myassert( error = 0 ,1004 );
	error := SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
	myassert( error = 0 ,1005 );
	error := SDL_GL_SetAttribute(SDL_GL_ALPHA_SIZE, 8);
	myassert( error = 0 );





	error := SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
	myassert( error = 0 ,1006 );
	error := SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
	myassert( error = 0 ,1007 );




	error := SDL_GL_SetAttribute( SDL_GL_CONTEXT_PROFILE_MASK, 
											SDL_GL_CONTEXT_PROFILE_CORE );
	myassert( error = 0 ,1008 );

	-- Note that OSX currently requires the forward_compatible flag!
	error := SDL_GL_SetAttribute( SDL_GL_CONTEXT_FLAGS, 
											SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG );
	myassert( error = 0 ,1009 );



	mainWindow := SDL_CreateWindow( To_C(name,true) , 
			SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 
			width, height, flags);


	mainGLContext := SDL_GL_CreateContext(mainWindow);

	error := SDL_GL_MakeCurrent( mainWindow, mainGLContext );
	myassert( error = 0 ,1010 );



-- This next section is ugly...
---------------------------------------------------------------------
	--this FTN must be called AFTER context is created and made current:
	if SDL_TRUE = sdl_gl_extensionsupported(pms) then

		-- If we get here, multisamples are supported...
		-- so reduce aliasing by enabling multisamples:

		put_line("MultSample is supported");
		error := SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4);
		myassert( error = 0 ,1011 );

		SDL_GL_DeleteContext(mainGLContext);
		SDL_DestroyWindow(mainWindow);

		mainWindow := SDL_CreateWindow( To_C(name,true) , 
				SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 
				width, height, flags);

		mainGLContext := SDL_GL_CreateContext(mainWindow);

		error := SDL_GL_MakeCurrent( mainWindow, mainGLContext );
		myassert( error = 0 ,1012 );

---------------------------------------------------------------------
		error := SDL_GL_GetAttribute(SDL_GL_MULTISAMPLESAMPLES,psampl'access);
		myassert( error = 0 ,1013 );
		put_line("psampl="&glint'image(psampl));   -- 4
---------------------------------------------------------------------

	else
		put_line("MultSample is NOT supported");
	end if;


	glgetintegerv(gl_major_version, major'address);
	glgetintegerv(gl_minor_version, minor'address);
	put_line("ogl-version-query:"&glint'image(major)&":"&glint'image(minor));


	glGetIntegerv(GL_CONTEXT_PROFILE_MASK, profile'address);
	if( profile = GL_CONTEXT_CORE_PROFILE_BIT ) then
		put_line("ogl-query:  Core Profile");
	end if;


	-- OSX currently requires the forward_compatible flag!
	glGetIntegerv(GL_CONTEXT_FLAGS, compflag'address);
	if( compflag = GL_CONTEXT_FLAG_FORWARD_COMPATIBLE_BIT ) then
		put_line("ogl-query:  Forward-Compatible bit is set");
	end if;


end InitSDL;










MVP, ModelMatrix, ViewMatrix, ProjectionMatrix
	 : mat44 := identity;


procedure updateMVP is -- only call once unless change in aspect ratio

	xlook, ylook, zlook, xlk,ylk,zlk, xrt,yrt,zrt, xup,yup,zup : float;
	xme,yme,zme : float;

	fovdeg : constant float := 45.0;
	fovrad : constant float := fovdeg*deg2rad;


	-- distance from eye so FOV encompasses proper field:
	eyeradius : constant float := 1.0 / fmath.tan(fovrad/2.0);

	horiAng : constant float := onepi; --0.0;
	near : constant float := 0.1;
	far  : constant float := 100.0;

	focus : constant vec3 := (0.0, -1.0, 0.0);
	eyepos: constant vec3 := (0.0, eyeradius-1.0 , 0.0);
	look  : constant vec3 := 
		( focus(1)-eyepos(1), focus(2)-eyepos(2), focus(3)-eyepos(3) );
	vertAng : constant float := fmath.arctan( look(2), look(3) );

begin

	ModelMatrix:=identity;

	xme:=eyepos(1);
	yme:=eyepos(2);
	zme:=eyepos(3);

	-- look direction:
	xlook := fmath.cos(vertang)*fmath.sin(horiang);
	ylook := fmath.sin(vertang);
	zlook := fmath.cos(vertang)*fmath.cos(horiang);

	xlk := xme+xlook;
	ylk := yme+ylook;
	zlk := zme+zlook;

	-- Right unit-Direction
	xrt:= fmath.sin(horiang-halfpi);
	yrt:= 0.0;
	zrt:= fmath.cos(horiang-halfpi);

	-- calculate UP unit-Direction
	cross( xrt,yrt,zrt, xlook,ylook,zlook, xup,yup,zup );

	perspective(ProjectionMatrix, fovdeg, 1.0,  near, far);

	lookat(ViewMatrix, xme,yme,zme, xlk,ylk,zlk, xup,yup,zup );

	MVP:=ModelMatrix;
	matXmat(MVP,ViewMatrix);
	matXmat(MVP,ProjectionMatrix);

end updateMVP;





procedure release_textures is -- prepare to close down
begin

	glext.binding.glDeleteBuffers(1, vertbuff'address);
	glext.binding.glDeleteBuffers(1, rgbbuff'address);
	glext.binding.glDeleteBuffers(1, uvbuff'address);
	glext.binding.glDeleteBuffers(1, elembuff'address);

	gldeletetextures(1, floor_texid'address);
	gldeletetextures(1, btnup_texid'address);
	gldeletetextures(1, btndn_texid'address);

	glext.binding.glDeleteProgram( picttexshadid );

	glext.binding.glDeleteVertexArrays(1, vertexarrayid'address);

end release_textures;



procedure setup_textures is  -- prepare dungeon textures
begin 

	glgenvertexarrays(1, vertexarrayid'address );
	glbindvertexarray(vertexarrayid);
	glactivetexture(gl_texture0);
	glgenbuffers(1, vertbuff'address);
	glgenbuffers(1, rgbbuff'address);
	glgenbuffers(1, uvbuff'address);
	glgenbuffers(1, elembuff'address);


	picttexshadid := loadshaders("./data/texobj.vs", "./data/texobj.fs");
	matrixid := glgetuniformlocation(picttexshadid, pmvp);
	uniftex  := glgetuniformlocation(picttexshadid, pmyts);

	--floor_texid:= loadPng(mirror,"data/white.png");
	floor_texid:= loadPng(mirror,"data/politicalWorldB.png");
	btnup_texid:= loadPng(mirror,"data/btnDn.png");
	btndn_texid:= loadPng(mirror,"data/btnUp.png");


end setup_textures;









procedure first_prep is -- main program setup
      FileId : text_io.File_Type;
		ret : glint;
		current: aliased SDL_DisplayMode;

begin

------- begin SDL prep ---------------------------------------------------

	ret := SDL_Init(SDL_INIT_VIDEO or SDL_INIT_EVENTS or SDL_INIT_TIMER);

	for i in 1..SDL_GetNumVideoDisplays loop
		ret := SDL_GetCurrentDisplayMode(i-1, current'access);
		if ret /= 0 then
			put_line("Could not get display mode");
		end if;
	end loop;
	Mwid := current.w;
	Mhit := current.h;

	contextFlags := 
		SDL_WINDOW_SHOWN 
		or SDL_WINDOW_OPENGL
		or SDL_WINDOW_RESIZABLE
		or SDL_WINDOW_ALLOW_HIGHDPI;

	Wwid:=960;
	Whit:=700;


	InitSDL(Wwid, Whit, contextFlags, "font-ttf    <h>=help  <esc>=quit");


	-- prepare font -------------
	stex.InitFont ( "data/AnonymousPro-Regular.ttf" );
	stex.setColor( (1.0, 1.0, 1.0, 1.0) ); --white
	--stex.setColor( (0.5, 0.5, 0.5, 1.0) ); --gray
	--stex.setColor( (0.0, 0.0, 0.0, 1.0) ); --black
	stex.setTextWindowSize(Wwid,Whit);




	put_line( "Window: wid-X-hit :" 
		& interfaces.c.int'image(Wwid)&" X "
		& interfaces.c.int'image(Whit) );


	SDL_GL_GetDrawableSize( mainWindow, Fwid'access, Fhit'access );
	glViewport(0,0,Fwid,Fhit);

	put_line( "Drawable: Fwid-X-Fhit : "
		&interfaces.c.int'image(Fwid)&" X "
		& interfaces.c.int'image(Fhit) );

	key_map := sdl_getkeyboardstate(numkeys'access);
	--put_line("...numkeys=" & interfaces.c.int'image(numkeys) ); -- 512
	--myassert( sdl.keyrange'last <= numkeys );


	setup_textures;

	glClearColor(0.4,0.4,0.4,1.0);

	glenable(gl_depth_test);
	gldepthfunc( gl_lequal );
	glenable( gl_cull_face );

	glEnable(GL_MULTISAMPLE);
	glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
	glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);

end first_prep;








procedure Draw is

	dh: constant float := 0.077; --horizontal offset btn
	szhelp: constant float := 0.5;
	szbtn: constant float := 0.2;


	l1x: constant float :=0.5*(b1x+1.0);
	l1z: constant float :=1.0-0.5*(b1z+1.0)+0.05;

	l3x: constant float :=0.5*(b3x+1.0);
	l3z: constant float :=1.0-0.5*(b3z+1.0)+0.05;



	procedure putBtn( 
		x,z : float; 
		push: boolean; 
		wide: boolean := false ) is
		dx: float:= bdx;
	begin
		if wide then dx:=2.0*bdx; end if;
		pictobj.setrect(opict, 
			   x, -1.0,      z,
			  dx,  0.0001, bdz );
		if push then
			glBindTexture(GL_TEXTURE_2D, btndn_texid);
		else
			glBindTexture(GL_TEXTURE_2D, btnup_texid);
		end if;
		pictobj.draw(opict, vertbuff, uvbuff, elembuff);
	end putBtn;



	hpos: constant float := 0.3;
	vpos: float := 0.7;
	procedure incline(s: string;  sz: float; md: integer:=0) is
		dv: constant float := 0.05; --reasonable vertical spacing
	begin
		stex.print2d(s, hpos, vpos, sz,md);
		vpos:=vpos-dv;
	end incline;



begin


	glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

	glUseProgram(pictTexShadID);
	glUniformMatrix4fv(MatrixID, 1, GL_FALSE, MVP(1,1)'address);
	glUniform1i(uniftex,0);


	pictobj.setrect(opict, 
		0.0, -1.0,    0.0,
		1.0,  0.0001, 1.0 );
	glBindTexture(GL_TEXTURE_2D, floor_texid);
	pictobj.draw(opict, vertbuff, uvbuff, elembuff);

	if help  then -- display only help messages:

		incline("font-ttf Help",szhelp); 
		incline(" <esc> => quit",szhelp); 
		incline("  <h>  => toggles this screen",szhelp);
		incline("font: AnonymousPro-Regular.ttf",szhelp);
		incline("abcdefg",szhelp);
		incline("ABCDEFG",szhelp);
		incline("abcdefg",szhelp);


	else -- display normal table dialog

		-- (x,?,z) have origin @ center...
		-- increasing rightward, downward

		putBtn(b1x,b1z,b1push);
		putBtn(b2x,b2z,b2push);
		putBtn(b3x,b3z,b3push);

------------------- text output ------------------------------------
-- all text comes after other drawings -----------------------------
--------------------------------------------------------------------

		--btn labels AFTER all btns
		stex.print2d("radio", l1x, l1z, szbtn);
		stex.print2d("toggle", l3x, l3z, szbtn);

		--       text      size   r, g, b
		incline("blendmode=0", 0.5,0);
		incline("blendmode=1", 0.5,1);
		incline("blendmode=2", 0.5,2);
		incline("blendmode=3", 0.5,3);
		incline("blendmode=4", 0.5,4);
		incline("blendmode=5", 0.5,5);
		incline("blendmode=6", 0.5,6);

		--NOTE:  high contrast modes 3,6 show aliasing!

		if b1push then
			incline("radio btn #1, blendmode=6",0.5,6);
		elsif b2push then
			incline("radio btn #2, blendmode=6",0.5,6);
		end if;

		if b3push then
			incline("btn #3 down, blendmode=3",0.5,3);
		else
			incline("btn #3 up, blendmode=3",0.5,3);
		end if;


	end if;

end Draw;




	dwell : constant float := 0.5;
	ndwell : constant float := 0.2;

	keytime: float := 0.0;

	numbering: boolean:=false;


procedure handleKeys(currentTime: float) is
	ktime: float := 0.0;
begin


	if(key_map( SDL_SCANCODE_ESCAPE )/=0) then userexit:=true; end if;
	if( key_map( SDL_SCANCODE_Q ) /= 0 ) then userexit:=true; end if;

	ktime:=currentTime-keytime;

	
	if( key_map( SDL_SCANCODE_H )  /= 0 ) then --Help
		if ktime>dwell then
			help:= not help;
			keytime:=currentTime;
		end if;
	end if;


end handleKeys;








function odd( i: integer ) return boolean is
begin
	return ( i mod 2 = 1 );
end odd;

function bitmatch( x, y : integer ) return boolean is
	result : boolean := false;
	a : integer := x;
	b : integer := y;
begin
	for i in 1..32 loop
		if ( odd(a) and odd(b) ) then result:=true; end if;
		a:=a/2;
		b:=b/2;
	end loop;
	return result;
end;




state,ileft,iright: integer;
mousex, mousey : aliased interfaces.c.int;
mousestate : Uint32;

prevTime : float := 0.0;

procedure handle_mouse_click( nowTime, Wwid, Whit : float ) is

	fmx : float := float(mousex)/Wwid;
	fmy : float := float(mousey)/Whit;

	ox : constant float := 0.07; --0.05;
	oz : constant float := -0.01;
	Ok,drc,
	b1,b2,b3,b4,b5,b6,c7: boolean := false;

begin

--put_line("entering mouse_click");

	fmx := -1.0 + 2.0*fmx;
	fmy := -1.0 + 2.0*fmy;


	if( (nowTime-prevTime) > 0.5 ) then

		prevTime := nowTime;

		b1 := (abs(fmx-b1x)<bdx) and (abs(fmy-b1z)<bdz);
		b2 := (abs(fmx-b2x)<bdx) and (abs(fmy-b2z)<bdz);

		b3 := (abs(fmx-b3x)<bdx) and (abs(fmy-b3z)<bdz);

	end if;


	--radio Btn group
	if b1 then
		b1push:=true;
		b2push:=false;
	elsif b2 then
		b2push:=true;
		b1push:=false;
	end if;

	--toggle Btn
	if b3 then
		b3push:=not b3push;
	end if;

end handle_mouse_click;















	currentTime : float;
	test_event: aliased SDL_Event;



begin -- font-ttf ===================================================

	first_prep; -- init graphics/sound, defines fnum, flev

	updateMVP; --just once


	-- main event loop begin: --------------------------------------------
   while not userexit loop

		SDL_PumpEvents;
		key_map := sdl_getkeyboardstate(numkeys'access);
		handleKeys( float(sdl_getticks)/1000.0 );

		--pollEvent returns 0 if no [new] event pending:
		if SDL_PollEvent(test_event'access)>0 then
			if test_event.typ = SDL_WindowEvent then
				-- note unusual syntax due to quirk in binding
				-- caused by the case-insensitivity of Ada:
				if test_event.window.event=sdl_windowevent_close then
					userexit:=true;
				end if; --user hits closeWindow "x"
			end if;
		end if;

-------- here we handle resizing window ----------------------
		SDL_GetWindowSize( mainWindow, Nwid'access, Nhit'access );
		if( (Nwid /= Wwid) or (Nhit /= Whit) ) then
			wwid:=nwid; whit:=nhit;
			SDL_GL_GetDrawableSize( mainWindow, Fwid'access, Fhit'access );
			glViewport(0,0,Fwid,Fhit);
			stex.setTextWindowSize(Wwid,Whit);
		end if;


		currentTime := float(sdl_getticks)/1000.0;

		MouseState:=SDL_GetMouseState(mousex'access,mousey'access);
		state := integer( MouseState );
		ileft := integer( SDL_BUTTON(1) );
		iright:= integer( SDL_BUTTON(3) );

		if    
			bitmatch(state, ileft)   or
			bitmatch(state, iright)   or
			( key_map( SDL_SCANCODE_RETURN ) /= 0 )
		then 
			handle_mouse_click(currentTime, float(Wwid), float(Whit) );
		end if;


		Draw; -- main drawing here ###################################

		SDL_GL_SwapWindow( mainWindow );

   end loop; --------------------- main event loop end -------------------

	release_textures;
	stex.CloseFont;
	SDL_GL_DeleteContext(mainGLContext);
	SDL_DestroyWindow(mainWindow);
	SDL_Quit;

end fonttf;

