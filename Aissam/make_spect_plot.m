if ~exist('spect.m','file'),addpath('..\Spectra');end
%spectra from https://searchlight.semrock.com/
cfpA = spect('..\Spectra\FPs\ECFP - Abs.txt');
cfpF = spect('..\Spectra\FPs\ECFP - Em.txt');
yfpA = spect('..\Spectra\FPs\YFP - Abs.txt');
yfpF = spect('..\Spectra\FPs\YFP - Em.txt');
figure(1);
subplot(1,2,1);
plot(cfpA,'-b','LineWidth',3);hold on;
plot(yfpA,'-g','LineWidth',3);
plot([405 405],[0,1],'k-','LineWidth',2)
plot([488 488],[0,1],'k-','LineWidth',2)
axis([400 550 0 1])
legend('cpf','yfp')
xlabel('Wavelength(nm)')
title('absorption')
hold off
subplot(1,2,2);
plot(cfpF,'-b','LineWidth',3);hold on;
plot(yfpF,'-g','LineWidth',3);
axis([400 700 0 1])
legend('cpf','yfp')
xlabel('Wavelength(nm)')
title('fluorescence')
hold off