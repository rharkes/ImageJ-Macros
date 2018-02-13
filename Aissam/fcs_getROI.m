function [ROI] = fcs_getROI(h)
if nargin<1||isempty(h),h=gcf;end
figure(h);
go=true;
x=[];y=[];
while go
    [x_,y_,b] = ginput(1);
    switch b
        case 1 %left mousebutton
            x(end+1)=x_;
            y(end+1)=y_;
        case 3 %right mousebutton
            x(end+1)=x(1);
            y(end+1)=y(1);
            go=false;
        case 8 %backspace
            x(end)=[];
            y(end)=[];
        otherwise
            warning('key %.0f not supported',b)
    end
    hold on
    plot(x,y,'r-')
    hold off
end
ROI=[x',y'];