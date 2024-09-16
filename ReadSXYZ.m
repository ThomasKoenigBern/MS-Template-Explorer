function [Montage,pos,lbl] = ReadSXYZ(fname)

% Copyright 2009-2011 Thomas Koenig
% distributed under the terms of the GNU AFFERO General Public License

[fid,message] = fopen(fname,'rt');

if fid == -1
    errordlg(message,'Read SXYZ File');
    Montage = [];
    return;
end

l = fgets(fid);
[params,pcount] = sscanf(l,'%f');

nChannels = params(1);

C = textscan(fid,'%f%f%f%s');
fclose(fid);

if numel(C) ~= 4
    errordlg('Problem with file format, not 4 columns found','Read SXYZ File');
    Montage = [];
end

x = C{1};
y = C{2};
z = C{3};
lbl = C{4};

Coords.pos = [x y z];
Coords.lbl = lbl;

if numel(x) ~= nChannels
    errordlg('Channel number mismatch','Read SXYZ File');
end


h = SetXYZCoordinates([],[],[],Coords);

if isempty(h)
    Montage = [];
    return;
end

Coords = get(h,'UserData');

close(h);

x = Coords.x;
y = Coords.y;
z = Coords.z;

pos = [x y z];

sgnx = ones(numel(x),1);
sgnx(x<0) = -1;

sgny = ones(numel(y),1);
sgny(y<=0) = -1;

r = sqrt(x.*x + y.*y + z.*z);
rh = sqrt(x.*x + y.*y);
ph = abs(acos(abs(x) ./ rh) / pi * 180);
ph(rh == 0) = 0;
th = abs(acos(abs(z) ./ r ) / pi * 180);

for i = 1:nChannels
    Montage(i).Name = lbl{i};
    Montage(i).Ref = '';
    Montage(i).Radius = r(i);
       
    if z(i) < 0
        Montage(i).Theta = -(-180 + th(i)) * sgnx(i);
    else
        Montage(i).Theta = th(i)  * sgnx(i);
    end
    Montage(i).Phi  = ph(i) * sgnx(i) * sgny(i);
    Montage(i).sx = sgnx(i);
end




%pos = [x y z];    
%Montage = [y -x z];    
