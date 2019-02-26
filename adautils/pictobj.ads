
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

with gl;  use gl;
with ada.finalization;
with unchecked_deallocation;



package pictobj is -- for textured rectangular exterior, eg. partition wall

-- maps texture coordinates UV to cover the full extent of a side;
-- thus the whole *.png file is visible

type pictangle is tagged private;

procedure setrect( rect: pictangle;
xc,yc,zc, xr,yr,zr : float );

procedure draw( rect: pictangle; vertbuff, uvbuff, elembuff : gluint );

private

nvert : constant integer := 72;
nuv : constant integer := 48;
nelm : constant integer := 36;

type varray is array(1..nvert) of float;
type vap is access varray;

type tarray is array(1..nuv) of float;
type tap is access tarray;

type earray is array(1..nelm) of glushort;
type eap is access earray;

type pictangle is new ada.finalization.controlled with record
	vert : vap;
	txuv : tap;
	elem : eap;
end record;


procedure initialize(rect: in out pictangle);
procedure finalize(rect: in out pictangle);

end pictobj;

