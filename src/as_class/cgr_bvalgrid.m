classdef cgr_bvalgrid < ZmapGridFunction
    % description of this function
    %
    %
    % in the function that generates the figure where this function can be called:
    %
    %     % create some menu items...
    %     h=cgr_bvalgrid.MenuItem(hMenu, ax) %c reate subordinate to menu item with handle hMenu
    %     % create the rest of the menu items...
    %
    %  once the menu item is clicked, then cgr_bvalgrid.interative_setup(true,true) is called
    %  meaning that the user will be provided with a dialog to set up the parameters,
    %  and the results will be automatically calculated & plotted once they hit the "GO" button
    %
    %
    
    properties
        ni = ZmapGlobal.Data.ni 
        ra = 25 % ZmapGlobal.Data.ra;
        Nmin = 50 
        fMcFix=1.0  %2.2
        nBstSample=100 
        useBootstrap  % perform bootstrapping?
        fMccorr = 0.2  % magnitude correction
        fBinning = 0.1  % magnitude bins
        EventSelector 
        gridOpts = ZmapGlobal.Data.gridopt 
        %bUseNiEvents= true;
        mc_choice
        Grid = ZmapGlobal.Data.Grid % actual grid[X Y;...], created from gridOpts
        %xvect %valid x values for grid
        %yvect %valid y values for grid
    end
    
    properties(Constant)
        PlotTag='myplot';
        ReturnDetails = { ... VariableNames, VariableDescriptions, VariableUnits
            'Mc_value', 'Magnitude of Completion (Mc)', '';...
            'Mc_std', 'Std. of Magnitude of Completion', '';...
            'x', 'Longitude', 'deg';...
            'y', 'Latitude', 'deg';...
            'Radius_km', 'Radius of chosen events (Resolution) [km]', 'km';...
            'b_value', 'b-value', '';...
            'b_value_std', 'Std. of b-value', '';...
            'a_value', 'a-value', '';...
            'a_value_std', 'Std. of a-value', '';...
            'power_fit', 'Goodness of fit to power-law', '';...
            'max_mag', 'Maximum magnitude at node', 'mag';...
            'Additional_Runs_b_std', 'Additional runs: Std b-value', '';...
            'Additional_Runs_Mc_std', 'Additional runs: Std of Mc', '';...
            'Number_of_Events', 'Number of events in node', ''...
            };
    end
    
    methods
        function obj=cgr_bvalgrid(caller, catalog, varargin)
            
            narginchk(1,inf); 
            ZmapFunction.verify_catalog(catalog);
            obj.RawCatalog=catalog;
            
            if ~isempty(caller)
                obj.Grid = caller.Grid;
                obj.gridOpts = caller.gridopt;
            end
                
            % create bvalgrid
            obj.active_col='b_value';
            % depending on whether parameters were provided, either run automatically, or
            % request input from the user.
            if nargin<3
                % create dialog box, then exit.
                obj.InteractiveSetup();
                
            else
                % run this function without human interaction
                obj.doIt();
                %obj.CheckCatalogPreconditions();
                %obj.Calculate();
                %obj.plot();
                %obj.ModifyGlobals();
            end
        end
        
        function InteractiveSetup(obj)
            % create a dialog that allows user to select parameters neccessary for the calculation
            % if autoCalculate, then do the calculation immediately.
            % if autoPlot, then plot results immediately after calculation
            
            %% make the interface
            zdlg = ZmapDialog();
            %zdlg = ZmapDialog(obj, @obj.doIt);
            
                zdlg.AddBasicHeader('Choose stuff');
                zdlg.AddBasicPopup('mc_choice', 'Magnitude of Completeness (Mc) method:',calc_Mc(),1,...
                                    'Choose the calculation method for Mc');
                gop=obj.gridOpts;
                zdlg.AddGridParameters('gridOpts',gop.dx,gop.dx_units,gop.dy,gop.dy_units,[],'');
                zdlg.AddEventSelectionParameters('EventSelector',ceil(obj.Nmin*1.5), obj.ra,obj.Nmin);
                zdlg.AddBasicCheckbox('useBootstrap','Use Bootstrapping', false, {'nBstSample','nBstSample_label'},...
                    're takes longer, but provides more accurate results');
                zdlg.AddBasicEdit('nBstSample','Number of bootstraps', obj.nBstSample,...
                    'Number of bootstraps to determine Mc');
                zdlg.AddBasicEdit('Nmin','Min. No. of events > Mc', obj.Nmin,...
                    'Min # events greater than magnitude of completeness (Mc)');
                ... obj.basicEdit('fMcFix', 'Fixed Mc (affects only "Fixed Mc")',obj.fMcFix); %'ToolTipString','fixed magnitude of completeness (Mc)'
                zdlg.AddBasicEdit('fMccorr', 'Mc correction for MaxC',obj.fMccorr,...
                    'Correction term to be added to Mc');
            
            [res,okPressed] = zdlg.Create('b-Value Grid Parameters');
            if ~okPressed
                return
            end
            obj.SetValuesFromDialog(res);
            %obj.Grid = obj.ZG.Grid;
            obj.doIt()
        end
        
        function SetValuesFromDialog(obj, res)
            % called when the dialog's OK button is pressed
            
            obj.Nmin=res.Nmin;
            obj.nBstSample=res.nBstSample;
            obj.fMccorr=res.fMccorr;
            obj.ZG.inb1=res.mc_choice;
            obj.EventSelector=res.EventSelector;
            obj.gridOpts=res.gridOpts;
            obj.useBootstrap=res.useBootstrap;
            if isempty(obj.Grid) || obj.gridOpts.CreateGrid
               obj.Grid = ZmapGrid('BvalGrid',obj.gridOpts);
            end
        end
        
        function CheckPreconditions(obj)
            % check to make sure any important conditions are met.
            % for example,
            % - catalogs have what are expected.
            % - required variables exist or have valid values
            if isempty(obj.Grid) || obj.gridOpts.CreateGrid
               obj.Grid = ZmapGrid('BvalGrid',obj.gridOpts);
            end
            assert(~isempty(obj.Grid), 'No grid exists. please create one first');
        end
        
        function results=Calculate(obj)
            % once the properties have been set, either by the constructor or by interactive_setup
            
            % get the grid-size interactively and
            % calculate the b-value in the grid by sorting
            % thge seimicity and selectiong the ni neighbors
            % to each grid point
            map = findobj('Name','Seismicity Map');
            
            %{
            if obj.gridOpts.CreateGrid
                % Select and create grid
                pause(0.5)
                obj.Grid = ZmapGrid('bvalgrid',obj.gridOpts);
            end
            %}
            
            % Overall b-value
            bv =  bvalca3(obj.RawCatalog.Magnitude, obj.ZG.inb1); %ignore all the other outputs of bvalca3
            
            obj.ZG.bo1 = bv;
            
            returnFields = obj.ReturnDetails(:,1);
            returnDesc = obj.ReturnDetails(:,2);
            returnUnits = obj.ReturnDetails(:,3);
            
            [bvg,nEvents,maxDists,maxMag, ll]=gridfun(@calculation_function,obj.RawCatalog,obj.Grid, obj.EventSelector, numel(returnFields));
            
            bvg(:,strcmp('x',returnFields))=obj.Grid.X(:);
            bvg(:,strcmp('y',returnFields))=obj.Grid.Y(:);
            bvg(:,strcmp('Number_of_Events',returnFields))=nEvents;
            bvg(:,strcmp('Radius_km',returnFields))=maxDists;
            bvg(:,strcmp('max_mag',returnFields))=maxMag;
            % adjust to match expectations
            
            
            myvalues = array2table(bvg,'VariableNames', returnFields);
            myvalues.Properties.VariableDescriptions = returnDesc;
            myvalues.Properties.VariableUnits = returnUnits;
            
            kll = ll;
            obj.Result.values=myvalues;
            if nargout
                results=myvalues;
            end
            
             function out=calculation_function(catalog)
                % calulate values at a single point

                % Added to obtain goodness-of-fit to powerlaw value
                % [Mc, Mc90, Mc95, magco, prf]=mcperc_ca3(catalog.Magnitude);
                [~, ~, ~, ~, prf]=mcperc_ca3(catalog.Magnitude);
                
                [Mc_value] = calc_Mc(catalog, obj.ZG.inb1, obj.fBinning, obj.fMccorr);
                l = catalog.Magnitude >= Mc_value-(obj.fBinning/2);
                
                if sum(l) >= obj.Nmin
                    [b_value, b_value_std, a_value] =  calc_bmemag(catalog.subset(l), obj.fBinning);
                    % otherwise, they should be NaN
                else
                    [b_value, b_value_std, a_value] = deal(nan);
                end
                
                % Bootstrap uncertainties FOR EACH CELL
                if obj.useBootstrap
                    % Check Mc from original catalog
                    if sum(l) >= obj.Nmin
                        % following line has only b, but maybe should be catalog.subset(l)
                        [Mc_value, Mc_std, ...
                            b_value, b_value_std, ...
                            a_value, a_value_std, ...
                            Additional_Runs_b_std, Additional_Runs_Mc_std] = ...
                            calc_McBboot(catalog, obj.fBinning, obj.nBstSample, obj.ZG.inb1);
                    else
                        Mc_value = NaN;
                        %fStd_Mc = NaN; fBValue = NaN; fStd_B = NaN; fAValue= NaN; fStd_A= NaN;
                    end
                else
                    % Set standard deviation ofa-value to NaN;
                    a_value_std= NaN; 
                    Mc_std = NaN;
                    Additional_Runs_b_std=NaN;
                    Additional_Runs_Mc_std=NaN;
                end

                mab = max(catalog.Magnitude);
                if isempty(mab); mab = NaN; end

                % Result matrix
                out  = [Mc_value Mc_std nan nan, ... nan's were x and y
                    nan b_value b_value_std a_value a_value_std,... was rd
                    prf mab Additional_Runs_b_std Additional_Runs_Mc_std nan]; % nan was nX
            
            end
        end
       
        function ModifyGlobals(obj)
            obj.ZG.bvg=obj.Result.values;
            obj.ZG.Grid = obj.Grid; %TODO do we really write back the grid?
        end
    end %methods
    
    methods(Static)
        function h=AddMenuItem(parent, caller, catalogfn)
            % create a menu item
            label='Mc, a- and b- value map';
            h=uimenu(parent,'Label',label,'Callback', @(~,~)cgr_bvalgrid(caller, catalogfn()));
        end
        
    end % static methods
    
end %classdef

