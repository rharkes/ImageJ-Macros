
pth = 'D:\2018\02\19_FACS';
file1 = 'H200-2_non-stimulated';
file2 = 'H200-2_stimuated';
F1 = fcsfile(fullfile(pth,file1));
F2 = fcsfile(fullfile(pth,file2));

x=10;
y=13;

%show data
xdata=[F1.data(x,:),F2.data(x,:)];
ydata=[F1.data(y,:),F2.data(y,:)];
figure(1);clf
loglog(xdata,ydata,'.')
xlabel(F1.Params{x})
ylabel(F1.Params{y})

Lx = log10(xdata);
Ly = log10(ydata);

figure(2);clf;
plot(Lx,Ly,'.')
xlabel(F2.Params{x})
ylabel(F2.Params{y})

f=figure(3);
scale = 100;
val = real([Lx'.*scale,Ly'.*scale]);
val(any(val'<[0;0]),:)=[];
[h,xax,yax] = hist2r(val);
imagesc(xax./scale,yax./scale,h)
f.Children.YDir='normal';
xlabel(F1.Params{x})
ylabel(F1.Params{y})
colormap hot


