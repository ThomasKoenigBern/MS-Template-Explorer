function varargout = SetXYZCoordinates(varargin)
% SETXYZCOORDINATES M-file for SetXYZCoordinates.fig
%      SETXYZCOORDINATES, by itself, creates a new SETXYZCOORDINATES or raises the existing
%      singleton*.
%
%      H = SETXYZCOORDINATES returns the handle to a new SETXYZCOORDINATES or the handle to
%      the existing singleton*.
%
%      SETXYZCOORDINATES('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SETXYZCOORDINATES.M with the given input arguments.
%
%      SETXYZCOORDINATES('Property','Value',...) creates a new SETXYZCOORDINATES or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SetXYZCoordinates_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SetXYZCoordinates_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SetXYZCoordinates

% Last Modified by GUIDE v2.5 27-Jun-2013 17:26:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SetXYZCoordinates_OpeningFcn, ...
                   'gui_OutputFcn',  @SetXYZCoordinates_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before SetXYZCoordinates is made visible.
function SetXYZCoordinates_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SetXYZCoordinates (see VARARGIN)

% Choose default command line output for SetXYZCoordinates

handles.output = hObject;
set(handles.TopView,'UserData',varargin{4});
guidata(hObject, handles);
set(handles.output,'UserData',varargin{4});

set(handles.PopupOrientation,'Value',1);

set(handles.rbLeftNeg,'parent',handles.ButtonGroupLR,'UserData',1);
set(handles.rbLeftPos,'parent',handles.ButtonGroupLR,'UserData',-1);
set(handles.ButtonGroupLR,'SelectionChangeFcn',{@ButtonGroup_SelectionChanged,handles},'UserData',1);

set(handles.rbAntNeg,'parent',handles.ButtonGroupAP,'UserData',1);
set(handles.rbAntPos,'parent',handles.ButtonGroupAP,'UserData',-1);
set(handles.ButtonGroupAP,'SelectionChangeFcn',{@ButtonGroup_SelectionChanged,handles},'UserData',1);

set(handles.rbSupNeg,'parent',handles.ButtonGroupSI,'UserData',1);
set(handles.rbSupPos,'parent',handles.ButtonGroupSI,'UserData',-1);
set(handles.ButtonGroupSI,'SelectionChangeFcn',{@ButtonGroup_SelectionChanged,handles},'UserData',1);

DisplayCoordinates(handles);
% Update handles structure


% UIWAIT makes SetXYZCoordinates wait for user response (see UIRESUME)
uiwait(handles.figure1);


function DisplayCoordinates(handles)

Coords = get(handles.output,'UserData');

xdir = get(handles.ButtonGroupLR,'UserData');
ydir = get(handles.ButtonGroupAP,'UserData');
zdir = get(handles.ButtonGroupSI,'UserData');

switch(get(handles.PopupOrientation,'Value'));
    case 1 %LR - AP - SI
        Coords.x = Coords.pos(:,1) * xdir;
        Coords.y = Coords.pos(:,2) * ydir;
        Coords.z = Coords.pos(:,3) * zdir;
    case 2 % LR - SI - AP
        Coords.x = Coords.pos(:,1) * xdir;
        Coords.z = Coords.pos(:,2) * zdir;
        Coords.y = Coords.pos(:,3) * ydir;

    case 3 % AP - LR - SI
        Coords.y = Coords.pos(:,1) * ydir;
        Coords.x = Coords.pos(:,2) * xdir;
        Coords.z = Coords.pos(:,3) * zdir;

    case 4 % AP - SI - LR
        Coords.y = Coords.pos(:,1) * ydir;
        Coords.z = Coords.pos(:,2) * zdir;
        Coords.x = Coords.pos(:,3) * xdir;

    case 5 % SI - AP - LR
        Coords.z = Coords.pos(:,1) * zdir;
        Coords.y = Coords.pos(:,2) * ydir;
        Coords.x = Coords.pos(:,3) * xdir;

    case 6 % SI - LR - AP
        Coords.z = Coords.pos(:,1) * zdir;
        Coords.x = Coords.pos(:,2) * xdir;
        Coords.y = Coords.pos(:,3) * ydir;
end

mx = max(abs(Coords.pos(:)))* 1.1;

set(handles.output,'UserData',Coords);

axes(handles.TopView);

plot(Coords.x,Coords.y,'.w');
text(Coords.x,Coords.y,Coords.lbl,'HorizontalAlignment','center','BackgroundColor','none','FontSize',8);
axis([-mx mx -mx mx]);
title('Top View');
xlabel('left <-> right');
ylabel('posterior <-> anterior');

idx = Coords.x >= 0;

axes(handles.LeftView);
plot(Coords.y(idx),Coords.z(idx),'.w');
text(Coords.y(idx),Coords.z(idx),Coords.lbl(idx),'HorizontalAlignment','center','BackgroundColor','none','FontSize',8);
axis([-mx mx -mx mx]);
title('Right View');
xlabel('posterior <-> anterior');
ylabel('inferior <-> superior');

% --- Outputs from this function are returned to the command line.
function varargout = SetXYZCoordinates_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure

if isempty(handles)
    varargout{1} = [];
else
    varargout{1} = handles.output;
end


% --- Executes on selection change in PopupOrientation.
function PopupOrientation_Callback(hObject, eventdata, handles)
% hObject    handle to PopupOrientation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns PopupOrientation contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PopupOrientation
DisplayCoordinates(handles);


% --- Executes during object creation, after setting all properties.
function PopupOrientation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PopupOrientation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function ButtonGroup_SelectionChanged(hObject, eventdata, handles)
% hObject    handle to ButtonGroupLR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject,'UserData',get(eventdata.NewValue,'UserData'));
DisplayCoordinates(handles);


% --- Executes on mouse press over figure background.
function figure1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbuttonOK.
function pushbuttonOK_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonOK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiresume(handles.figure1);
