with gl; use gl;
with matutils; use matutils;

package stex is

	procedure CloseFont;
   procedure InitFont (
		Font_File : String );

	procedure setColor( color: vec4 );
	procedure setTextWindowSize( wid, hit: glint );

   procedure print2d (
      Text   : String; 
		X, Y, Scale : float;
		mode: integer := 0);

   procedure print3d (
      Text   : String; 
		ccx,ccy,ccz,ccw : float;
		Scale : float );

end stex;
