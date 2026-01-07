function HelperData = dspCMap2T(map,ChanPos,varargin)
% dspCMap2 - Display topographic scalp maps
% ----------------------------------------
% Copyright 2009-2011 Thomas Koenig
% distributed under the terms of the GNU AFFERO General Public License
%
% Usage: dspCMap(map,ChanPos,CStep)
%
% map is the 1xN voltage map to display, where N is the number of electrode
%
% ChanPos contains the electrode positions, either as Nx3 xyz coordinates,
% or as structure withRadius, Theta and Phi (Brainvision convention), or as
% labels of the 10-10 system
%
% CStep is the size of a single step in the contourlines, a default is used
% if this is not set
%
% There are a series of options that can be set using parameter/value
% pairs:
%dir
%
% 'Step'            Step between contour lines
% 'Axis'            The Axis to plot into
% 'LineWidth'       Sets linewidth
% '3D'              Show the map in 3D
    
    HelperFieldNames = {'NewHullEdgesX','NewHullEdgesY','XGrid2DaxPlane','YGrid2DaxPlane','XAxis2DGrid','YAxis2DGrid','XGrid2D','YGrid2D','InHull','ElectrodesOnPlaneX','ElectrodesOnPlaneY','InterpolationMatrix'};
    
    InputParameters = inputParser;
    addOptional(InputParameters,'Step'        ,max(abs(map)) / 4, @(x) isnumeric(x) && isscalar(x));
    addOptional(InputParameters,'Axis'        ,[],@(x)isa(x,'matlab.graphics.axis.Axes')||isempty(x));
    addOptional(InputParameters,'tValues'     ,[],@(x)isnumeric(x));
    addOptional(InputParameters,'FigureHandle',[],@(x)isa(x,'matlab.ui.Figure')||isempty(x));
    addOptional(InputParameters,'LineWidth'   ,1,@(x)isnumeric(x)&&isscalar(x));
    addOptional(InputParameters,'ContourLines',false,@(x)islogical(x)&&isscalar(x));
    addOptional(InputParameters,'Title'       ,[],@(s)isstring(s) || ischar(s));
    addOptional(InputParameters,'Show3D'      ,[],@(x)(islogical(x)||isempty(x))&&isscalar(x));
    addOptional(InputParameters,'MenuButton'  ,false,@(x)islogical(x)&&isscalar(x));
    addOptional(InputParameters,'TuningMode'  ,false,@(x)islogical(x)&&isscalar(x));
    addOptional(InputParameters,'ContextMenu' ,false,@(x)islogical(x)&&isscalar(x));
    addOptional(InputParameters,'Background'  ,[],@(x)(all(isnumeric(x))&&numel(x) == 3) || isempty(x));
    addOptional(InputParameters,'ShowPosition',[],@(x)(all(islogical(x))||iscell(x)) || isempty(x));

    parse(InputParameters,varargin{:});

    if InputParameters.Results.TuningMode
        clc;
        tic;
    end

     if isempty(InputParameters.Results.Axis)
        AxisToUse = gca;
    else
        AxisToUse = InputParameters.Results.Axis;
    end

    if isempty(InputParameters.Results.FigureHandle)
        FigureToUse = gcf;
    else
        FigureToUse = InputParameters.Results.FigureHandle;
    end
    if nargout < 1
        UserData = AxisToUse.UserData;
    else
        UserData = [];
    end
    
    
    HelperDataThere = false;
    
    if isstruct(ChanPos) && nargout < 1
        if isfield(ChanPos,'HelperData')
            for fn = HelperFieldNames
                UserData.PrivateMapInfo.(fn{1}) = ChanPos.HelperData.(fn{1});
            end
        HelperDataThere = true;
        end
    end
   
    UserData.PrivateMapInfo.tMap         = InputParameters.Results.tValues;
    UserData.PrivateMapInfo.FigureHandle = FigureToUse;
    UserData.PrivateMapInfo.MapLineWidth = InputParameters.Results.LineWidth;
    UserData.PrivateMapInfo.ContourLines = InputParameters.Results.ContourLines;
    UserData.PrivateMapInfo.Title        = InputParameters.Results.Title;
    UserData.PrivateMapInfo.MenuButton   = InputParameters.Results.MenuButton;
    UserData.PrivateMapInfo.Background   = InputParameters.Results.Background;
    UserData.PrivateMapInfo.ShowPosition = InputParameters.Results.ShowPosition;
    
    if ~isempty(InputParameters.Results.Show3D)
        UserData.PrivateMapInfo.Show3D       = InputParameters.Results.Show3D;
    else
        if ~isfield(UserData.PrivateMapInfo,'Show3D')
            UserData.PrivateMapInfo.Show3D = false;
        end
    end
                
    if HelperDataThere == false
        res = 1;
   
        if iscell(ChanPos)
            ChanPos = GetChannelPositionsFromLabels(ChanPos);
        end

        if isstruct(ChanPos)
            if isfield(ChanPos,'Theta') || isfield(ChanPos,'CoordsTheta')
                [x,y,z] = VAsph2cart(ChanPos);
            
            elseif isfield(ChanPos,'X')
                y =  cell2mat({ChanPos.X});
                x = -cell2mat({ChanPos.Y});
                z =  cell2mat({ChanPos.Z});
            elseif isfield(ChanPos,'x')
                x = -cell2mat({ChanPos.x});
                y =  cell2mat({ChanPos.y});
                z =  cell2mat({ChanPos.z});
            else
                error('Unknown montage format');
            end
        
        else
            if size(ChanPos,1) == 3
                ChanPos = ChanPos';
            end
            x = -ChanPos(:,2)';
            y =  ChanPos(:,1)';
            z =  ChanPos(:,3)';
        end

        r = sqrt(x.*x + y.*y + z.*z);

        x = x ./ r;
        y = y ./ r;
        z = z ./ r;

        x = x(:)';
        y = y(:)';
        z = z(:)';


        % Here, we project things on a sphere
        
        Theta = acos(z) / pi * 180;
        r = sqrt(x.*x + y.* y);
        
        r(r == 0) = 1;

        UserData.PrivateMapInfo.ElectrodesOnPlaneX = x./r.*Theta;
        UserData.PrivateMapInfo.ElectrodesOnPlaneY = y./r.*Theta;
    
        if ~isempty(UserData.PrivateMapInfo.ShowPosition)
            UserData.PrivateMapInfo.ElectrodesToPlotX = x./r.*Theta;
            UserData.PrivateMapInfo.ElectrodesToPlotY = y./r.*Theta;
        end
        if InputParameters.Results.TuningMode
            fprintf(1,'Start Hull: %f\n',toc);
        end

        % This finds the convex hull around the electrodes and interpolates
        % the points in between making spheres instead of straight lines,
        % as these lines look bad in 3D
        
        [kHull] = convhull(UserData.PrivateMapInfo.ElectrodesOnPlaneX,UserData.PrivateMapInfo.ElectrodesOnPlaneY);
    
        HullOriginalEdgesX = UserData.PrivateMapInfo.ElectrodesOnPlaneX(kHull);
        HullOriginalEdgesY = UserData.PrivateMapInfo.ElectrodesOnPlaneY(kHull);

        HullOriginalEdgesRadius = sqrt(HullOriginalEdgesX.^2 + HullOriginalEdgesY.^2);
        HullOriginalEdgesAngle  = acos(HullOriginalEdgesY./HullOriginalEdgesRadius);
        HullOriginalEdgesAngle(HullOriginalEdgesX > 0) = 2 * pi - HullOriginalEdgesAngle(HullOriginalEdgesX > 0);
        [~,idx] = min(HullOriginalEdgesAngle);
        HullOriginalEdgesAngle(1:(idx-1)) = HullOriginalEdgesAngle(1:(idx-1)) - 2*pi;   % These are all the angles of the electrodes

        HullOriginalEdgesAngle = [HullOriginalEdgesAngle HullOriginalEdgesAngle(1) + 2*pi];
        HullOriginalEdgesRadius = [HullOriginalEdgesRadius HullOriginalEdgesRadius(1)];

        [HullOriginalEdgesAngle,idx] = unique(HullOriginalEdgesAngle);

        NewHullAngles = unique(min(HullOriginalEdgesAngle):4 * pi /180:max(HullOriginalEdgesAngle));    % These are the angles of the new sphere
        HullOriginalEdgesRadius = HullOriginalEdgesRadius(idx);
        InterpRadius = interp1(HullOriginalEdgesAngle,HullOriginalEdgesRadius,NewHullAngles);   % The radius is linearly interpolated
    
        UserData.PrivateMapInfo.NewHullEdgesX = sin(NewHullAngles).* InterpRadius;              % And we recompute X and Y of the full hull
        UserData.PrivateMapInfo.NewHullEdgesY = cos(NewHullAngles).* InterpRadius;

        % Here, we create an equally spaced grid that Matlab can handle
        % well
        UserData.PrivateMapInfo.XGrid2DaxPlane = max(abs(UserData.PrivateMapInfo.NewHullEdgesX));
        UserData.PrivateMapInfo.YGrid2DaxPlane = max(abs(UserData.PrivateMapInfo.NewHullEdgesY));

        UserData.PrivateMapInfo.XAxis2DGrid = -UserData.PrivateMapInfo.XGrid2DaxPlane:res:UserData.PrivateMapInfo.XGrid2DaxPlane;
        UserData.PrivateMapInfo.YAxis2DGrid = -UserData.PrivateMapInfo.YGrid2DaxPlane:res:UserData.PrivateMapInfo.YGrid2DaxPlane;

        [UserData.PrivateMapInfo.XGrid2D,UserData.PrivateMapInfo.YGrid2D] = meshgrid(UserData.PrivateMapInfo.XAxis2DGrid,UserData.PrivateMapInfo.YAxis2DGrid);

        if InputParameters.Results.TuningMode
            fprintf(1,'Before inpolygon: %f\n',toc);
        end
        UserData.PrivateMapInfo.InHull = inpolygon(UserData.PrivateMapInfo.XGrid2D,UserData.PrivateMapInfo.YGrid2D,UserData.PrivateMapInfo.NewHullEdgesX,UserData.PrivateMapInfo.NewHullEdgesY);

        PointsToExtrapolateX = UserData.PrivateMapInfo.NewHullEdgesX(2:end)*1.05;
        PointsToExtrapolateY = UserData.PrivateMapInfo.NewHullEdgesY(2:end)*1.05;
        
        
        [mx,my,mz] = Planar2Sphere(PointsToExtrapolateX,PointsToExtrapolateY,1.00);
        
      
        
        if InputParameters.Results.TuningMode
            fprintf(1,'Before interpolation: %f\n',toc);
        end
        UserData.PrivateMapInfo.InterpolationMatrix = [eye(numel(x)); splint2([x(:) y(:) z(:)],eye(numel(x)),[mx(:) my(:) mz(:)])];
        
        UserData.PrivateMapInfo.ElectrodesOnPlaneX = [UserData.PrivateMapInfo.ElectrodesOnPlaneX(:);PointsToExtrapolateX(:)];
        UserData.PrivateMapInfo.ElectrodesOnPlaneY = [UserData.PrivateMapInfo.ElectrodesOnPlaneY(:);PointsToExtrapolateY(:)];

        if InputParameters.Results.TuningMode
            fprintf(1,'After interpolation: %f\n',toc);
        end
    else
        if InputParameters.Results.TuningMode
            disp('Setup bypassed');
        end
    end
    
    if nargout > 0
        HelperData = [];
        for fn = HelperFieldNames
            HelperData.(fn{1}) = UserData.PrivateMapInfo.(fn{1});
        end
        return
    end
    
    if InputParameters.Results.TuningMode
        fprintf(1,'Start Interpolating: %f\n',toc);
    end

    UserData.PrivateMapInfo.imap = griddata(UserData.PrivateMapInfo.ElectrodesOnPlaneX,UserData.PrivateMapInfo.ElectrodesOnPlaneY,UserData.PrivateMapInfo.InterpolationMatrix*map,UserData.PrivateMapInfo.XGrid2D,UserData.PrivateMapInfo.YGrid2D,'cubic');
    UserData.PrivateMapInfo.imap(~UserData.PrivateMapInfo.InHull) = nan;
    if ~isempty(UserData.PrivateMapInfo.tMap)
        UserData.PrivateMapInfo.itmap = griddata(UserData.PrivateMapInfo.ElectrodesOnPlaneX,UserData.PrivateMapInfo.ElectrodesOnPlaneY,UserData.PrivateMapInfo.InterpolationMatrix*UserData.PrivateMapInfo.tMap,UserData.PrivateMapInfo.XGrid2D,UserData.PrivateMapInfo.YGrid2D,'cubic');
        UserData.PrivateMapInfo.itmap(~UserData.PrivateMapInfo.InHull) = nan;
    end
    
    if InputParameters.Results.TuningMode
        fprintf(1,'Done Interpolating: %f\n',toc);
    end

    UserData.PrivateMapInfo.nLevels = ceil(max(abs(UserData.PrivateMapInfo.imap(:))) / InputParameters.Results.Step) +1;
    if isnan(UserData.PrivateMapInfo.nLevels)
        UserData.PrivateMapInfo.nLevels = 3;
    end
    UserData.PrivateMapInfo.Levels = ((-UserData.PrivateMapInfo.nLevels) * InputParameters.Results.Step):InputParameters.Results.Step:((UserData.PrivateMapInfo.nLevels)*InputParameters.Results.Step);

    UserData.PrivateMapInfo.ShowTValues = false;
%    FindPositionInUIFigure(InputParameters.Results.Axis)
  
    if InputParameters.Results.MenuButton && ~isfield(UserData.PrivateMapInfo,'Button')
        if isa(FigureToUse,'matlab.ui.Figure')
            UserData.PrivateMapInfo.Button = uibutton('Parent',AxisToUse,'Position',[10 10 20 20],'Text','...');
        else
            UserData.PrivateMapInfo.Button = uicontrol('Parent',FigureToUse,'Style','pushbutton','Units','normalized','Position',[0.1 0.1 0.1 0.1],'String','...');
        end
    end
    
    
   if isa(FigureToUse,'matlab.ui.Figure')
       UIAxesZoom = zoom(AxisToUse);
       setAllowAxesZoom(UIAxesZoom,AxisToUse,1);
   end
    %   UserData.PrivateMapInfo.Button = uibutton(PlotAxis.Parent,'Position',[0 0 0.05 0.05]);
    AxisToUse.UserData.PrivateMapInfo = UserData.PrivateMapInfo;
    
    if InputParameters.Results.TuningMode
        fprintf(1,'Ready to plot: %f\n',toc); %#ok<*UNRCH>
    end
    
    
%    AxisToUse.Toolbar.Visible = 'off';
%    AxisToUse.Interactions = [];
    
    if UserData.PrivateMapInfo.Show3D == false
        Show2DMap([],[],AxisToUse);
    else
        Show3DMap([],[],AxisToUse);
    end
end

function Show2DMap(~,~,PlotAxis)
    
    cla(PlotAxis);
    
    ud = PlotAxis.UserData.PrivateMapInfo;
    
    if ud.ShowTValues == false       
        MapToShow = ud.imap;
    else
        MapToShow = ud.itmap;
    end

%    if any(isnan(MapToShow))
%        MapToShow = zeros(size(MapToShow));
%    end


    if ud.ContourLines == true
        contourf(PlotAxis,ud.XGrid2D,ud.YGrid2D,MapToShow,ud.Levels,'LineWidth',ud.MapLineWidth);
    else
        surf(PlotAxis,ud.XGrid2D,ud.YGrid2D,MapToShow);
        view(PlotAxis,2);
        shading(PlotAxis,'interp'); 
    end
    hold(PlotAxis,'on');

    if ~isempty(ud.ShowPosition)
        plot3(PlotAxis,ud.ElectrodesToPlotX,ud.ElectrodesToPlotY,ones(size(ud.ElectrodesToPlotX)),'.k');
        
        if iscell(ud.ShowPosition)
            text(PlotAxis,ud.ElectrodesToPlotX,ud.ElectrodesToPlotY,ones(size(ud.ElectrodesToPlotX)),ud.ShowPosition);
        end
    end    

    caxis(PlotAxis,[ud.Levels(1) ud.Levels(end)]);
    colormap(PlotAxis,bluered(ud.nLevels*2));
    plot(PlotAxis,ud.NewHullEdgesX,ud.NewHullEdgesY,'-k','LineWidth',ud.MapLineWidth*2);
    hold(PlotAxis,'off');
    axis(PlotAxis,'equal');
    if isempty(ud.Background)
        axis(PlotAxis,'off');
    else
        set(PlotAxis,'xtick',[],'ytick',[],'xticklabel',[],'yticklabel',[],'Color',ud.Background);
    end 
    ud.Show3D = false;
    PlotAxis.UserData.PrivateMapInfo = ud;
    ShowTitle(PlotAxis);
    PlotAxis.PlotBoxAspectRatio = [1,1,1];
    PlotAxis.PlotBoxAspectRatioMode = 'manual';    
    UpdateTheContextMenu(PlotAxis);

end


function Show3DMap(~,~,PlotAxis)
    cla(PlotAxis);

    hold(PlotAxis,'on');

    ud = PlotAxis.UserData.PrivateMapInfo;
    
    [mx,my,mz] = Planar2Sphere(ud.XGrid2D,ud.YGrid2D,1.00);
    c = [];
    
    if ud.ShowTValues == false       
        if ud.ContourLines == true
            c = contourc(ud.XAxis2DGrid,ud.YAxis2DGrid,ud.imap,ud.Levels);
        end
        surfhandle = surf(PlotAxis,mx,my,mz,ud.imap,'BackFaceLighting','unlit');
    else
        if ud.ContourLines == true
            c = contourc(ud.XAxis2DGrid,ud.YAxis2DGrid,ud.itmap,ud.Levels);
        end
        surfhandle = surf(PlotAxis,mx,my,mz,ud.itmap,'BackFaceLighting','unlit');
    end
        

    caxis(PlotAxis,[ud.Levels(1) ud.Levels(end)]);
    colormap(PlotAxis,bluered(ud.nLevels*2));

    shading(PlotAxis,'interp');

    idx = 1;
    while(idx < size(c,2))
%        clevel = c(1,idx);
        npts   = c(2,idx);
        idx    = idx + 1;
        cx     = c(1,idx: (idx + npts-1));
        cy     = c(2,idx: (idx + npts-1));
        [px,py,pz]     = Planar2Sphere(cx,cy,1.00);
        idx = idx + npts;
        plot3(PlotAxis,px,py,pz,'-k','LineWidth',ud.MapLineWidth);
    end
    [HullX,HullY,HullZ] = Planar2Sphere(ud.NewHullEdgesX,ud.NewHullEdgesY);
    plot3(PlotAxis,HullX,HullY,HullZ,'-k','LineWidth',ud.MapLineWidth*4);
    hold(PlotAxis,'off');
    axis(PlotAxis,'equal');
    axis(PlotAxis,'off');


    ShowEye(PlotAxis,-0.3,0.70,-0.5,0.2);
    ShowEye(PlotAxis, 0.3,0.70,-0.5,0.2);
    
    if ud.Show3D == false
        SetView([],[],PlotAxis, 127.5,30);
    end
    ud.Show3D = true;
    
    PlotAxis.UserData.PrivateMapInfo = ud;
    axis(PlotAxis,'vis3d');
    material(surfhandle,'dull');
    light(PlotAxis);
    ShowTitle(PlotAxis);
    PlotAxis.PlotBoxAspectRatio = [1,1,1];
    PlotAxis.PlotBoxAspectRatioMode = 'manual';
    UpdateTheContextMenu(PlotAxis);
end

function ShowTitle(PlotAxis)
    if ~isempty(PlotAxis.UserData.PrivateMapInfo.Title)
        PlotAxis.Title.Visible = 'on';
        PlotAxis.Title.Interpreter = 'none';
        PlotAxis.Title.String = PlotAxis.UserData.PrivateMapInfo.Title;
    else
        PlotAxis.Title.Visible = 'off';
    end
end

function OpenMyContextMenu(obj,event)
    CurrentPoint = obj.Parent.CurrentPoint;
    open(obj,[CurrentPoint(1),CurrentPoint(2)]);
end

function UpdateTheContextMenu(PlotAxis)
   if ~isempty(PlotAxis.UserData.PrivateMapInfo.FigureHandle) 
      
       ContextMenu = uicontextmenu(PlotAxis.UserData.PrivateMapInfo.FigureHandle);
    else
       ContextMenu = uicontextmenu(PlotAxis.Parent);
   end

    ContextMenu.ContextMenuOpeningFcn = @OpenMyContextMenu;
    if PlotAxis.UserData.PrivateMapInfo.Show3D == false
        uimenu(ContextMenu, 'Label', 'Plot 3D map',             'Callback', {@Show3DMap,PlotAxis});
    else
        uimenu(ContextMenu, 'Label', 'Plot 2D map',             'Callback', {@Show2DMap,PlotAxis});
    end
    if ~isempty(PlotAxis.UserData.PrivateMapInfo.tMap)
        if PlotAxis.UserData.PrivateMapInfo.ShowTValues == true
            uimenu(ContextMenu, 'Label', 'Show t-value',             'Callback', {@SwitchToTMap,PlotAxis,false}, 'Checked','on', 'Separator','on');
        else
            uimenu(ContextMenu, 'Label', 'Show t-value',             'Callback', {@SwitchToTMap,PlotAxis,true}, 'Checked','off');
        end
    end
    if PlotAxis.UserData.PrivateMapInfo.Show3D == true

        uimenu(ContextMenu, 'Label', 'Free rotation',  'Callback', {@FreeRotate, PlotAxis}, 'Separator','on');
        uimenu(ContextMenu, 'Label', 'Left view',  'Callback', {@SetView, PlotAxis,-90, 0}, 'Separator','on');
        uimenu(ContextMenu, 'Label', 'Right view', 'Callback', {@SetView, PlotAxis, 90, 0});
        uimenu(ContextMenu, 'Label', 'Front view', 'Callback', {@SetView, PlotAxis,180, 0});
        uimenu(ContextMenu, 'Label', 'Back view',  'Callback', {@SetView, PlotAxis,  0, 0});
        uimenu(ContextMenu, 'Label', 'Top view',   'Callback', {@SetView, PlotAxis,  0,90});

        uimenu(ContextMenu, 'Label', 'Left back view',  'Callback',{@SetView, PlotAxis,- 37.5,30}, 'Separator','on');
        uimenu(ContextMenu, 'Label', 'Right back view', 'Callback',{@SetView, PlotAxis,  37.5,30});
        uimenu(ContextMenu, 'Label', 'Left front view', 'Callback',{@SetView, PlotAxis,-127.5,30});
        uimenu(ContextMenu, 'Label', 'Right front view','Callback',{@SetView, PlotAxis, 127.5,30});

        uimenu(ContextMenu,'Label', 'Light from left', 'Separator','on','Callback', {@CamlightCallback,PlotAxis,'Left'});
        uimenu(ContextMenu,'Label', 'Light from right',                 'Callback', {@CamlightCallback,PlotAxis,'Right'});
        uimenu(ContextMenu,'Label', 'No lights', 'Callback',{@DeleteLights,PlotAxis});

        uimenu(ContextMenu,'Label', 'Look at me', 'Separator','on','Callback',{@LookAtMe,PlotAxis});
        uimenu(ContextMenu,'Label', 'Blue eyes', 'Separator','on','Callback',{@EyeColor,PlotAxis,[0.2 0.2 1]});
        uimenu(ContextMenu,'Label', 'Brown eyes','Callback',{@EyeColor,PlotAxis,[153/255 76/255 0]});
        uimenu(ContextMenu,'Label', 'Zoom','Callback',{@ZoomOut,PlotAxis}, 'Separator','on');
    end
    if isfield(PlotAxis.UserData.PrivateMapInfo,'Button')
        if isa(PlotAxis.UserData.PrivateMapInfo.FigureHandle,'matlab.ui.Figure')
            PlotAxis.UserData.PrivateMapInfo.Button.ButtonPushedFcn = {@ButtonOpenContextMenu,PlotAxis.UserData.PrivateMapInfo.FigureHandle, ContextMenu};
        else
            PlotAxis.UserData.PrivateMapInfo.Button.Callback = {@ButtonOpenContextMenu,PlotAxis.UserData.PrivateMapInfo.FigureHandle, ContextMenu};
        end
    else
        AddContextMenu(PlotAxis,ContextMenu);
    end
end

function AddContextMenu(obj,cm)
    %obj
    %class(obj.Parent.Parent.Parent.Parent.Parent)
    cm.Parent = ancestor(obj,'matlab.ui.Figure','toplevel');
    if isprop(obj,'ContextMenu')
        obj.ContextMenu = cm;
    elseif isprop(obj,'uicontextmenu')
        obj.uicontextmenu = cm;
    end
    
    children = obj.Children;
    for kid = 1:numel(children)
        AddContextMenu(children(kid),cm);
  %      children(kid).HitTest = 'off';

    end
end

function ZoomOut(~,~,Axis)
    NewFigure = figure;
    NewAxes = axes(NewFigure);
    NewAxes.UserData = Axis.UserData;
    if isfield(NewAxes.UserData.PrivateMapInfo,'Button')
        NewAxes.UserData.PrivateMapInfo = rmfield(NewAxes.UserData.PrivateMapInfo,'Button');
    end
    NewAxes.UserData.PrivateMapInfo.FigureHandle = NewFigure;
    if Axis.UserData.PrivateMapInfo.Show3D
        [az,el] = view(Axis);
        Show3DMap([],[],NewAxes);
        view(NewAxes,az,el);
    else
        Show2DMap([],[],NewAxes);
    end

end
        
function SetView(~,~,Axis,azimut,elevation)
    view(Axis,azimut,elevation);
end

function FreeRotate(obj,~,Axis)
    h = rotate3d(Axis);

    switch(h.Enable)
        case 'on'
            disp('on->off');
            obj.Checked = 'off';
            h.Enable = 'off';
            Axis.Toolbar.Visible = 'off';
        case 'off'
            disp('off->on');
            obj.Checked = 'on';
            h.Enable = 'on';
            Axis.Toolbar.Visible = 'off';
    end
end




function CamlightCallback(~,~,Axis,Direction)
    camlight(Axis,Direction,'infinite');
end

function DeleteLights(~,~,Axis)
    delete(findall(Axis,'Type','light'));
end

function ButtonOpenContextMenu(obj,event, FigureHandle, TheMenu)
    CurrentPoint = FigureHandle.CurrentPoint;
    open(TheMenu,[CurrentPoint(1),CurrentPoint(2)]);
end


function OpenContextMenu(obj,event, FigureHandle)
    
    CurrentPoint = FigureHandle.CurrentPoint;
    open(obj.ContextMenu,[CurrentPoint(1),CurrentPoint(2)]);
end


function SwitchToTMap(~,~,PlotAxis,DoT)
    PlotAxis.UserData.PrivateMapInfo.ShowTValues = DoT;
    if PlotAxis.UserData.PrivateMapInfo.Show3D
        Show3DMap([],[],PlotAxis);
    else
        Show2DMap([],[],PlotAxis);
    end

end

function ShowEye(Axis,xpos,ypos,zpos,rad)
    [x,z,y] = sphere(100);
    [i1,j1] = find(y > 0.7);
    [i2,j2] = find(y > 0.9);
    [i3,j3] = find(y > 0.7 & y <= 0.9);
    x = x*rad + xpos;
    y = y*rad + ypos;
    z = z*rad + zpos;
    c = ones(size(x,1),size(x,2),3)-0.08;

    c(i1,j1,1) = 0.2;
    c(i1,j1,2) = 0.2;
    c(i1,j1,3) = 1;

    c(i2,j2,:) = 0;

    ud.pos = [xpos ypos zpos];
    ud.icol = i3;
    ud.jcol = j3;
    ud.dir = [180 0];
    surface(Axis,x,y,z,c,'EdgeColor','none','Tag','Eye','UserData',ud);
end

function LookAtMe(~,~,Axis)

    eyeh = findall(Axis,'Tag','Eye');


    for i = 1:numel(eyeh)
        ud = get(eyeh(i),'UserData');
        [az,el] = view(Axis);

        vert  = abs(180-az);
        horiz = el;
         
        if vert < 50 && horiz < 45 && horiz > -60
            disp('normal')
            rotate(eyeh(i),[0 0 1],az-ud.dir(1),ud.pos);
            rotate(eyeh(i),[1 0 0],el-ud.dir(2),ud.pos);
        else
            disp('abnormal')
%            rotate(eyeh(i),[0 0 1],150-ud.dir(1),ud.pos);
%            rotate(eyeh(i),[1 0 0],  0-ud.dir(2),ud.pos);

            
        end
            
        ud.dir(1) = az;
        ud.dir(2) = el;
        set(eyeh(i),'UserData',ud);
    end

end

function EyeColor(~,~,figh,col)

    eyeh = findall(figh,'Tag','Eye');

    for i = 1:numel(eyeh)
        ud = get(eyeh(i),'UserData');
    
        c = get(eyeh(i),'CData');
        c(ud.icol,ud.jcol,1) = col(1);
        c(ud.icol,ud.jcol,2) = col(2);
        c(ud.icol,ud.jcol,3) = col(3);
        set(eyeh(i),'CData',c);
    end

end


