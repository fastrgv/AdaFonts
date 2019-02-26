
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


with  Ada.Numerics.generic_elementary_functions;
with interfaces.c;  
use type interfaces.c.c_float;



package body MatUtils is
------------------------------------------------------------------



	package math is new
			Ada.Numerics.generic_elementary_functions( float );
	use math;


function safeSqrt( arg: float ) return float is
begin
	if arg<0.0001 then
		return 0.0;
	else
		return sqrt(arg);
	end if;
end safeSqrt;


procedure transpose( mm : in out mat44 ) is
	hold : float;
begin
	for row in 2..4 loop
	for col in 1..row-1 loop
			hold:=mm(row,col);
			mm(row,col):=mm(col,row);
			mm(col,row):=hold;
	end loop;
	end loop;
end transpose;


procedure transpose( mm : in out mat33 ) is
	hold : float;
begin
	for row in 2..3 loop
	for col in 1..row-1 loop
			hold:=mm(row,col);
			mm(row,col):=mm(col,row);
			mm(col,row):=hold;
	end loop;
	end loop;
end transpose;




-- c := a*b
procedure xmyMatVec( a : in mat44;  b : in vec4;  c : out vec4 ) is
begin
	c := ( others => 0.0 );
	for row in 1..4 loop
	for col in 1..4 loop
			c(row) := c(row) + a(row,col)*b(col);
	end loop; -- for row
	end loop; --for k
end xmyMatVec;





-- c := transpose(a)*b
procedure matXvec( a : in mat44;  b : in vec4;  c : out vec4 ) is
begin
	c := ( others => 0.0 );
	for k in 1..4 loop
		for row in 1..4 loop
			c(row) := c(row) + a(k,row)*b(k);
		end loop; -- for row
	end loop; --for k
end matXvec;









-- a := a*b
procedure matXmat( a : in out mat44;  b : in mat44 ) is
	c : mat44 := ( others => (others=>0.0) );
begin
	for col in 1..4 loop
		for k in 1..4 loop
			for row in 1..4 loop
				c(row,col) := c(row,col) + a(row,k)*b(k,col); --Ok
			end loop; -- for row
		end loop; --for k
	end loop; --for col
	a := c;
end matXmat;




procedure perspective(
	mo : in out mat44;
	fovdeg, aspect, zNear, zFar : float ) is

	onepi : constant float := ada.numerics.pi;
	fovy : float := fovdeg * onepi / 180.0;

	m : mat44;
	f : float := 1.0/tan(fovy/2.0);
	a33 : float := (zFar+zNear)/(zNear-zFar);
	a34 : float := 2.0*zFar*zNear/(zNear-zFar);
	a11 : float := f/aspect;
begin

	m(1,1):= a11;	m(1,2):= 0.0;	m(1,3):= 0.0;	m(1,4):= 0.0;
	m(2,1):= 0.0;	m(2,2):= f;		m(2,3):= 0.0;	m(2,4):= 0.0;
	m(3,1):= 0.0;	m(3,2):= 0.0;	m(3,3):= a33;	m(3,4):= a34;
	m(4,1):= 0.0;	m(4,2):= 0.0;	m(4,3):=-1.0;	m(4,4):= 0.0;
	transpose(m);
	mo := m;

end perspective;


procedure normalize( x,y,z : in out float ) is
	len : float := safesqrt( x*x+y*y+z*z );
begin
	x:=x/len;
	y:=y/len;
	z:=z/len;
end normalize;

procedure cross(
	a1,a2,a3,
	b1,b2,b3  : in float;
	c1,c2,c3  : out float ) is
begin
	c1 := a2*b3 - b2*a3;
	c2 := a3*b1 - b3*a1;
	c3 := a1*b2 - b1*a2;
end cross;




procedure translate( 
	mo : in out mat44;
	x,y,z : float ) is
	m : mat44;
begin

	m := identity;

	m(4,1):=x;
	m(4,2):=y;
	m(4,3):=z;

	matXmat( mo, m );

end translate;




-- functionally matches   glm::lookAt(),  because GLM was
-- carefully designed for the needs of C++ developers
procedure lookAt(
	mo : in out mat44;
	eyeX, eyeY, eyeZ,
	atX, atY, atZ,
	upX, upY, upZ : float ) is  -- UP is assumed to be a UNIT-vector

	m : mat44;

	dotse, dotue, dotfe,
	s0,s1,s2,u0,u1,u2,f0,f1,f2 : float;

begin

	f0:=atX-eyeX;
	f1:=atY-eyeY;
	f2:=atZ-eyeZ;
	normalize(f0,f1,f2);

	cross(f0,f1,f2, upx,upy,upz, s0,s1,s2);

	cross(s0,s1,s2, f0,f1,f2, u0,u1,u2);

	dotse := s0*eyeX + s1*eyeY + s2*eyeZ;
	dotue := u0*eyeX + u1*eyeY + u2*eyeZ;
	dotfe := f0*eyeX + f1*eyeY + f2*eyeZ;

	m(1,1):= s0;		m(1,2):= u0;		m(1,3):=-f0;		m(1,4):= 0.0;
	m(2,1):= s1;		m(2,2):= u1;		m(2,3):=-f1;		m(2,4):= 0.0;
	m(3,1):= s2; 		m(3,2):= u2;		m(3,3):=-f2;		m(3,4):= 0.0;
	m(4,1):=-dotse;	m(4,2):=-dotue;	m(4,3):=+dotfe;	m(4,4):= 1.0;

	mo:=m;

end lookAt;












procedure degRotate( mo : in out mat44; angleDeg,xx,yy,zz : float ) is

	onepi : constant float := ada.numerics.pi;
	radians : constant float := angleDeg/180.0 * onepi;
	c : constant float := math.cos(radians);
	s : constant float := math.sin(radians);
	cc : constant float := 1.0-c;
	m : mat44;
	x,y,z : float;

begin

	x:=xx; y:=yy; z:=zz;  normalize(x,y,z);

	m(1,1):= x*x*cc+c;	m(1,2):= y*x*cc+z*s;	m(1,3):= x*z*cc-y*s;	m(1,4):= 0.0;
	m(2,1):= x*y*cc-z*s;	m(2,2):= y*y*cc+c;	m(2,3):= y*z*cc+x*s;	m(2,4):= 0.0;
	m(3,1):= x*z*cc+y*s;	m(3,2):= y*z*cc-x*s;	m(3,3):= z*z*cc+c;	m(3,4):= 0.0;
	m(4,1):= 0.0;			m(4,2):= 0.0;			m(4,3):= 0.0;			m(4,4):= 1.0;
	matXmat( mo, m );

end degRotate;





procedure degTrotate( mo : in out mat44; angleDeg,xx,yy,zz : float ) is

	onepi : constant float := ada.numerics.pi;
	radians : constant float := angleDeg/180.0 * onepi;
	c : constant float := math.cos(radians);
	s : constant float := math.sin(radians);
	cc : constant float := 1.0-c;
	m : mat44;
	x,y,z : float;

begin

	x:=xx; y:=yy; z:=zz;  normalize(x,y,z);

	m(1,1):= x*x*cc+c;	m(1,2):= y*x*cc+z*s;	m(1,3):= x*z*cc-y*s;	m(1,4):= 0.0;
	m(2,1):= x*y*cc-z*s;	m(2,2):= y*y*cc+c;	m(2,3):= y*z*cc+x*s;	m(2,4):= 0.0;
	m(3,1):= x*z*cc+y*s;	m(3,2):= y*z*cc-x*s;	m(3,3):= z*z*cc+c;	m(3,4):= 0.0;
	m(4,1):= 0.0;			m(4,2):= 0.0;			m(4,3):= 0.0;			m(4,4):= 1.0;
	transpose(m);
	matXmat( mo, m );

end degTrotate;


-- Reverses order of rotations.  This means that we can allow
-- the most recent procedure calls to represent the most
-- recent angular updates.
procedure degRevRotate( sumrot : in out mat44;
	rotx, roty, rotz : in float
) is
	mm : mat44 := identity;
begin

	degTrotate(mm, rotx, 1.0, 0.0, 0.0);
	degTrotate(mm, roty, 0.0, 1.0, 0.0);
	degTrotate(mm, rotz, 0.0, 0.0, 1.0);

	transpose(sumrot);
	matXmat( mm, sumrot );

	transpose(mm);
	sumrot := mm;

end degRevRotate;







-- in case we need a normalMatrix, we get it by
-- InvTransp(MM, NM);
-- where MM = modelmatrix
-- ...but in this App, MM=ID...

procedure InvTransp( mi : in mat44;  it : out mat33 ) is

	-- note: we use only the upperleft 3x3 part of mi.

	det : float;

begin

	det :=
		+ mi(1,1) * ( mi(2,2) * mi(3,3) - mi(2,3) * mi(3,2) )
		- mi(1,2) * ( mi(2,1) * mi(3,3) - mi(2,3) * mi(3,1) )
		+ mi(1,3) * ( mi(2,1) * mi(3,2) - mi(2,2) * mi(3,1) );

	it(1,1):= + ( mi(2,2) * mi(3,3) - mi(3,2) * mi(2,3) ) / det;
	it(1,2):= - ( mi(2,1) * mi(3,3) - mi(3,1) * mi(2,3) ) / det;
	it(1,3):= + ( mi(2,1) * mi(3,2) - mi(3,1) * mi(2,2) ) / det;

	it(2,1):= - ( mi(1,2) * mi(3,3) - mi(3,2) * mi(1,3) ) / det;
	it(2,2):= + ( mi(1,1) * mi(3,3) - mi(3,1) * mi(1,3) ) / det;
	it(2,3):= - ( mi(1,1) * mi(3,2) - mi(3,1) * mi(1,2) ) / det;

	it(3,1):= + ( mi(1,2) * mi(2,3) - mi(2,2) * mi(1,3) ) / det;
	it(3,2):= - ( mi(1,1) * mi(2,3) - mi(2,1) * mi(1,3) ) / det;
	it(3,3):= + ( mi(1,1) * mi(2,2) - mi(2,1) * mi(1,2) ) / det;


end InvTransp; -- 4jan18 update






------------------------------------------------------------------

end MatUtils;


