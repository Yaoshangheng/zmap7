classdef zmap_message_center < handle
    % zmap_message_center is the main control window for zmap.
    % it provides feedback on what operations zmap is performing, as well as help for
    % this replaces the existing mess (welcome) window.
    % it is more robust, and is self-contained.
    
    properties
    end
    
    methods
        function obj = zmap_message_center()
            % zmap_message_center provides handle used to access zmap message center functionality
            % the message center will be created if it doesn't exist, otherwise it will be made the
            % active figure
            
            h = findall(0,'tag','zmap_message_window');
            if (isempty(h))
                h = create_message_figure();
                startmen(h);
                zmap_message_center.set_message('To get started...',...
                    ['Choose an import option from the "Data" menu', newline,...
                    'data can be imported from .MAT files, from  ', newline,...
                    'formatted text files, or from the web       ']);
                obj.end_action( );
            else
                % put it in focus
                figure(h)
            end
        end
        %{
        function set_message(obj, messageTitle, messageText, messageColor)
            % set_message displays a message to the user
            %
            % usage: 
            %    msgcenter.set_message(title, text)
            %
            % see also set_warning, set_error, set_info, clear_message
            
            titleh = findall(0,'tag','zmap_message_title');
            % TODO see if control still exists
            titleh.String = messageTitle;
            texth = findall(0,'tag','zmap_message_text');
            texth.String = messageText;
            if exist('messageColor','var')
                titleh.ForegroundColor = messageColor;
            end
        end
        
        function set_warning(obj, messageTitle, messageText)
            % set_warning displays a message to the user in orange
            obj.set_message(messageTitle, messageText, [.8 .2 .2]);
        end
        
        function set_error(obj, messageTitle, messageText)
            % set_error displays a message to the user in red
            obj.set_message(messageTitle, messageText, [.8 0 0]);
        end
        
        function set_info(obj, messageTitle, messageText)
            % set_info displays a messaget ot the user in blue
            obj.set_message(messageTitle, messageText, [0 0 0.8]);
        end
        
        function clear_message(obj)
            % clear_message will return the message center to neutral state
            %
            %  usage:
            %      msgcenter.clear_message()
            
            titleh = findall(0,'tag','zmap_message_title');
            % TODO see if control still exists
            if ~isempty(titleh)
                titleh.String = 'Messages';
                titleh.FOregroundColor = 'k';
            end
            texth = findall(0,'tag','zmap_message_text');
            % TODO see if control still exists
            if ~isempty(texth)
                texth.String = '';
            end
        end
        %}
        
        
    end
    methods(Static)
        function create()
            h = findall(0,'tag','zmap_message_title');
            if isempty(h)
                zmap_message_center();
            end
        end
        function set_message(messageTitle, messageText, messageColor)
            % set_message displays a message to the user
            %
            % usage: 
            %    msgcenter.set_message(title, text)
            %
            % see also set_warning, set_error, set_info, clear_message
            zmap_message_center.create();
            titleh = findall(0,'tag','zmap_message_title');
            % TODO see if control still exists
            titleh.String = messageTitle;
            texth = findall(0,'tag','zmap_message_text');
            texth.String = messageText;
            if exist('messageColor','var')
                titleh.ForegroundColor = messageColor;
            end
        end
        
        function set_warning(messageTitle, messageText)
            % set_warning displays a message to the user in orange
            zmap_message_center.set_message(messageTitle, messageText, [.8 .2 .2]);
        end
        
        function set_error(messageTitle, messageText)
            % set_error displays a message to the user in red
            zmap_message_center.set_message(messageTitle, messageText, [.8 0 0]);
        end
        
        function set_info(messageTitle, messageText)
            % set_info displays a messaget ot the user in blue
            zmap_message_center.set_message(messageTitle, messageText, [0 0 0.8]);
        end
        
        function clear_message()
            % clear_message will return the message center to neutral state
            %
            %  usage:
            %      msgcenter.clear_message()
            zmap_message_center.create();
            titleh = findall(0,'tag','zmap_message_title');
            % TODO see if control still exists
            if ~isempty(titleh)
                titleh.String = 'Messages';
                titleh.ForegroundColor = 'k';
            end
            texth = findall(0,'tag','zmap_message_text');
            % TODO see if control still exists
            if ~isempty(texth)
                texth.String = '';
            end
            zmap_message_center.update_catalog();
            
        end
        
        function update_catalog()
            %obj = zmap_message_center();
            update_current_catalog_pane();
            update_selected_catalog_pane();
        end
        
        function start_action(action_name)
            % start_action sets the text for the action button, and sets the spinner
            buth = findall(0,'tag','zmap_action_button');
            if ~isempty(buth)
                buth.String = action_name;
            end
            watchon();
        end
        
        function end_action()
            % end_action sets the text button to idling, and unsets the spinner
            buth = findall(0,'tag','zmap_action_button');
            if ~isempty(buth)
                buth.String = 'Ready, now idling';
            end
            watchoff();
        end
    end
end

function h = create_message_figure()
    % creates figure with following uicontrols
    %   TAG                 FUNCTION
    %   quit_button         leave matlab(?) 
    %   zmap_action_button  display current ation that is happening
    %   zmap_action_text    provide context for action button(?)
    %   welcome_text        welcome to zmap v whatever
    %   zmap_message_title  title of message
    %   zmap_message_text   text of message
    global wex wey welx wely fontsz
    hilighted_color = [0.8 0 0];
    
        h = figure();
        welcome_text = 'Welcome to ZMAP v 7.0';
        
        messtext = '  ';
        titStr ='Messages';
        rng('shuffle');
        
        set(h,'NumberTitle','off',...
            'Name','Message Window',...
            'MenuBar','none',...
            'Units','pixel',...
            'backingstore','off',...
            'tag','zmap_message_window',...
            'Resize','off',...
            'pos',[23 212 340 585]);
        %h.Units = 'normalized';
        ax = axes('units','normalized','Position',[0 0 1 1]);;
        ax.Units = 'pixel';
        %ax.Units = 'normalized';
        ax.Visible = 'off';
        te1 = text(.05,.98, welcome_text);
        set(te1,'FontSize',12,'Color','k','FontWeight','bold','Tag','welcome_text');
        
        te2 = text(0.05,0.94,'   ') ;
        set(te2,'FontSize',fontsz.s,'Color','k','FontWeight','bold','Tag','te2');
        
        % quit button
        uicontrol('Style','Pushbutton',...
            'Position', [235 485 85 45],...
            'Callback','qui', ...
            'String','Quit', ...
            'Visible','on',...
            'Tag', 'quit_button');
            
        uicontrol(...
            'BackgroundColor',[0.7 0.7 0.7 ],...
            'ForegroundColor',[0 0 0 ],...
            'Position',[20 485 200 45],...
            'String','   ',...
            'Style','pushbutton',...
            'Visible','on',...
            'Tag', 'zmap_action_button',...
            'UserData','frame1');
        
        text(0.05,0.93 ,'Action:','FontSize',fontsz.l,...
            'Color', hilighted_color,'FontWeight','bold','Tag','zmap_action_text');
        
        
        % Display the message text
        %
        top=0.55;
        left=0.05;
        right=0.95;
        bottom=0.05;
        labelHt=0.050;
        spacing=0.05;
        
        % First, the Text Window frame
        frmBorder=0.02;
        frmPos=[left-frmBorder bottom-frmBorder ...
            (right-left)+2*frmBorder (top-bottom)+2*frmBorder];
        uicontrol( ...
            'Style','frame', ...
            'Position',[10 300 320 180], ...
            'BackgroundColor',[0.6 0.6 0.6]);
        
        % Then the text label
        labelPos=[left top-labelHt (right-left) labelHt];
        
        uicontrol( ...
            'Style','text', ...
            'Position',[20 440 300 30], ...
            'ForegroundColor',hilighted_color, ...
            'FontWeight','bold',...
            'Tag', 'zmap_message_title', ...
            'String',titStr);
        
        txtPos=[left bottom (right-left) top-bottom-labelHt-spacing];
        txtHndlList=uicontrol( ...
            'Style','edit', ...
            'Max',20, ...
            'String',messtext, ...
            'BackgroundColor',[1 1 1], ...
            'Visible','off', ...
            'Tag', 'zmap_message_text', ...
            'Position',[20 310 300 125]);
        set(txtHndlList,'Visible','on');
        
        %%  add catalog details
        
        
        % create panel to hold catalog details
        cat1panel = uipanel(h,'Title','Current Catalog Summary',...
            'Units','pixels',...
            'Position',[15 130 315 160],...
            'Tag', 'zmap_curr_cat_pane');
        
        
        uicontrol('Parent',cat1panel,'Style','text', ...
            'String','No Catalog Loaded!',...
            'Units','normalized',...
            'Position',[0.05 0.4 .9 .55],...
            'HorizontalAlignment','left',...
            'FontName','FixedWidth',...
            'FontSize',12,...
            'FontWeight','bold',...
            'Tag','zmap_curr_cat_summary');
        
        %% BUTTONS
        % update catalog
       uicontrol('Parent',cat1panel,'Style','Pushbutton', ...
            'String','Refresh',...
            'Units','normalized',...
            'Position',[0.05 0.05 .3 .3],...
            'Callback','zmap_message_center.update_catalog()',...
            'Tag','zmap__cat_updatebutton');
        
        % edit button to modify catalog parameters
       uicontrol('Parent',cat1panel,'Style','Pushbutton', ...
            'String','Edit Ranges',...
            'Units','normalized',...
            'Position',[0.35 0.05 .3 .3],...
            'Callback',@do_catalog_overview,...
            'Tag','zmap_curr_cat_editbutton');
        
        % edit button to modify catalog parameters
       uicontrol('Parent',cat1panel,'Style','Pushbutton', ...
            'String','Show Map',...
            'Units','normalized',...
            'Position',[0.65 0.05 .3 .3],...
            'Callback',@(s,e) mainmap_overview(),...
            'Tag','zmap_curr_cat_mapbutton');
        
        %% selected catalog panel
        % create panel to hold details for selected part of catalog
        cat2panel = uipanel(h,'Title','Selected Catalog Summary',...
            'Units','pixels',...
            'Position',[15,10,315,110],...
            'Tag', 'zmap_sel_cat_pane');
        
        
        uicontrol('Parent',cat2panel,'Style','text', ...
            'String','No sub-selection of catalog!',...
            'Units','normalized',...
            'Position',[0.05 0.1 .9 .85],...
            'HorizontalAlignment','left',...
            'FontName','FixedWidth',...
            'FontSize',12,...
            'FontWeight','bold',...
            'Tag','zmap_sel_cat_summary');
        
        update_current_catalog_pane();
        update_selected_catalog_pane();
        
end

function do_catalog_overview(s,~)
    global a
    a = catalog_overview(a);
    update_current_catalog_pane(s);
end

function update_current_catalog_pane(~,~)
    global a
    
    
    if ~isempty(a)
        if isa(a,'ZmapCatalog')
            mycat = a;
        else
            mycat=ZmapCatalog(a,'a');
        end
        h = findall(0,'tag','zmap_curr_cat_summary');
        h.String = mycat.summary('simple');
        return
    else
        h = findall(0,'tag','zmap_curr_cat_summary');
        h.String = 'No catalog loaded';
    end
end

function update_selected_catalog_pane(~,~)
    global newcat
    
    
    if ~isempty(newcat)
        if ~isa(newcat,'ZmapCatalog')
            newcat=ZmapCatalog(newcat,'newcat');
        end
        h = findall(0,'tag','zmap_sel_cat_summary');
        h.String = newcat.summary('simple');
    else
        h = findall(0,'tag','zmap_sel_cat_summary');
        h.String = 'No subset selected';
    end
end
