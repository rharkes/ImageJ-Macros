%first we make sure spect.m is there. if not-exist (if ~exist) we add the
%path to spect.m so Matlab can find it.
if ~exist('spect.m','file'),addpath('..\Spectra');end

%get the right spectrum
cfpF = spect('..\Spectra\FPs\ECFP - Em.txt');
plot(cfpF);axis([400 600 0 1])

%set the filters
filt1 = [425,475];
filt2 = [515,535];

%now we need to find how much there is in either filterchannel
in_filt1 = cfpF.data(:,1)>filt1(1)&cfpF.data(:,1)<filt1(2); %bigger than lowest value, and smaller than biggest
in_filt2 = cfpF.data(:,1)>filt2(1)&cfpF.data(:,1)<filt2(2); 
%show area
hold on
area(cfpF.data(in_filt1,1),cfpF.data(in_filt1,2))
area(cfpF.data(in_filt2,1),cfpF.data(in_filt2,2));
hold off

%and sum the intensity
sum_filt1 = sum(cfpF.data(in_filt1,2));
sum_filt2 = sum(cfpF.data(in_filt2,2));

%divide
div = sum_filt2/sum_filt1;

%tell result
fprintf(1,'The overlap is %.1f%% \n',100*div)