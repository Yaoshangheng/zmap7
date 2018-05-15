classdef ZmapMainWindow < handle
    % ZMAPMAINWINDOW controls the main interactive window for ZMAP
    
    properties(SetObservable)
        catalog ZmapCatalog % event catalog
        shape {mustBeShape} = ShapeGeneral % used to subset catalog by selected area
        Grid {mustBeZmapGrid} = ZmapGlobal.Data.Grid % grid that covers entire catalog area
        daterange datetime % used to subset the catalog with date ranges
        colorField=ZmapGlobal.Data.mainmap_plotby; % see ValidColorFields for choices 
    end
    
    properties
        rawcatalog ZmapCatalog;
        gridopt % used to define the grid
        evsel {EventSelectionChoice.mustBeEventSelector} = ZmapGlobal.Data.GridSelector % how events are chosen
        fig % figure handle
        xsgroup;
        maingroup; % maps will be plotted in here
        maintab; % handle to tab where the main map is plotted
        xsections; % contains XSection 
        xscats; % ZmapXsectionCatalogs corresponding to each cross section
        xscatinfo %stores details about the last catalog used to get cross section, avoids projecting multiple times.
        prev_states Stack = Stack(10);
        undohandle;
        Features = containers.Map();
        replotting=false % keep from plotting while plotting
        mdate
        mshape
        WinPos (4,1) = position_in_current_monitor(Percent(95),Percent(90))% [50 50 1200 750]; % position of main window
        eventMarker char = ZmapGlobal.Data.event_marker; % Marker used when plotting events
        sharedContextMenus;
    end
    
    properties(Constant)
        TabGroupPositions = struct(...
            'UR', [0.6658    0.5053    0.3250    0.4800],... URPos
            'LR',[0.6658    0.0120    0.3250    0.4800],...LRPos
            'Main',[0.0125    0.012    0.64    0.9733],...MainGroupPos
            'XS',[0.01    0.008    0.98    0.28]); % XSPos
        MapPos_S=[0.059    0.33    0.8    0.64] % width was .5375
        MapPos_L=[0.059    0.065    0.8    0.8933]
        XSAxPos=[0.06    0.2    0.86    0.7] % inside XSPos
        MapCBPos_S=[0.5975    0.5600    0.0167    0.4000]
        MapCBPos_L=[0.5975    0.5600    0.0167    0.4000]
        FeaturesToPlot = ZmapGlobal.Data.mainmap_features
        ValidColorFields={'Depth','Date','Magnitude','-none-'};
    end
    
    properties(Dependent)
        map_axes % main map axes handle
    end
    
    events
        XsectionEmptied
        XsectionAdded
        XsectionChanged
        XsectionRemoved
        GridChanged
        ShapeChanged
        CatalogChanged
        DateRangeChanged
    end
    
    methods
        function obj=ZmapMainWindow(fig,catalog)
            if exist('fig','var') &&... specifed a figure, perhaps.
                    isa(fig,'ZmapMainWindow') &&... actually, specified a ZmapMainWindow object, instead
                    ~isvalid(fig.fig) % but that object's figure isn't valid. (?)
                % recreate the figure (?)
                errordlg('unimplemented');
                return
            end
            
            if exist('fig','var') && isa(fig,'ZmapCatalog')
                catalog=fig;
                fig=[];
            end
            
            %if the figure was specified, but wasn't empty, then delete it.
            if exist('fig','var') && isa(fig,'matlab.ui.Figure') && isvalid(fig)
                an=questdlg(sprintf('Replace existing Map Windows?\nWarning: This will delete any results tabs'),...
                    'Window exists','Replace Existing','Create Another', 'cancel','cancel');
                switch an
                    case 'Replace Existing'
                        delete(fig);
                    case 'Create a new figure'
                        ;
                    case 'Nevermind'
                        return;
                end
                %delete(fig);
            end
            
            % set up figure
            h=msgbox_nobutton('drawing the main window. Please wait'); %#ok<NASGU>
            
            obj.fig=figure('Position',obj.WinPos,'Name','Catalog Name and Date','Units',...
                'Normalized','Tag','Zmap Main Window','NumberTitle','off','visible','off');
            % plot all events from catalog as dots before it gets filtered by shapes, etc.
           
            
            % make sure that empty legend entries automatically disappear when the menu is called up 
            set(findall(obj.fig,'Type','uitoggletool'),'ClickedCallback',...
                'insertmenufcn(gcbf,''Legend'');clear_empty_legend_entries(gcf);');
            
            
            c=uicontextmenu('tag','yscale contextmenu');
            uimenu(c,'Label','Use Log Scale',CallbackFld,{@logtoggle,'Y'});
            obj.sharedContextMenus.LogLinearYScale = c;
            
            c=uicontextmenu('tag','xscale contextmenu');
            uimenu(c,'Label','Use Log Scale',CallbackFld,{@logtoggle,'X'});
            obj.sharedContextMenus.LogLinearXScale = c;
            
            add_menu_divider('mainmap_menu_divider')
            
            
            ZG=ZmapGlobal.Data;
            if exist('catalog','var')
                obj.rawcatalog=catalog;
            else
                rawview = ZG.Views.primary;
                if ~isempty(rawview)
                    obj.rawcatalog=ZG.Views.primary.Catalog;
                end
            end
            if isempty(obj.rawcatalog)
                errordlg(sprintf('Cannot open the ZmapMainWindow: No catalog is loaded.\nFirst load a catalog into Zmap, then try again.'),'ZMap');
                error('No catalog is loaded');
            end
            obj.daterange=[min(obj.rawcatalog.Date) max(obj.rawcatalog.Date)];
            
            obj.shape=ZG.selection_shape;
            [obj.catalog,obj.mdate, obj.mshape]=obj.filtered_catalog();
            obj.Grid=ZG.Grid;
            obj.gridopt= ZG.gridopt;
            obj.evsel = ZG.GridSelector;
            obj.xsections=containers.Map();
            obj.xscats=containers.Map();
            obj.xscatinfo=containers.Map();
            
            obj.fig.Name=sprintf('%s [%s - %s]',obj.catalog.Name ,char(min(obj.catalog.Date)),...
                char(max(obj.catalog.Date)));
            
            TabLocation = 'top'; % 'top','bottom','left','right'
            
            obj.maingroup=uitabgroup('Units','normalized','Position',obj.TabGroupPositions.Main,...
                'Visible','on',...
                'SelectionChangedFcn',@cb_mainMapSelectionChanged,...
                'TabLocation',TabLocation,'Tag','main plots');
            obj.maintab = findOrCreateTab(gcf,'main plots',obj.catalog.Name);
            obj.maintab.Tag = 'mainmap_tab';
            %obj.maintab = uitab(obj.maingroup,'Title',obj.catalog.Name,'Tag','mainmap_tab');
            
            
            obj.plot_base_events(obj.maintab, obj.FeaturesToPlot);
            
            if isempty(obj.Grid)
                obj.Grid=ZmapGrid('Grid',obj.gridopt);
            end
            
            obj.prev_states=Stack(5); % remember last 5 catalogs
            obj.pushState();
            
            
            uitabgroup('Units','normalized','Position',obj.TabGroupPositions.UR,...
                'Visible','off','SelectionChangedFcn',@cb_selectionChanged,...
                'TabLocation',TabLocation,'Tag','UR plots');
            uitabgroup('Units','normalized','Position',obj.TabGroupPositions.LR,...
                'Visible','off','SelectionChangedFcn',@cb_selectionChanged,...
                'TabLocation',TabLocation,'Tag','LR plots');
            
            obj.xsgroup=uitabgroup(obj.maintab,'Units','normalized','Position',obj.TabGroupPositions.XS,...
                'TabLocation',TabLocation,'Tag','xsections',...
                'SelectionChangedFcn',@cb_selectionChanged,'Visible','off');
            
            obj.replot_all();
            obj.fig.Visible='on';
            set(findobj(obj.fig,'Type','uitabgroup','-and','Tag','LR plots'),'Visible','on');
            set(findobj(obj.fig,'Type','uitabgroup','-and','Tag','UR plots'),'Visible','on');
            
            drawnow
            
            obj.create_all_menus(true); % plot_base_events(...) must have already been called, ino order to load the features from ZG
            ax=findobj(obj.fig,'Tag','mainmap_ax');
            obj.fig.CurrentAxes=ax;
            legend(ax,'show');
            clear_empty_legend_entries(obj.fig);
            
            
            
            if isempty(obj.xsections)
                set(findobj('Parent',findobj(obj.fig,'Label','X-sect'),'-not','Tag','CreateXsec'),'Enable','off')
            end
            obj.fig.UserData=obj; % hopefully not creating a problem with the space-time-continuum.
            
            attach_catalog_listeners(obj);
            attach_xsection_listeners(obj);
            addlistener(obj,'CatalogChanged'  ,      @obj.replot_all);
            addlistener(obj, 'daterange', 'PostSet', @obj.replot_all)
            addlistener(obj, 'catalog',   'PostSet', @obj.attach_catalog_listeners);
            addlistener(obj, 'shape',     'PostSet', @(~,~)disp('**Shape Changed'));
            addlistener(obj, 'Grid',      'PostSet', @(~,~)disp('**Grid Changed'));
        end
        
        function attach_catalog_listeners(obj,~,~)
            % reapply listeners to this specific catalog
            addlistener(obj.catalog,'Name','PostSet',@(~,~)obj.set_figure_name);
            addlistener(obj.catalog,'ValueChange',@(~,~)notify('CatalogChanged'));
        end
            
        function attach_xsection_listeners(obj)
            addlistener(obj,'XsectionEmptied',@(~,~)obj.deactivateXsections);
            addlistener(obj,'XsectionAdded',  @(~,~)obj.activateXsections);
            addlistener(obj,'XsectionAdded',  @obj.replot_all);
            addlistener(obj,'XsectionChanged',@obj.replot_all);
            addlistener(obj,'XsectionEmptied',@obj.replot_all);
            addlistener(obj,'XsectionAdded', @(~,~)clear_empty_legend_entries(obj.fig));
        end
        
        %% METHODS DEFINED IN DIRECTORY
        %
        %
        %
        %
        
        replot_all(obj,metaProp,eventData)
        plot_base_events(obj, container, featurelist)
        plotmainmap(obj)
        c=context_menus(obj, tag,createmode, varargin) % manage context menus used in figure
        plothist(obj, name, values, tabgrouptag)
        fmdplot(obj, tabgrouptag)
        
        cummomentplot(obj,tabgrouptag)
        time_vs_something_plot(obj, name, whichplotter, tabgrouptag)
        cumplot(obj, tabgrouptag)
        
        % push and pop state
        pushState(obj)
        popState(obj)
        catalog_menu(obj,force)
        [c, mdate, mshape, mall]=filtered_catalog(obj)
        %do_colorbar(obj,~,~, prevcallback)
        
        % menus
        create_all_menus(obj, force)
        
        %
        %
        %
        %
        %%
        
        function ax=get.map_axes(obj)
            % get mainmap axes
            ax=findobj(obj.fig,'Tag','mainmap_ax');
        end
        
        function zp = map_zap(obj)
            % MAP_ZAP create a ZmapAnalysis Pkg for the main window
            % the ZmapAnalysisPkg can be used as inputs to the various processing routines
            %
            % zp = obj.MAP_ZAP()
            %
            % see also ZMAPANALYSISPKG
            
            if isempty(obj.evsel)
                obj.evsel = EventSelectionChoice.quickshow();
            else
                fprintf('Using existing event selection:\n%s\n',...
                    matlab.unittest.diagnostics.ConstraintDiagnostic.getDisplayableString(obj.evsel));
            end
            if isempty(obj.Grid)
                gridopts= GridParameterChoice.quickshow();
                obj.Grid = ZmapGrid('grid',gridopts.toStruct);
            else
                fprintf('Using existing grid:\n');
            end
            zp = ZmapAnalysisPkg( [], obj.catalog,obj.evsel,obj.Grid, obj.shape);
        end
        
        function zp = xsec_zap(obj, xsTitle)
            % XSEC_ZAP create a ZmapAnalysisPkg from a cross section
            % the ZmapAnalysisPkg can be used as inputs to the various processing routines
            %
            % zp = obj.XSEC_ZAP() create a Z.A.P. but use the currently active cross section as a guide
            % zp = obj.XSEC_ZAP(xsTitle)
            %
            % see also ZMAPANALYSISPKG
            
            if isempty(obj.xsections)
                errordlg('There is no cross section to analyze. Aborting.');
                zp=[];
                return
            end
            
            ZG=ZmapGlobal.Data;
            
            z_min = floor(min([0 min(obj.catalog.Depth)]));
            z_max = round(max(obj.catalog.Depth) + 4.9999 , -1);
            
            zdlg = ZmapDialog([]);
            if ~exist('xsTitle','var')
                xsTitle=obj.xsgroup.SelectedTab.Title;
            else
                if ~any(strcmp(obj.xsections.keys,xsTitle))
                    warndlg(sprintf('The requested cross section [%s] does not exist. Using selected tab.',xsTitle));
                    xsTitle=obj.xsgroup.SelectedTab.Title;
                end
            end
            xsIndex = find(strcmp(obj.xsections.keys,xsTitle));
            zdlg.AddBasicPopup('xsTitle', 'Cross Section:', obj.xsections.keys, xsIndex, 'Choose the cross section');
            zdlg.AddEventSelectionParameters('evsel', ZG.ni, ZG.ra, 1);
            zdlg.AddBasicEdit('x_km','Horiz Spacing [km]', 5,'Distance along strike, in kilometers');
            zdlg.AddBasicEdit('z_min','min Z [km]', z_min,'Shallowest grid point');
            zdlg.AddBasicEdit('z_max','max Z [km]', z_max,'Deepest grid point, in kilometers');
            zdlg.AddBasicEdit('z_delta','number of layers', round(z_max-z_min)+1,'Number of horizontal layers ');
            [zans, okPressed] = zdlg.Create('Cross Section Sample parameters');
            if ~okPressed
                zp = [];
                return
            end
            
            zs_km = linspace(zans.z_min, zans.z_max, zans.z_delta);
            gr = obj.xsections(xsTitle).getGrid(zans.x_km, zs_km);
            zp = ZmapAnalysisPkg( [], obj.xscats(xsTitle), zans.evsel, gr, obj.shape);
            
        end
        %{
        function myTab = findOrCreateTab(obj, parent, title)
            % FINDORCREATETAB if tab doesn't exist yet, create it
            %    parent :
            myTab=findobj(obj.fig,'Title',title,'-and','Type','uitab');
            if isempty(myTab)
                p = findobj(obj.fig,'Tag',parent);
                myTab=uitab(p, 'Title',title);
            end
        end
        %}
        
        function cb_timeplot(obj)
            ZG=ZmapGlobal.Data;
            ZG.newt2=obj.catalog;
            timeplot();
        end
        
        function cb_starthere(obj,ax)
            disp(ax)
            [x,~]=click_to_datetime(ax);
            obj.pushState();
            obj.daterange(1)=x;
        end
        
        function cb_endhere(obj,ax)
            [x,~]=click_to_datetime(ax);
            obj.pushState();
            obj.daterange(2)=x;
        end
        
        function cb_trim_to_largest(obj,~,~)
            biggests = obj.catalog.Magnitude == max(obj.catalog.Magnitude);
            idx=find(biggests,1,'first');
            obj.pushState();
            obj.daterange(1)=obj.catalog.Date(idx);
            %obj.catalog = obj.catalog.subset(obj.catalog.Date>=obj.catalog.Date(idx));
        end
             
        function shapeChangedFcn(obj,oldshapecopy,varargin)
            if ~isempty(varargin)
                disp(varargin)
            end
            obj.prev_states.push({obj.catalog, oldshapecopy, obj.daterange});
            obj.replot_all();
        end
        
        function cb_undo(obj,~,~)
            obj.popState()
            obj.replot_all();
        end
        
        function cb_redraw(obj,~,~)
            % REDRAW if things have changed, then also push the new state
            watchon
            item=obj.prev_states.peek();
            do_stash=true;
            if ~isempty(item)
                do_stash = ~strcmp(item{1}.summary('stats'),obj.catalog.summary('stats')) ||...
                    ~isequal(obj.shape,item{2});
            end
            if do_stash
                disp('pushing')
                obj.pushState();
            end
            obj.replot_all();
            watchoff
        end
        
        function cb_xsection(obj,~,~)
            import callbacks.copytab
            % main map axes, where the cross section outline will be plotted
            axm=obj.map_axes;
            obj.fig.CurrentAxes=axm;
            % xsec = XSection.initialize_with_dialog(axm,20);
            try
                xsec = XSection.initialize_with_mouse(axm, 20);
            catch ME
                warning(ME.message)
                return
                % do not set segment
            end
            if isempty(xsec), return, end
            mytitle=xsec.name;
            
            obj.xsec_add(mytitle, xsec);
            
            mytab=findobj(obj.fig,'Title',mytitle,'-and','Type','uitab');
            if ~isempty(mytab)
                delete(mytab);
            end
            
            mytab=uitab(obj.xsgroup, 'Title',mytitle,'ForegroundColor',xsec.color,'DeleteFcn',xsec.DeleteFcn);
            
            % keep tabs alphabetized
            [~,idx]=sort({obj.xsgroup.Children.Title});
            obj.xsgroup.Children=obj.xsgroup.Children(idx);
           
            % add context menu to tab allowing modifications to x-section
            delete(findobj(obj.fig,'Tag',['xsTabContext' mytitle]))
            c=uicontextmenu(obj.fig,'Tag',['xsTabContext' mytitle]);
            uimenu(c,'Label','Copy Contents to new figure (static)','Callback',@copytab);
            uimenu(c,'Label','Info','Separator','on',CallbackFld,@obj.cb_info);
            uimenu(c,'Label','Change Width',CallbackFld,@obj.cb_chwidth);
            uimenu(c,'Label','Change Color',CallbackFld,@obj.cb_chcolor);
            uimenu(c,'Label','Examine This Area',CallbackFld,{@obj.cb_cropToXS, xsec});
            uimenu(c,'Separator','on',...
                'Label','Delete',...
                CallbackFld,{@obj.cb_deltab,xsec});
            mytab.UIContextMenu=c;
            
            % plot the 
            ax=axes(mytab,'Units','normalized','Position',obj.XSAxPos,'YDir','reverse');
            %xsec.plot_events_along_strike(ax,obj.catalog);
            xsec.plot_events_along_strike(ax,obj.xscats(mytitle));
            ax.Title=[];
            
            % make this the active tab
            mytab.Parent.SelectedTab=mytab;
            obj.replot_all();
         
        end
        
        function cb_cropToXS(obj,~,~,xsec)
            oldshape=copy(obj.shape);
            obj.shape=ShapePolygon('polygon',[xsec.polylons(:), xsec.polylats(:)]);
            obj.shapeChangedFcn(oldshape);
            obj.replot_all();
        end
            
        function cb_deltab(obj, src,~, xsec)
            prevPtr = obj.fig.Pointer;
            obj.fig.Pointer='watch';
            try
                
                if strcmp(get(gco,'Type'),'uitab') && strcmp(get(gco,'Title'), xsec.name)
                    delete(gco);
                else
                    error('Supposed to delete tab, but gco is not what is expected');
                end
                drawnow
                %xsec.DeleteFcn();
                %xsec.DeleteFcn=@do_nothing;
                disp(['deleting ' xsec.name]);
                delete(findobj(obj.fig,'Type','uicontextmenu','-and','-regexp','Tag',['.sel_ctxt .*' xsec.name '$']))
                obj.xsec_remove(xsec.name);
                obj.replot_all('CatalogUnchanged');
                if isempty(obj.xsections)
                    set(findobj(obj.fig,'Parent',findobj(obj.fig,'Label','X-sect'),'-not','Tag','CreateXsec'),'Enable','off')
                end
                
                obj.fig.Pointer=prevPtr;
            catch ME
                obj.fig.Pointer=prevPtr;
                rethrow(ME);
            end
            
                
        end
            
        function cb_chwidth(obj,~,~)
            % change width of a cross-section
            title=get(gco,'Title');
            xsec=obj.xsections(title);
            prompt={'Enter the New Width:'};
            name='Cross Section Width';
            numlines=1;
            defaultanswer={num2str(xsec.width_km)};
            answer=inputdlg(prompt,name,numlines,defaultanswer);
            if ~isempty(answer)
                xsec=xsec.change_width(str2double(answer),obj.map_axes);
                obj.xsec_add(title,xsec);
            end
            ax= findobj(gco,'Type','axes','-and','-regexp','Tag','Xsection strikeplot.*');
            ax.UserData.cep.catalogFcn=@()obj.xscats(xsec.name);
            ax.UserData.cep.update();%
            % xsec.plot_events_along_strike(ax,obj.xscats(title),true);
            ax.Title=[];
            obj.replot_all('CatalogUnchanged');
        end
        
        function cb_chcolor(obj,~,~)
            title=get(gco,'Title');
            xsec=obj.xsections(title);
            xsec=xsec.change_color([],gcf);
            set(gco,'ForegroundColor',xsec.color); %was mytab
            obj.xsections(title)=xsec;
        end
        function cb_info(obj,~,~)
            title=get(gco,'Title');
            xsec=obj.xsections(title);
            s=sprintf('%s containing:\n\n%s',xsec.info(),...
                obj.xscats(title).summary('stats'));
            msgbox(s,title);
        end
        
        %% menu items.        %% create menus
        
        function set_3d_view(obj, src,~)
            watchon
            drawnow;
            axm=obj.map_axes;
            switch src.Label
                case '3-D view'
                    hold(axm,'on');
                    view(axm,3);
                    grid(axm,'on');
                    zlim(axm,'auto');
                    %axis(ax,'tight');
                    zlabel(axm,'Depth [km]','UserData',field_unit.Depth);
                    axm.ZDir='reverse';
                    rotate3d(axm,'on'); %activate rotation tool
                    hold(axm,'off');
                    src.Label = '2-D view';
                otherwise
                    view(axm,2);
                    grid(axm,'on');
                    zlim(axm,'auto');
                    rotate3d(axm,'off'); %activate rotation tool
                    src.Label = '3-D view';
            end
            watchoff
            drawnow;
        end
        
        function set_event_selection(obj,val)
            % SET_EVENT_SELECTION changes the event selection criteria (radius, # events)
            %  obj.SET_EVENT_SELECTION() sets it to the global version
            %  obj.SET_EVENT_SELECTION(val) changes it to val, where val is a struct with fields
            %  similar to what is returned via EventelectionChoice.quickshow
            
            if ~isempty(val)
                assert(isstruct(val)); % could do more detailed checking of fields
                obj.evsel = val;
            elseif isempty(ZmapGlobal.Data.GridSelector)
                obj.evsel = EventSelectionChoice.quickshow();
            else
                ZG=ZmapGlobal;
                obj.evsel = ZG.GridSelector;
            end
        end
        
        function ev = get_event_selection(obj)
            ev = obj.evsel;
        end
        
        function copy_mainmap_into_container(obj,container)
            c=copyobj(obj.map_axes,container);
            c.Tag=[c.Tag '_' container.Tag];
            t=findobj(c,'Type','line','-or','Type','scatter','-not','Tag','grid_Grid');
            set(t,'PickableParts','none'); % mute the values
        end
    end % METHODS
    methods(Access=protected) % HELPER METHODS
        
        %% CROSS SECTION HELPERS
        
        function xsec_remove(obj, key)
            % XSEC_REMOVE completely removes cross section from object
            obj.xsections.remove(key);
            obj.xscats.remove(key);
            obj.xscatinfo.remove(key);
            if isempty(obj.xsections)
                obj.notify('XsectionEmptied');
            else
                obj.notify('XsectionRemoved');
            end
        end
        
        function xsec_add(obj, key, xsec)
            isUpdating=ismember(key,obj.xsections.keys);
            %XSEC_ADD add/replace cross section
            obj.xsections(key)=xsec;
            % add catalog generated by the cross section (ignoring shape)
            obj.xscats(key)= xsec.project(obj.rawcatalog.subset(obj.mdate));
            % add the information about the catalog used
            obj.xscatinfo(key)=obj.catalog.summary('stats');
            
            if isUpdating
                obj.notify('XsectionChanged');
            else
                obj.notify('XsectionAdded')
            end
        end
        
        function activateXsections(obj)
            disp('activationg Xsections')
            set(findobj(obj.fig,'Parent',findobj(obj.fig,'Label','X-sect'),'-not','Tag','CreateXsec'),'Enable','on');
            
            obj.xsgroup.Visible = 'on';
            set(obj.map_axes,'Position',obj.MapPos_S);
            
            % set the colorbar position, if it is visible.
            cb = findobj(obj.fig,'tag','mainmap_colorbar');
            set(cb,'Position',obj.MapCBPos_S);
            drawnow
        end
        
        function deactivateXsections(obj)
            set(findobj(obj.fig,'Parent',findobj(obj.fig,'Label','X-sect'),'-not','Tag','CreateXsec'),'Enable','off');
            obj.xsgroup.Visible='off';
            set(obj.map_axes,'Position',obj.MapPos_L);
            
            % set the colorbar position, if it is visible.
            cb = findobj(obj.fig,'tag','mainmap_colorbar');
            set(cb,'Position',obj.MapCBPos_L);
        end
            
        function plot_xsections(obj, plotfn, tagBase)
            % PLOT_XSECTIONS 
            %  obj.plot_xsections(plotfn, tagBase)
            % plotfn is a function like: [@(xs,xcat)plot(...)] that does plotting and returns a handle
            k=obj.xsections.keys;
            for j=1:obj.xsections.Count
                hold on
                tit=k{j};
                xs=obj.xsections(tit);
                h=plotfn(xs, obj.xscats(tit) );
                h.Tag=[tagBase,' ' , xs.name];
            end
        end
        
        function set_figure_name(obj)
            obj.fig.Name=sprintf('%s [%s - %s]',obj.catalog.Name ,char(min(obj.catalog.Date)),...
                char(max(obj.catalog.Date)));
            obj.maintab.Title=obj.catalog.Name;
            drawnow
        end
        
    end
end % CLASSDEF

%% helper functions
function cb_selectionChanged(~,~)
    %alltabs = src.Children;
    %isselected=alltabs == src.SelectedTab;
    %set(alltabs(isselected).Children, 'Visible','on');
    %subax=findobj(alltabs(~isselected),'Type','axes')
    %set(subax,'visible','off');
end
function cb_mainMapSelectionChanged(src,~)
end

function s=CallbackFld()
    s=Futures.MenuSelectedFcn;
end