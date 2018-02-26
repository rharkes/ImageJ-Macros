function []=makeLOG(L)
if nargin<1||isempty(L),L=0;end
ax = gca;
%reset to normal
set(ax, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
set(ax, 'YTickMode', 'auto', 'YTickLabelMode', 'auto')

%make labels integers
XTick = ax.XTick;
YTick = ax.YTick;
ax.XTick = ceil(min(XTick)):floor(max(XTick));
ax.YTick = ceil(min(YTick)):floor(max(YTick));

%convert labels to 10^{}
XTickLabel = ax.XTickLabel;
for ct = 1:length(XTickLabel)
    XTickLabel{ct}=['10^',XTickLabel{ct}];
end
ax.XTickLabel=XTickLabel;

YTickLabel = ax.YTickLabel;
for ct = 1:length(YTickLabel)
    YTickLabel{ct}=['10^',YTickLabel{ct}];
end
ax.YTickLabel=YTickLabel;

%make lines
if L
    %in X
    base10=10.^floor(XTick(1));
    start = ceil(10.^XTick(1) / base10)*base10;
    hold on
    go=1;
    while go
        plot([start,start],[YTick(1) YTick(end)],'-w')
        go=0;
    end
    
    
    
end