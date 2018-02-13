%columns to plot
x=1;
y=2;

%load data
F=fcsfile;

%show data
figure(1);clf
plot(F.data(x,:),F.data(y,:),'.')
xlabel(F.Events{x})
ylabel(F.Events{y})

%get region
[ROI] = fcs_getROI();

%remove data not in the region
in = inpolygon(F.data(x,:),F.data(y,:),ROI(:,1),ROI(:,2));
F.data(:,~in)=[];

%show data again
x=12;
y=7;

figure(1);clf
plot(F.data(x,:),F.data(y,:),'.')
xlabel(F.Events{x})
ylabel(F.Events{y})