function [d] = dirrh(str,pth)
%calls itself recursively to find all files
if nargin<2||isempty(pth),pth=cd;end
d = dir(fullfile(pth,str));
alld = dir(fullfile(pth,'*.*'));
for ct = 3:length(alld)
    if alld(ct).isdir
        [d] = [d, dirrh(str,fullfile(pth,alld(ct).name))];
    end
end