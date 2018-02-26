classdef fcsfile
    %FLIFILE - a handle to open fcsfiles
    % example: F=fcsfile('data.fcs');
    
    properties
        filename %full filename
        fid      %file identifier
        version  %header segment
        offset   %offsets
        text     %text segment
        NrParam  %nr of parameters
        NrEvent  %nr of events
        Params   %name of events
        data     %all data
    end
    
    methods
        function obj = fcsfile(filename)
            if nargin<1,[f,p] = uigetfile('*.fcs','Select FCS File');filename = fullfile(p,f);end
            if ~strcmp(filename(end-3:end),'.fcs'),filename=[filename,'.fcs'];end
            if ~exist(filename,'file')
                error('cannot find file')
            else
                obj.fid = fopen(filename,'r','b');
            end
            obj.filename = filename;
            [obj.offset,obj.version]=obj.getoffsets(obj.fid);
            fseek(obj.fid,obj.offset(1),-1);
            obj.text=fread(obj.fid,obj.offset(2)-obj.offset(1),'uint8=>char')';
            [obj.NrParam,obj.NrEvent,obj.Params]=obj.analysetext(obj.text); %could be doing something with this, but data is just 32-bit floats
            fseek(obj.fid,obj.offset(3),-1);
            obj.data=fread(obj.fid,(obj.offset(4)-obj.offset(3))/4,'*single')';
            obj.data = reshape(obj.data,[obj.NrParam,obj.NrEvent]);
            fclose(obj.fid);            
        end
    end
    methods(Static) 
        function [nP,nE,N] = analysetext(input)
            byteo = regexp(input,'\$BYTEORD\f[^\f]*','match');
            datatype = regexp(input,'\$DATATYPE\f[^\f]*','match');
            B = regexp(input,'\$P\d*B\f[^\f]*','match');
            E = regexp(input,'\$P\d*E\f[^\f]*','match');
            N = regexp(input,'\$P\d*N\f[^\f]*','match');
            N = regexp(N,'\f','split');
            for ct = 1:length(N)
                N{ct} = N{ct}{2};
            end
            R = regexp(input,'\$P\d*R\f[^\f]*','match');
            TOT = regexp(input,'\$TOT\f[^\f]*','match');
            TOT = regexp(TOT{:},'\f','split');
            nE = sscanf(TOT{2},'%lu');
            PAR = regexp(input,'\$PAR\f[^\f]*','match');
            PAR = regexp(PAR{:},'\f','split');
            nP = sscanf(PAR{2},'%lu');
        end
       
        function [offset, version] = getoffsets(fid)
            fseek(fid,0,-1);
            version = fread(fid,1,'uint8=>char');
            char = fread(fid,1,'uint8=>char');
            while ~strcmp(char,' ')
                version = [version,char];
                char = fread(fid,1,'uint8=>char');
            end
            ct = 1;E=false;offset='';
            while strcmp(char,' ')
                char = fread(fid,1,'uint8=>char');
            end
            while ct<6
                while strcmp(char,' ')
                    E=true;
                    char = fread(fid,1,'uint8=>char');
                end
                if E,E=false;ct=ct+1;offset=[offset,';'];end
                offset = [offset,char];
                char = fread(fid,1,'uint8=>char');
            end
            offset=sscanf(offset,'%lu;%lu;%lu;%lu;%lu;%lu')';
        end
    end
end

