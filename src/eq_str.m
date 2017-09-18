function eq_str() % autogenerated function wrapper
    %earthquake_strike.m
    % plot the earthquake number along the strike on the map view
    %	August 1995 by Zhong Lu
    % turned into function by Celso G Reyes 2017
    
    ZG=ZmapGlobal.Data; % used by get_zmap_globals
    report_this_filefun(mfilename('fullpath'));
    myFigName='Earthquake Number Map';
    mif55=findobj('Type','Figure','-and','Name',myFigName);
    
    
    
    if isempty(mif55)
        mif55 = figure_w_normalized_uicontrolunits( ...
            'Name',myFigName,...
            'NumberTitle','off', ...
            'backingstore','on',...
            'NextPlot','add', ...
            'Visible','off', ...
            'Position',[ (ZG.fipo(3:4) - [300 500]) ZmapGlobal.Data.map_len]);
    end
    figure(mif55)
    
    hold on
    
    tt = newcat2;
    [ts,ti] = sort(tt(:,15));
    tt = tt(ti(:,1),:);
    
    for i = 1:length(tt)
        pt = plot(tt(i,1),tt(i,2),'o');
        hold on
    end
    
    done
    
end
