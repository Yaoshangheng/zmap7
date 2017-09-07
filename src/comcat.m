function combined=comcat(cat1, cat2) % autogenerated function wrapper
    % turned into function by Celso G Reyes 2017
    if ~exist('cat2','var')
        cat2=my_loadcatalog('Second');
    end
        
    combined=cat(cat1,cat2);
    combined.sort('Date');
end


function outcat = my_loadcatalog(desc)            %% load first catalog
    outcat=ZmapCatalog();
    [file1,path1] = uigetfile( '*.mat',[desc, ' catalog in *.mat format']);
    if isempty(file1)
        warningdlg('Cancelled');
        return;
    end
    tmp=load(fullfile(path1,file1),'a'); % assume catalog in variable a
    assert(isfield('a','tmp'),'file does not contain expected variable name');
    if ~isa(tmp.a,'ZmapCatalog')
        outcat=ZmapCatalog(tmp.a);
    else
        outcat=tmp.a;
    end
end