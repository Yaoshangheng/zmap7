function time_vs_something_plot(obj, name, whichplotter, tabgrouptag)
    % TIME_VS_SOMETHING_PLOT
    %
    % whichplotter can be an instance of either TimeMagnitudePLottter or TimeDepthPlotter
    % if tab doesn't exist yet, create it
    
    myTab = findOrCreateTab(obj.fig, tabgrouptag, name);
    
    contextTag =[name ' contextmenu'];

    delete(myTab.Children);
    delete(findobj(obj.fig,'Tag',contextTag));
    ax=axes(myTab);
    whichplotter.plot(obj.catalog,ax);
    ax.Title=[];
    c=uicontextmenu('Tag',contextTag);
    uimenu(c,'Label','Open in new window','MenuSelectedFcn',@(~,~)whichplotter.plot(obj.catalog));
    addLegendToggleContextMenuItem(ax,ax,c,'bottom','above');
    ax.UIContextMenu=c;
end