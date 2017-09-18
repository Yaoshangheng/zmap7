function mi_dep() % autogenerated function wrapper
    %  misfit_magnitude
    % August 95 by Zhong Lu
    % turned into function by Celso G Reyes 2017
    
    ZG=ZmapGlobal.Data; % used by get_zmap_globals
    
    report_this_filefun(mfilename('fullpath'));
    
    mif77=findobj('Type','Figure','-and','Name','Misfit as a Function of Depth');
    
    
    
    if isempty(mif77)
        mif77 = figure_w_normalized_uicontrolunits( ...
            'Name','Misfit as a Function of Depth',...
            'NumberTitle','off', ...
            'backingstore','on',...
            'NextPlot','add', ...
            'Visible','off', ...
            'Position',[ (ZG.fipo(3:4) - [300 500]) ZmapGlobal.Data.map_len]);
        
        
        
        hold on
        
    end
    figure_w_normalized_uicontrolunits(mif77)
    hold on
    
    
    plot(ZG.a.Depth,mi(:,2),'go');
    
    grid
    %set(gca,'box','on',...
    %        'SortMethod','childorder','TickDir','out','FontWeight',...
    %        'bold','FontSize',ZmapGlobal.Data.fontsz.m,'Linewidth',1.2);
    
    xlabel('Depth of Earthquake','FontWeight','bold','FontSize',ZmapGlobal.Data.fontsz.m);
    ylabel('Misfit Angle ','FontWeight','bold','FontSize',ZmapGlobal.Data.fontsz.m);
    hold off;
    
    done
    
end
