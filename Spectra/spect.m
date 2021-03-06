classdef spect
    properties
        filename
        header
        data
    end
    
    methods
        function obj = spect(filename)
            if nargin<1,[f,p]=uigetfile('.csv');filename=[p,f];end
            if isempty(regexp(filename,'\w:\', 'once')),filename=[cd,filesep,filename];end
            if ~exist(filename,'file'),error('file does not exist');end
            obj.filename=filename;
            fid=fopen(filename,'r');
            l = fgetl(fid); %read header
            obj.header = strsplit(l,',');
            if isempty(obj.header{end}),obj.header(end)=[];end
            l = fgetl(fid); %read data
            while ~isnumeric(l)
                d = strsplit(l,',','CollapseDelimiters',false);
                d = d(1:length(obj.header));
                obj.data(end+1,:)=str2double(d);
                l = fgetl(fid);
            end
            fclose(fid);
        end
        function plot(obj,varargin)
            f=figure(1);clf;hold on;
            for ct = 2:length(obj.header)
                plot(obj.data(:,1),obj.data(:,ct),varargin{:})
            end
            legend(obj.header{end:-1:2});
        end
        
    end
end