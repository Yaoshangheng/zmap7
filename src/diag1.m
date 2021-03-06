function diag1() 
    %make another dialog interface and call maxzlta
    
    % turned into function by Celso G Reyes 2017
    
    ZG=ZmapGlobal.Data; % used by get_zmap_globals
    report_this_filefun();
    %
    %
    %
    %
    %initial values
    ZG.compare_window_dur_v3 = years(1);
    step = 3;
    
    
    figure(mess);
    set(gcf,'visible','off')
    clf
    set(gcf,  'Name','MAXZ Input Parameters');
    set(gca,'visible','off');
    set(gcf,'Units','points','pos',[ ZG.welcome_pos 500 200])
    
    % creates a dialog box to input some parameters
    %
    freq_field=uicontrol('Style','edit',...
        'Position',[.70 .60 .17 .10],...
        'Units','normalized','String',num2str(years(ZG.compare_window_dur_v3)),...
        'callback',@callbackfun_001);
    
    inp2_field=uicontrol('Style','edit',...
        'Position',[.70 .40 .17 .10],...
        'Units','normalized','String',num2str(step),...
        'callback',@callbackfun_002);
    
    close_button=uicontrol('Style','Pushbutton',...
        'Position', [.60 .05 .15 .15 ],...
        'Units','normalized', 'Callback', @(~,~)zmapmenu(),'String','Cancel');
    
    go_button=uicontrol('Style','Pushbutton',...
        'Position',[.25 .05 .15 .15 ],...
        'Units','normalized',...
        'callback',@callbackfun_004,...
        'String','Go');
    
    txt1 = text(...
        'Position',[0. 0.65 0 ],...
        'FontSize',ZmapGlobal.Data.fontsz.m ,...
        'FontWeight','bold',...
        'String','Please input window length in years (winlen_days):');
    
    txt2 = text(...
        'Position',[0. 0.40 0 ],...
        'FontSize',ZmapGlobal.Data.fontsz.m ,...
        'FontWeight','bold',...
        'String','Please input step width in bins:');
    
    set(gcf,'visible','on')
    
    function callbackfun_001(mysrc,myevt)

        callback_tracker(mysrc,myevt,mfilename('fullpath'));
        ZG.compare_window_dur_v3=years(str2double(mysrc.String));
        freq_field.String=num2str(ZG.compare_window_dur_v3);
    end
    
    function callbackfun_002(mysrc,myevt)

        callback_tracker(mysrc,myevt,mfilename('fullpath'));
        step=str2double(inp2_field.String);
        inp2_field.String=num2str(step);
    end
    
    
    function callbackfun_004(mysrc,myevt)

        callback_tracker(mysrc,myevt,mfilename('fullpath'));
        show_map('maz','calma',ZG.compare_window_dur);
    end
    
end
