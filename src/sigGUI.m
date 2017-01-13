function varargout = sigGUI(varargin)
% SIGGUI MATLAB code for sigGUI.fig
%      SIGGUI, by itself, creates a new SIGGUI or raises the existing
%      singleton*.
%
%      H = SIGGUI returns the handle to a new SIGGUI or the handle to
%      the existing singleton*.
%
%      SIGGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SIGGUI.M with the given input arguments.
%
%      SIGGUI('Property','Value',...) creates a new SIGGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before sigGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to sigGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help sigGUI

% Last Modified by GUIDE v2.5 13-Jan-2017 13:09:07

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @sigGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @sigGUI_OutputFcn, ...
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


% --- Executes just before sigGUI is made visible.
function sigGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to sigGUI (see VARARGIN)

% Choose default command line output for sigGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes sigGUI wait for user response (see UIRESUME)
% uiwait(handles.signaturegui);


% --- Outputs from this function are returned to the command line.
function varargout = sigGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton.
function pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
address = gcs;
numChars = strfind(address, '/');

if ~isempty(numChars)
    address = address(1:numChars(1) - 1);
end

% Get all the group's children. Get their values and put into a matrix.
% Flip it so that it matches the GUI order. Find the index of the radio
% button that is selected (value is nonzero. Minus 1 becuase the function 
% takes 0,1,2 instead of 1,2,3.
docType = find(flipud(cell2mat(get(get(handles.group_DocType, 'Children'), 'Value')))) - 1;

if get(handles.radio_strongsig, 'Value')
    StrongSignature(address, ~get(handles.radio_model, 'Value'), get(handles.radio_enableupdate, 'Value'), 'All', docType);
else
    WeakSignature(address, ~get(handles.radio_model, 'Value'), get(handles.radio_enableupdate, 'Value'), 'All', docType);
end

close(handles.signaturegui);

% --- Executes during object creation, after setting all properties.
function signaturegui_CreateFcn(hObject, eventdata, handles)
% hObject    handle to signaturegui (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes when selected object is changed in uipanel2.
function uipanel2_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel2 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

% Enable/disable Documentation Type radio buttons based on whether or not
% the user wants the signature in the model or as documentation
if get(handles.radio_model, 'Value')
    set(handles.radio_txt, 'Enable', 'off');
    set(handles.radio_tex, 'Enable', 'off');
    set(handles.radio_doc, 'Enable', 'off');
else
    set(handles.radio_txt, 'Enable', 'on');
    set(handles.radio_tex, 'Enable', 'on');
    set(handles.radio_doc, 'Enable', 'on');
end
