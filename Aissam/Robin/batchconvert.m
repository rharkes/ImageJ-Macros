d = dirrh('*.PLW');
for ct = 1:length(d)
    [~,n,e] = fileparts(d(ct).name);
    p = d(ct).folder;
    [t,u,par]=PLW2MLv5(d(ct).name);
    writeto = fullfile(p,[n,'.xlsx']);
    if exist(writeto,'file'),delete(writeto);end
    xlswrite(writeto,[t;u]');
end