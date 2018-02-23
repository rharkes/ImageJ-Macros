function [t,U,param]=PLW2MLv5(fullfilename,info)
% PLW2ML converts PLW-files (PicoTech Picologger) to MATLAB variables
% [t,U,param]=PLW2ML(filename,info)
% filename is the full filename (with path and extension .plw)
% info is an optional parameter that if set to 1 displays
% information about the file being read
% t is the time vector
% U is the output (voltage, temperature etc. vector/matrix)
% param is a structure containing other information,
% for example param.PLS is a settings file (first part is strange)
%
% A typical use of the plw2ml function is as follows:
%
% [t,U]=plw2ml('c:\measure2\rotfungi\sl0921A.plw');
% plot(t,U(:,1))
%
% A more advanced way is to use it on all files of a certain sort,
% for example to plot the data in all files starting with 'sl' in one directory:
%
% presdir=cd; %present directory
% dirvec=dir; %Find all filenames in directory
% for k=1:length(dirvec) %go through all files
% filename=dirvec(k).name; %put filename in filename-string
% if length(filename)>5 % do not evaluate '-' '--' and other strange things in dirvec
% if strcmp(filename(1:2),'SL') %only if it is a SLXXXX- file
% fullfilename=[presdir,'\',filename]; %full filename, incl. path
% [t,U]=PLW2ML(fullfilename);
% plot(t,U);
% end
% end
% end
%
% An even more automated evaluation method can be made by looking up,
% e.g., sample identifiers in the param.PLS-variable (if they have
% been entered into PLW before the start of the measurements). In the
% following example samples (channels) are named HDMXX, where XX is a
% sample number that the program finds and uses to sort the measurements
%
% k=k+1;
% indstart=findstr('MultiConverter',param.PLS); %---Find line before channel identifier
% indname=findstr('HDM',param.PLS(indstart:end)); %---In this example sample numbers follow HDM-string
% %find all places in PLS-file starting with 'Name=HDM' (that are followed by the sample number)
% for p=1:length(indname) %for all measurements found in the file
% sample_no(k)=str2num(param.PLS(indstart+indname(p)+2:indstart+indname(p)+3)); %extract sample number
% end
%
% Lars Wadsö, Building Materials, Lund University, Sweden 28 Oct 2004
% James Mack, Applied Materials, United States, 28 Jan 2014
% krisk, 18 Apr 2015

if nargout<2|nargout>3;error('PLW2ML needs two or three output arguments [t,U] or [t,U,param]');end
if nargin==0;[fn,pn]=uigetfile('*.*','Open a measurement file');fullfilename=[pn,fn];info=0;end
if nargin==1;info=0;end
if fullfilename(end-3:end)~='.plw' & fullfilename(end-3:end)~='.PLW';error('PLW2ML can only open files with extension .plw or .PLW');end
fid=fopen(fullfilename); %open file for reading
if fid==-1;error('File could not be opened');end
param.header_bytes=fread(fid,1,'ushort'); %read first line of PLW-HEADER (the end of the file contains a partial explanation of how a PLW file is built up)
param.signature=char(fread(fid,40,'uchar'))'; %etc
param.version=fread(fid,1,'uint32');

if info;disp(['PLW file version ',int2str(param.version)]);end
switch param.version
    case 1
        antal_parametrar=50;
        antal_notes=200;
        antal_spare = 78;
    case 2
        antal_parametrar=50; %100;
        antal_notes=200;
        antal_spare = 78;
    case 3
        antal_parametrar=250;
        antal_notes=1000;
        antal_spare = 78;
    case 4
        antal_parametrar=250;
        antal_notes=1000;
        antal_spare = 78;
    case 5
        antal_parametrar=250;
        antal_notes=1000;
        antal_spare = 58;
end
param.no_of_parameters=fread(fid,1,'uint32');
if info;disp(['Number of parameters ',int2str(param.no_of_parameters)]);end
param.parameters=fread(fid,antal_parametrar,'uint16'); %says 50 in PLW manual
if info;disp(['Parameters: ',int2str(param.parameters(1:param.no_of_parameters)')]);end
% param.sample_no=0;
% while param.sample_no==0
param.sample_no=fread(fid,1,'uint32'); %=following
% end
if info;disp(['Number of samples: ',int2str(param.sample_no)]);end
param.no_of_samples=fread(fid,1,'uint32'); %=previous %number of samples
if info;disp(['No OF SAMPLES: ',int2str(param.no_of_samples)]);end
param.max_samples=fread(fid,1,'uint32');
if info;disp(['MAX Number of samples: ',int2str(param.max_samples)]);end
param.interval=fread(fid,1,'uint32'); %measurement interval
if info;disp(['Interval: ',int2str(param.interval)]);end
param.interval_units=fread(fid,1,'uint16'); %interval units
if info;disp(['Interval_units: ',int2str(param.interval_units)]);end
switch param.interval_units
    case 0;units=' fs';
    case 1;units=' ps';
    case 2;units=' ns';
    case 3;units=' us';
    case 4;units=' ms';
    case 5;units=' s';
    case 6;units=' min';
    case 7;units=' h';
    otherwise;units=' with unknown unit';
end
param.units_string = units;
if info;disp(['Sampling interval: ',num2str(param.interval),units]);end
param.trigger_sample=fread(fid,1,'uint32');
param.triggered=fread(fid,1,'uint16');
param.first_sample=fread(fid,1,'uint32');
param.sample_bytes=fread(fid,1,'uint32');
param.settings_bytes=fread(fid,1,'uint32');
param.start_date=fread(fid,1,'uint32'); %start date (days since start of year 0)
if info;disp(['Start date (days since 1 jan year 0) ',int2str(param.start_date)]);end
param.start_time=fread(fid,1,'uint32'); %start time (seconds since start of day)
if info;disp(['Start time (secondas since beginning of day) ',int2str(param.start_time)]);end
param.minimum_time=fread(fid,1,'int32');
param.maximum_time=fread(fid,1,'int32');
param.notes=fread(fid,antal_notes,'uchar')';
param.current_time=fread(fid,1,'int32');
if param.version == 5 % Additional parameters in version 5 not present in other versions
   param.stopAfter = fread(fid,1,'uint16');
   param.maxTimeUnit = fread(fid,1,'uint16');
   param.maxSampleTime = fread(fid,1,'uint32');
   param.startTimeMsAccuracy = fread(fid,1,'uint32');
   param.previousTimeMsAccuracy = fread(fid,1,'uint32');
   param.noOfDays = fread(fid,1,'uint32');
end

param.spare=fread(fid,antal_spare,'uint8');
%read DATA
nr = param.no_of_parameters + 1;
nc = param.no_of_samples;
raw = reshape( fread( fid, nr * nc, 'float=>float' ), [nr nc] );
t = double( typecast( raw( 1, : ), 'uint32' ) );
U = double( raw( 2:end, : ) );

%read PLS-file appended at end of PLW-file (see the end of this file for an explanation)
param.PLS=fread(fid,inf,'*char')'; %here the PLS-file is read (the first part contains strange text)


% % % % % % [starti, endi] = regexp(str,'\[Parameter \d*\]')
% % % % % % [starti, endi] = regexp(str,'\[Parameter \d*\].*?Name=.*?\r\n')

channelLabels = cell(param.no_of_parameters,1);

% Pull out the parameter number (first token) and channel label (second
% token)
[tkns starti endi] = regexp(param.PLS,'\[Parameter (\d*)\].*?Name=(.*?)\r\n','tokens');
for k = 1:length(tkns)
    % This will cycle through all parameters listed in the settings
    % appended to the end of the PLW file, and place in the proper place in
    % the channel label array.  Some PLW files have a fragment that is
    % repeated in the beginning, so any labels from this fragment will be
    % overwritten when the main block is read
   paramNum = str2double(tkns{k}{1});
   channelLabels{paramNum} = tkns{k}{2};
end

param.channelLabels = channelLabels;

if info;disp('The param.PLS file with infomation about the run can be retreived from a third output argument');end
fclose(fid); %close file
end