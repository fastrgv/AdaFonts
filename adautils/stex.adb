with Interfaces.C;
with Interfaces.C.strings;
with text_io;
with matutils;
with system;

with FT;
with FT.Faces;
with FT.Glyphs;

with gl, gl.binding, gl.pointers;
with glu, glu.binding, glu.pointers;
with glext, glext.binding, glext.pointers;

with shader;


package body stex is
   use Interfaces.C;

	use shader;

	use text_io;
	use matutils;

	use interfaces.c;
	use interfaces.c.strings;
	use glext;
	use glext.pointers;
	use glext.binding;
	use gl;
	use gl.binding;
	use gl.pointers;

	Colour: vec4;
	Projection_Matrix: mat44;

	WindowWidth, WindowHeight : glint;

   type Character_Record is record
      Texture   : gluint:= 0;
      Width     : glint := 0;
      Rows      : glint := 0;
      Left      : glint := 0;
      Top       : glint := 0;
      Advance_X : glint := 0;
   end record;

   OGL_Exception      : Exception;

   type Character_Data_Vector is 
		array (Natural range <>) of Character_Record;

	tid, pmid, cid: glint;
	progid: gluint;

   Vertex_Array_ID         : gluint;
   Vertex_Buffer_ID        : gluint;
   Extended_Ascii_Data  : Character_Data_Vector (0 .. 255);

   procedure Setup_Character_Textures (Face_Ptr : FT.Faces.Face_Reference);
   procedure Setup_Font (theLibrary : FT.Library_Reference;
                         Face_Ptr   : out FT.Faces.Face_Reference;
                         Font_File  : String);

   --  -------------------------------------------------------------------

   function Advance_X (Data : Character_Record) return glint is
   begin
      return Data.Advance_X;
   end Advance_X;

   --  -------------------------------------------------------------------




    --  --------------------------------------------------------------
    --  Init_Orthographic_Transform is derived from
    --  Computer Graphics Using OpenGL, Chapter 7, 
	 --  transpose of equation 7.18

    procedure Init_Orthographic_Transform (
	 	Top, Bottom, Left, Right, Z_Near, Z_Far : float;
      Transform     : out mat44) is

        dX : constant float := Right - Left;
        dY : constant float := Top - Bottom;
        dZ : constant float := Z_Far - Z_Near;
    begin
        Transform := Identity;
        Transform (1,1) := 2.0 / dX;
        Transform (4,1) := -(Right + Left) / dX;
        Transform (2,2) := 2.0 / dY;
        Transform (4,2) := -(Top + Bottom) / dY;
        Transform (3,3) := 2.0 / dZ;
        Transform (4,3) := -(Z_Far + Z_Near) / dZ;
    end Init_Orthographic_Transform;

    --  --------------------------------------------------------------



	procedure setColor( color: vec4 ) is
	begin
		Colour:=color;
	end setColor;

	procedure setTextWindowSize( wid, hit : glint ) is
	begin

		WindowWidth:=wid;
		WindowHeight:=hit;

      Init_Orthographic_Transform 
		( float(WindowHeight), 0.0, 0.0,
        float(WindowWidth), 0.1, -100.0,
        Projection_Matrix);

	end setTextWindowSize;


   procedure InitFont ( Font_File : String ) is

      theLibrary : FT.Library_Reference;
      Face_Ptr   : FT.Faces.Face_Reference;

   begin

	progid := 
		loadshaders(
			"data/textVs410.glsl",   --vs
			"data/textFs410.glsl"); --fs

	PMid  := 
		glgetuniformlocation
			(progid, new_string("projection_matrix"&ascii.nul)); --vs

	tid   := 
		glgetuniformlocation
			(progid, new_string("text_sampler"&ascii.nul)); --fs

	cid   := 
		glgetuniformlocation
			(progid, new_string("text_colour"&ascii.nul)); --fs



      theLibrary.Init;
      Setup_Font (theLibrary, Face_Ptr, Font_File);

      Setup_Character_Textures (Face_Ptr);


		--do the following ONCE:

		glgenvertexarrays(1, vertex_array_id'address );
		glbindvertexarray(vertex_array_id);

		glgenbuffers(1, vertex_buffer_id'address);

		gl.binding.glactivetexture(gl_texture0); -- do only once!


   end InitFont;

	procedure CloseFont is
	begin
		glext.binding.glDeleteVertexArrays(1, vertex_array_id'address);
	end CloseFont;
   --  -------------------------------------------------------------------

   procedure Load_Texture (Face_Ptr  : FT.Faces.Face_Reference;
                           Char_Data : in out Character_Record;
                           Width, Height : glsizei;
                           X_Offset, Y_Offset : glint) is
      aTexture          : gluint;
      Bitmap            : constant FT.Bitmap_Record :=
                                   FT.Glyphs.Bitmap (Face_Ptr.Glyph_Slot);
      Num_Levels        : constant gluint := 1;
      Mip_Level_0       : constant glint := 0;

   begin

		gl.binding.glgentextures(1,atexture'address);
		gl.binding.glbindtexture(gl_texture_2d, atexture);


		-- fastrgv:  gl_linear is NOT a valid option for texture_wrap 27feb18
		-- ...valid options are a) gl_repeat, b) gl_mirrored_repeat, c)gl_clamp_to_edge
		gltexparameteri(gl_texture_2d, gl_texture_wrap_s, gl_clamp_to_edge);
		gltexparameteri(gl_texture_2d, gl_texture_wrap_t, gl_clamp_to_edge);
		--gltexparameteri(gl_texture_2d, gl_texture_mag_filter, gl_nearest);
		--gltexparameteri(gl_texture_2d, gl_texture_min_filter, gl_nearest);

		gltexparameteri(gl_texture_2d, gl_texture_mag_filter, gl_linear);
		gltexparameteri(gl_texture_2d, gl_texture_min_filter, gl_linear);

		glgeneratemipmap(gl_texture_2d);


      if Width > 0 and then Height > 0 then
			gltexstorage2d(gl_texture_2d, 1, gl_RGBA8, Width, Height);
      else
			gltexstorage2d(gl_texture_2d, 1, gl_RGBA8, 1,1);
      end if;


      if Width > 0 and Height > 0 then

			gl.binding.gltexsubimage2d(gl_texture_2d,
				mip_level_0, 
				x_offset, y_offset, 
				width,height, 
				gl_red, gl_unsigned_byte, bitmap.buffer);

      end if;

      Char_Data.Texture := aTexture;

		-- if this next line is present, then
		-- the cube does NOT appear...
		--gldeletebuffers(1,atexture'address);

   end Load_Texture;

   -- ---------------------------------------------------------------------

   procedure printex (
		Text   : String; 
		X, Y, Scale : float;
		mode: integer) is

      use FT.Faces;

      Num_Triangles  : constant glint := 2;
      Num_Vertices   : constant glint := Num_Triangles * 3;
      Num_Components : constant glint := 4;  -- Coords vector size;
      Stride         : constant glint := 0;
      Char           : Character;
      Char_Data      : Character_Record;
      charTexID      : gluint;
      X_Orig         : float := X;
      Y_Orig         : constant float := Y;
      X_Pos          : float;
      Y_Pos          : float;
      Char_Width     : float;
      Height         : float;
      --  2D quad as two triangles requires 2 * 3 vertices of 4 floats
      Vertex_Data    : array (1 .. Num_Vertices) of vec4; -- 1..6 * 4

		blendWasEnabled : glboolean :=gl.binding.glIsEnabled(gl_blend);

   begin


		if blendWasEnabled=gl_false then
			gl.binding.glenable(gl_blend);
		end if;

      for index in Text'Range loop
         Char := Text (index);
         Char_Data := Extended_Ascii_Data (Character'Pos (Char));
         X_Pos := X_Orig + float (Char_Data.Left) * Scale;
         Y_Pos := Y_Orig - float (Char_Data.Rows - Char_Data.Top) * Scale;
         Char_Width := float (Char_Data.Width) * Scale;
         Height := float (Char_Data.Rows) * Scale;

         Vertex_Data := ((X_Pos, Y_Pos + Height,             0.0, 0.0),
                         (X_Pos, Y_Pos,                      0.0, 1.0),
                         (X_Pos + Char_Width, Y_Pos,         1.0, 1.0),

                         (X_Pos, Y_Pos + Height,              0.0, 0.0),
                         (X_Pos + Char_Width, Y_Pos,          1.0, 1.0),
                         (X_Pos + Char_Width, Y_Pos + Height, 1.0, 0.0));


			gluseprogram(progid);


	if mode=0 then --white
	gl.binding.glblendfunc(gl_src_alpha, gl_one_minus_src_alpha); --default

	elsif mode=1 then --white
	gl.binding.glblendfunc(gl_one, gl_one_minus_src_alpha); --white

	elsif mode=2 then --black
	gl.binding.glblendfunc(gl_zero, gl_one_minus_src_alpha); --black

	elsif mode=3 then --contrast lettering
	gl.binding.glblendfunc(gl_one_minus_dst_color, gl_one_minus_src_alpha);

	elsif mode=4 then --same as 2
	gl.binding.glblendfunc(gl_constant_color, gl_one_minus_src_alpha);--?

	--NOT as expected...white lettering outlined with black
	elsif mode=5 then
	gl.binding.glblendfunc(gl_src_alpha, gl_one_minus_dst_color);

	elsif mode=6 then --similar to 3
	glext.binding.glblendfuncseparate(
		gl_one_minus_dst_color, gl_one_minus_src_alpha,
		gl_src_alpha, gl_one_minus_src_alpha
		);
	end if;


         charTexID :=  Char_Data.Texture;
			gl.binding.glbindtexture(gl_texture_2d, charTexID);

			gluniform1i(tid, 0);
			gluniform3f(cid, 
				glfloat(colour(1)),glfloat(colour(2)), glfloat(colour(3)));
			gluniformmatrix4fv( 
				pmid, 1, gl_false, 
				projection_matrix(1,1)'address );


			glenablevertexattribarray(0);
			glbindbuffer(glext.gl_array_buffer, vertex_buffer_id);
			glbufferdata( 
				glext.gl_array_buffer, 
				(float'size/8)*4*vertex_data'length, 
				vertex_data(1)'address, glext.gl_dynamic_draw);

			glvertexattribPointer(
				0,4, gl_float, gl_false, 0, system.null_address);

			gl.binding.gldrawarrays( gl_triangles, 0, 6 ); --6=num_vertices

			gldisablevertexattribarray(0);

         --  Bitshift by 6 to get value in pixels (2^6 = 64
         --  (divide amount of 1/64th pixels by 64 to get amount of pixels))
         X_Orig := X_Orig + float (Advance_X (Char_Data)) / 64.0 * Scale;

      end loop;

		if blendWasEnabled=gl_false then
			gl.binding.gldisable(gl_blend);
		end if;


   end printex;





	-- here, (X,Y) represent fractions of window size in (0,1)
   procedure print2d (
		Text   : String; 
		X, Y, Scale : float;
		mode: integer:=0
		) is
		diam: constant float := 0.5*float(WindowWidth+WindowHeight)/500.0;
	begin --print2d
		printex(
			Text,
			X*float(WindowWidth),
			Y*float(WindowHeight),
			diam*Scale,mode);
	end print2d;









   procedure print3d (
		Text   : String; 
		ccx,ccy,ccz,ccw : float;
		Scale : float) is

		fwid : constant float := float(WindowWidth);
		fhit : constant float := float(WindowHeight);

		-- Normalize Device Coords in [-1..1]
		xndc : constant float := ccx/ccw;
		yndc : constant float := ccy/ccw;
		zndc : constant float := ccz/ccw;

		-- coords in [0..1]
		xcen : constant float := (1.0+xndc)/2.0;
		ycen : constant float := (1.0+yndc)/2.0;

		eps : constant float := 0.001;

	begin --print3d

		printex(
			Text,
			fwid*xcen,
			fhit*ycen,
			Scale,0);

	end print3d;






   --  ------------------------------------------------------------------------

   procedure Set_Char_Data (Char_Data : in out Character_Record;
                            Width     : glint; Height : glint;
                            Left      : glint; Top    : glint;
                            Advance_X : glint) is
   begin
      Char_Data.Width := Width;
      Char_Data.Rows := Height;
      Char_Data.Left := Left;
      Char_Data.Top := Top;
      Char_Data.Advance_X := Advance_X;
   end Set_Char_Data;

   --  --------------------------------------------------------------------

   procedure Setup_Character_Textures (Face_Ptr : FT.Faces.Face_Reference) is
      Glyph_Slot     : constant FT.Glyph_Slot_Reference := Face_Ptr.Glyph_Slot;
      Width          : glint;
      Height         : glint;
      X_Offset       : constant glint := 0;
      Y_Offset       : constant glint := 0;
      Char_Data      : Character_Record;

		blendWasEnabled : glboolean :=gl.binding.glIsEnabled(gl_blend);

   begin

      --  Blending allows a fragment color's alpha value to control the resulting
      --  color which will be transparent for all the glyph's background colors and
      --  non-transparent for the actual character pixels.
		if blendWasEnabled=gl_false then
			gl.binding.glenable(gl_blend);
		end if;
		gl.binding.glblendfunc(gl_src_alpha, gl_one_minus_src_alpha);

		--glbindvertexarray(vertex_buffer_id);


      for index in Extended_Ascii_Data'Range loop
         --  Load_Render asks FreeType to create an 8-bit grayscale bitmap image
         --  that can be accessed via face->glyph->bitmap.
         FT.Faces.Load_Character (Face_Ptr, unsigned_long (index),
                                  FT.Faces.Load_Render);



         --  Ensure that the glyph image is an anti-aliased bitmap
         FT.Glyphs.Render_Glyph (Glyph_Slot, FT.Faces.Render_Mode_Mono);

         Width := glint (FT.Glyphs.Bitmap (Glyph_Slot).Width);
         Height := glint (FT.Glyphs.Bitmap (Glyph_Slot).Rows);

         Set_Char_Data (Char_Data, Width, Height,
                        glint (FT.Glyphs.Bitmap_Left (Glyph_Slot)),
                        glint (FT.Glyphs.Bitmap_Top (Glyph_Slot)),
                        glint (FT.Glyphs.Advance (Glyph_Slot).X));

         Load_Texture (Face_Ptr, Char_Data, Width, Height, X_Offset, Y_Offset);

         Extended_Ascii_Data (index) := Char_Data;
      end loop;

		if blendWasEnabled=gl_false then
			gl.binding.gldisable(gl_blend);
		end if;

   end Setup_Character_Textures;

      --  ------------------------------------------------------------------------

   procedure Setup_Font (
		theLibrary : FT.Library_Reference;
      Face_Ptr   : out FT.Faces.Face_Reference; 
		Font_File : String) is
   begin

      FT.Faces.New_Face (theLibrary, Font_File, 0, Face_Ptr);

      --  Set pixel size to 48 x 48
      FT.Faces.Set_Pixel_Sizes (Face_Ptr, 0, 48);

      --  Disable byte-alignment restriction
		glpixelstorei(gl_unpack_alignment,1);
   end Setup_Font;

   --  ------------------------------------------------------------------------

end stex;
