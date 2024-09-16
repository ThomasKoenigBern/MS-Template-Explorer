function h = bluered(m)
%HOT    Black-red-yellow-white color map.
%   HOT(M) returns an M-by-3 matrix containing a "hot" colormap.
%   HOT, by itself, is the same length as the current colormap.
%
%   For example, to reset the colormap of the current figure:
%
%             colormap(hot)
%
%   See also HSV, GRAY, PINK, COOL, BONE, COPPER, FLAG, 
%   COLORMAP, RGBPLOT.

%   C. Moler, 8-17-88, 5-11-91, 8-19-92.
%   Copyright 1984-2001 The MathWorks, Inc. 
%   $Revision: 5.6 $  $Date: 2001/04/15 11:58:57 $

if nargin < 1, m = size(get(gcf,'colormap'),1); end

n = fix(1/2*m);
o = m - n - n;

r = [(0:n-1)'/n ;ones(o,1) ; ones(n,1)];
g = [(0:n-1)'/n ;ones(o,1) ; (n-1:-1:0)'/n];
b = [ones(n,1);ones(o,1); (n-1:-1:0)'/n];  

h = [r g b];