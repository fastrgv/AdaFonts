
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


package MatUtils is

----------------------------------------------------

	type vec4 is array(1..4) of float;

	type mat44 is  array(1..4,1..4) of aliased float;
	identity : constant mat44 :=
		( 
			(1.0, 0.0, 0.0, 0.0),
			(0.0, 1.0, 0.0, 0.0),
			(0.0, 0.0, 1.0, 0.0),
			(0.0, 0.0, 0.0, 1.0)
		);


	type mat33 is  array(1..3,1..3) of aliased float;


function safeSqrt( arg: float ) return float;

procedure matXvec( a : in mat44; b : in vec4; c : out vec4 );


procedure transpose( mm : in out mat44 );
procedure transpose( mm : in out mat33 );

-- a := a*b
procedure matXmat( a : in out mat44;  b : in mat44 );

procedure translate( 
	mo : in out mat44;
	x,y,z : float );

procedure perspective(
	mo : in out mat44;
	fovdeg, aspect, zNear, zFar : float );

procedure normalize( x,y,z : in out float );

procedure cross(
	a1,a2,a3,
	b1,b2,b3  : in float;
	c1,c2,c3  : out float );


-- functionally matches   glm::lookAt(),  because GLM was
-- carefully designed for the needs of C++ developers
procedure lookAt(
	mo : in out mat44;
	eyeX, eyeY, eyeZ,
	atX, atY, atZ,
	upX, upY, upZ : float );

procedure degRotate( mo : in out mat44; angleDeg,xx,yy,zz : float );


-- Reverses order of rotations.  This means that we can allow
-- the most recent procedure calls to represent the most
-- recent angular updates.
procedure degRevRotate( sumrot : in out mat44;
	rotx,roty,rotz : in float);
	
procedure InvTransp( mi : in mat44;  it : out mat33 );

end MatUtils;

