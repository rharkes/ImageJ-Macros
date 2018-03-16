clear all;
spectra=readtable('U:\ImageJ-Macros\Spectra\FPs\Alexa_532_555.csv');
x=spectra.Wavelength;
y1=spectra.AlexaFluor532_EM_;
y2=spectra.AlexaFluor555_EM_;
split = 550:600;
val1 = [];
val2 = [];
for ct = 1:length(split)
    idx = find(x>split(ct),1);
    ch1_v1 = sum(y1(1:idx),'omitnan')./sum(y1,'omitnan');
    ch1_v2 = sum(y2(1:idx),'omitnan')./sum(y2,'omitnan');
    val1(ct) = ch1_v1;
    val2(ct) = ch1_v2;
end
figure(1);clf;subplot(2,2,3)
plot(split,val1,split,val2,split,0.5*ones(1,length(split)))
legend('Alexa 532','Alexa 555','Location','best')
xlabel('Channel split (nm)')
ylabel('Fraction in ch1')
subplot(2,2,4)
plot(split,abs(0.5-val1),split,abs(0.5-val2))
legend('Alexa 532','Alexa 555','Location','best')
xlabel('Channel split (nm)')
ylabel('Deviation from 0.5')
subplot(2,2,[1:2])
plot(x,y1,x,y2,[572 572],[0 1],'--k')
legend('Alexa 532','Alexa 555','Location','best')
xlabel('Wavelength (nm)')
ylabel('Emission')