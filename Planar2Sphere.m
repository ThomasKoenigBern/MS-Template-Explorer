function [x,y,z] = Planar2Sphere(pxG,pyG,fact)

    if nargin < 3
        fact = 1;
    end
    Theta = sqrt(pxG.^2 + pyG.^2);

    z = cos(Theta/180 * pi);
       
    k = sqrt((1-z.^2) ./ (pxG.^2 + pyG.^2));
    
    
    Theta(Theta == 0) = 1;
    
    x = pxG .* k * fact;
    y = pyG .* k * fact;
    z = z * fact;
        
end
