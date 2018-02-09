classdef spect    
    properties
        filename
        data
    end
    
    methods
        function obj = spect(filename)
            if nargin<1,[f,p]=uigetfile('.txt');filename=[p,f];end
            if isempty(regexp(filename,'\w:\', 'once')),filename=[cd,filesep,filename];end
            if exist(filename,'file')==2
                obj.filename=filename;
                fid=fopen(filename,'r');
                l = fgetl(fid);
                while isempty(l)||~isempty(regexp(l,'[^\d|\s|.]'))
                    l = fgetl(fid);
                end
                while ~isnumeric(l)
                    obj.data(end+1,:)=str2double(strsplit(l,'\t'));
                    l = fgetl(fid);
                end
                fclose(fid);
            end
        end
        function plot(obj,varargin)
            plot(obj.data(:,1),obj.data(:,2),varargin{:})
        end
        
    end
end