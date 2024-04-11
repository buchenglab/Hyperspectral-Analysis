%% Attribution
% =========================================================================
% Author: Mark Cherepashensky
% Ji-Xin Cheng Group @ Boston University Feb. 2024
% Version 0.95
%
% The following code is distributed without any warranty,and without
% implied warranty of merchantability or fitness for a particular purpose.
% Distribution of this work for commercial purposes is prohibited. This
% work can be redistributed and/or modified for non-commercial purposes.
% Publications that use this code or modified instances should credit the
% author(s) appropriately.
% =========================================================================
%% Initialization
ExistingFigs = findall(groot,'Type','figure');
for q = 1:length(ExistingFigs)
    delete(ExistingFigs(q));
end
clearvars; clc;
HyperspectralUI();

%% Central UI
function HyperspectralUI(ScreenSize)
% Central UI for processing hyperspectral images
    % Basic Configuration
    LoadFig = uifigure('Position',ResolutionScaler([(1920-1900)/2 (1080-490)/2 1900 490]),'Name','Hyperspectral Analysis','Resize','off');
    InitializeProgress = uiprogressdlg(LoadFig,'Title','Creating UI','Message','Checking MATLAB requirements and initializing environment.','Indeterminate','on');
    if CheckValidInstalls == 0
        close(InitializeProgress);
        delete(LoadFig);
        return;
    end
    ScreenSize = get(groot,'ScreenSize');

    % Setting up the UI
    uilabel(LoadFig,'Position',[0 LoadFig.Position(4) LoadFig.Position(3) 0]+ResolutionScaler([5 -40 -10 50]),'Text','Hyperspectral Analysis','FontSize',28,'FontWeight','Bold');
    LoadGroup = uitabgroup(LoadFig,'TabLocation','Left','Position',[0 0 LoadFig.Position(3) LoadFig.Position(4)]+ResolutionScaler([0 0 0 -35]));

    % Home tab
    HomeTab = uitab(LoadGroup,'Title','Home');
    PrimaryPanel = uipanel(HomeTab,'Position',ResolutionScaler([10 225 300 215]),'BackgroundColor',[0.6289 0.7734 0.8164]);
    uilabel(PrimaryPanel,'Position',ResolutionScaler([5 185 160 30]),'Text','Primary Data','FontWeight','Bold','FontSize',20);
    PrimaryArray = {};
    ProcessedArray = {};
    ExampleArray = {};
    CoefficientsArray = {};
    Path = '';
    PrimaryLoad = uibutton(PrimaryPanel,'Position',ResolutionScaler([10 140 100 40]),'Text','Set Data Folder','FontSize',14,'WordWrap','on','HorizontalAlignment','Center','ButtonPushedFcn',@(~,~)LoadPrimary());
    SetsCounter = uilabel(PrimaryPanel,'Position',ResolutionScaler([120 165 170 20]),'Text','','FontSize',14);
    uibutton(PrimaryPanel,'Position',ResolutionScaler([120 140 170 25]),'Text','Import Save State','FontSize',14,'ButtonPushedFcn',@(~,~)ImportState());
    uilabel(PrimaryPanel,'Position',ResolutionScaler([10 115 280 20]),'Text','Right Click to Modify:','FontSize',12,'HorizontalAlignment','Center');
    PrimaryTable = uitable(PrimaryPanel,'Position',ResolutionScaler([10 10 280 110]),'ColumnName','Datasets','ColumnEditable',false,'ColumnFormat',{'char'});
    PrimaryTable.ContextMenu = CreateContext(LoadFig,{'Set as Primary Dataset','View Dataset','Delete Dataset'},{@SetPrimaryTable,@ViewPrimaryTable,@DeletePrimaryTable},@(Source,Event)ToggleVisible(Source,Event));
    
    ReferencesPanel = uipanel(HomeTab,'Position',ResolutionScaler([10 10 300 205]),'BackgroundColor',[0.457 0.7266 0.4609]);
    uilabel(ReferencesPanel,'Position',ResolutionScaler([5 175 270 30]),'Text','Chemical Reference Maps','FontWeight','Bold','FontSize',20);
    ReferenceArray = {};
    ReferenceLoad = uibutton(ReferencesPanel,'Position',ResolutionScaler([10 140 280 30]),'Text','Load a Chemical Reference','FontSize',14,'HorizontalAlignment','Center','ButtonPushedFcn',@(~,~)LoadNewRef());
    uilabel(ReferencesPanel,'Position',ResolutionScaler([10 115 280 20]),'Text','Right Click to Modify:','FontSize',12,'HorizontalAlignment','Center');
    ReferenceTable = uitable(ReferencesPanel,'Position',ResolutionScaler([10 10 280 110]),'ColumnName','Reference Maps','ColumnEditable',false,'ColumnFormat',{'char'});
    ReferenceTable.ContextMenu = CreateContext(LoadFig,{'Modify Reference','Delete Reference'},{@ModifyRefTable,@DeleteRefTable},@(Source,Event)ToggleVisible(Source,Event));

    FitPanel = uipanel(HomeTab,'Position',ResolutionScaler([320 240 400 200]),'BackgroundColor',[0.9258 0.7773 0.3984]);
    uilabel(FitPanel,'Position',ResolutionScaler([5 170 300 30]),'Text','Calibrate Spectra Fitting','FontWeight','Bold','FontSize',20);
    uibutton(FitPanel,'Position',ResolutionScaler([10 135 190 30]),'Text','Set Background Reference','FontSize',14,'HorizontalAlignment','Center','ButtonPushedFcn',@(~,~)GetBackgroundFit());
    FitData = {'Background',NaN,NaN;'Background',NaN,NaN};
    AddedFitData = {};
    uilabel(FitPanel,'Position',ResolutionScaler([210 140 65 20]),'Text','Presets:','FontSize',17,'VerticalAlignment','Center');
    FitPresets = uidropdown(FitPanel,'Position',ResolutionScaler([280 140 110 20]),'Items',{'','DMSO','Lipid'},'FontSize',14,'ValueChangedFcn',@(~,~)DisplayFitPresets());
    FitTable = uitable(FitPanel,'Position',ResolutionScaler([10 10 380 120]),'Data',FitData,'ColumnName',{'Source','Frame Number','Wavenumber'},'ColumnEditable',[false true true],'ColumnFormat',{'char','numeric','numeric'},'ColumnWidth',{'auto','auto','auto'});

    ProcessingPanel = uipanel(HomeTab,'Position',ResolutionScaler([320 105 400 125]),'BackgroundColor',[0.8164 0.5312 0.3086]);
    uilabel(ProcessingPanel,'Position',ResolutionScaler([5 95 250 30]),'Text','Processing Techniques','FontWeight','Bold','FontSize',20);
    uilabel(ProcessingPanel,'Position',ResolutionScaler([10 70 200 25]),'Text','Denoising Package:','FontSize',18);
    DenoisingChoice = uidropdown(ProcessingPanel,'Position',ResolutionScaler([200 70 140 20]),'Items',{'BM#D'},'FontSize',13);
    uibutton(ProcessingPanel,'Position',ResolutionScaler([340 70 50 20]),'Text','Run','FontSize',12,'ButtonPushedFcn',@(~,~)LaunchDenoise);
    uilabel(ProcessingPanel,'Position',ResolutionScaler([10 40 200 25]),'Text','Background Removal:','FontSize',18);
    BackgroundChoice = uidropdown(ProcessingPanel,'Position',ResolutionScaler([200 40 140 20]),'Items',{'Binary Mask','Gaussian Blur'},'FontSize',13);
    uibutton(ProcessingPanel,'Position',ResolutionScaler([340 40 50 20]),'Text','Run','FontSize',12,'ButtonPushedFcn',@(~,~)LaunchRemoval);
    uilabel(ProcessingPanel,'Position',ResolutionScaler([10 10 200 25]),'Text','Spectral Unmixing:','FontSize',18);
    UnmixingChoice = uidropdown(ProcessingPanel,'Position',ResolutionScaler([200 10 140 20]),'Items',{'LASSO'},'FontSize',13);
    uibutton(ProcessingPanel,'Position',ResolutionScaler([340 10 50 20]),'Text','Run','FontSize',12,'ButtonPushedFcn',@(~,~)LaunchUnmixing);

    VisualsPanel = uipanel(HomeTab,'Position',ResolutionScaler([730 10 1090 430]),'BackgroundColor',[0.7227 0.582 0.9258]);
    uilabel(VisualsPanel,'Position',ResolutionScaler([5 400 100 30]),'Text','Visuals','FontWeight','Bold','FontSize',20);
    OriginalVisual = uiaxes(VisualsPanel,'Position',ResolutionScaler([10 30 350 350]),'XTick',[],'YTick',[]);
    OriginalLabel = uilabel(VisualsPanel,'Position',ResolutionScaler([10 385 350 20]),'Text','Original Average Image','FontSize',15,'HorizontalAlignment','Center');
    OriginalSizeLabel = uilabel(VisualsPanel,'Position',ResolutionScaler([10 10 350 20]),'Text','','FontSize',15,'HorizontalAlignment','Center');
    ProcessedVisual = uiaxes(VisualsPanel,'Position',ResolutionScaler([365 30 350 350]),'XTick',[],'YTick',[]);
    ProcessedLabel = uilabel(VisualsPanel,'Position',ResolutionScaler([365 385 350 20]),'Text','Processed Average Image','FontSize',15,'HorizontalAlignment','Center');
    ProcessedSizeLabel = uilabel(VisualsPanel,'Position',ResolutionScaler([365 10 350 20]),'Text','','FontSize',15,'HorizontalAlignment','Center');
    axis([OriginalVisual ProcessedVisual],'image');
    colormap(OriginalVisual,'Bone');
    colormap(ProcessedVisual,'Bone');
    SpectraAxes = uiaxes(VisualsPanel,'Position',ResolutionScaler([720 10 360 370]));
    uilabel(VisualsPanel,'Position',ResolutionScaler([740 385 350 20]),'Text','Chemical Reference Spectra','FontSize',15,'HorizontalAlignment','Center');
    ylim(SpectraAxes,[-0.01 1.01])
    xlabel(SpectraAxes,sprintf('Wavenumber (cm^{-1})'),'FontSize',14)
    ylabel(SpectraAxes,'Normalized Intensity','FontSize',14)
    grid(SpectraAxes,'on')

    AdjustmentsPanel = uipanel(HomeTab,'Position',ResolutionScaler([320 10 400 85]),'BackgroundColor',[0.7656 0.5039 0.4688]);
    uilabel(AdjustmentsPanel,'Position',ResolutionScaler([5 55 390 30]),'Text','Analysis & Adjustments','FontWeight','Bold','FontSize',20);
    uibutton(AdjustmentsPanel,'Position',ResolutionScaler([10 10 180 40]),'Text','Quantification Calculations','FontSize',14,'WordWrap','on','ButtonPushedFcn',@(~,~)Quantifications());
    uibutton(AdjustmentsPanel,'Position',ResolutionScaler([210 10 180 40]),'Text','Contrast/Brightness & Final Export','FontSize',14,'WordWrap','on','ButtonPushedFcn',@(~,~)ExportAdjusting());

    fontname(LoadFig,GetFont());
    close(InitializeProgress);
    uiwait(LoadFig);

    % Context menu functions
    function SetPrimaryTable(~,Event)
    % Sets different primary visual used via ExampleArray
        SelectedRow = Event.InteractionInformation.Row;
        if isempty(SelectedRow)
            return;
        end
        ExampleArray = {PrimaryArray{SelectedRow,1:3} ProcessedArray{SelectedRow,2:3}};
        UpdateVisualReferences({OriginalVisual,ExampleArray{5}(:,:,1),OriginalVisual.Position(3),OriginalLabel,OriginalSizeLabel},{ProcessedVisual,ExampleArray{5}(:,:,1),ProcessedVisual.Position(3),ProcessedLabel,ProcessedSizeLabel});
        if size(ExampleArray{5},3) > 2
            DisplayComposite(ProcessedVisual,ExampleArray{5}(:,:,2:end),ReferenceArray(:,6),'Auto');
            ProcessedLabel.Text = 'Processed Unmixed Image';
        elseif size(ExampleArray{5},3) > 1
            DisplayColored(ProcessedVisual,ExampleArray{5}(:,:,2),ReferenceArray{1,6});
            ProcessedLabel.Text = sprintf('Processed %s Image',ReferenceArray{1,4});
        end
    end

    function ViewPrimaryTable(~,Event)
    % Views primary visual 
        SelectedRow = Event.InteractionInformation.Row;
        if isempty(SelectedRow)
            return;
        end
        VisualViewer = uifigure('Position',[(ScreenSize(3)-840)/2 (ScreenSize(4)-500)/2 840 500],'Name',sprintf('Visualizer: %s',PrimaryArray{SelectedRow,1}));
        VisualPanel = uipanel(VisualViewer,'Position',[0 0 840 500],'BackgroundColor',[0.7227 0.582 0.9258]);
        uilabel(VisualPanel,'Position',[(VisualPanel.Position(3)-820)/2 460 820 30],'Text',PrimaryArray{SelectedRow,1},'FontWeight','Bold','FontAngle','Italic','FontSize',18);
        FirstVisual = uiaxes(VisualPanel,'Position',[10 30 400 400],'XTick',[],'YTick',[]);
        FirstLabel = uilabel(VisualPanel,'Position',[10 430 400 20],'Text','Average of Original','FontSize',15,'FontWeight','Bold','HorizontalAlignment','Center');
        FirstSizeLabel = uilabel(VisualPanel,'Position',[10 10 400 20],'Text','','FontSize',15,'HorizontalAlignment','Center');
        SecondVisual = uiaxes(VisualPanel,'Position',[430 30 400 400],'XTick',[],'YTick',[]);
        SecondLabel = uilabel(VisualPanel,'Position',[430 430 400 20],'Text','Processed Average Image','FontSize',15,'FontWeight','Bold','HorizontalAlignment','Center');
        SecondSizeLabel = uilabel(VisualPanel,'Position',[430 10 400 20],'Text','','FontSize',15,'HorizontalAlignment','Center');
        axis([FirstVisual SecondVisual],'image');
        colormap(FirstVisual,'Bone');
        colormap(SecondVisual,'Bone');
        UpdateVisualReferences({FirstVisual,PrimaryArray{SelectedRow,3}(:,:,1),FirstVisual.Position(3),FirstLabel,FirstSizeLabel},{SecondVisual,ProcessedArray{SelectedRow,3}(:,:,1),SecondVisual.Position(3),SecondLabel,SecondSizeLabel});
        if size(ExampleArray{5},3) > 2
            DisplayComposite(SecondVisual,ProcessedArray{SelectedRow,3}(:,:,2:end),ReferenceArray(:,6),'Auto');
            SecondLabel.Text = 'Processed Unmixed Image';
        elseif size(ExampleArray{5},3) > 1
            DisplayColored(SecondVisual,ProcessedArray{SelectedRow,3}(:,:,2),ReferenceArray{1,6});
            SecondLabel.Text = sprintf('Processed %s Image',ReferenceArray{1,4});
        end
        fontname(VisualViewer,GetFont());
    end

    function DeletePrimaryTable(~,Event)
    % Deletes primary data set
        SelectedRow = Event.InteractionInformation.Row;
        if isempty(SelectedRow)
            return;
        elseif height(PrimaryArray) == 1
            PrimaryArray = {};
            ProcessedArray = {};
            ExampleArray = {};
            PrimaryTable.Data = {};
            SetsCounter.Text = 'No Active Datasets';
            imagesc(OriginalVisual,0);
            imagesc(ProcessedVisual,0);
            OriginalSizeLabel.Text = '';
            ProcessedSizeLabel.Text = '';
            return;
        end
        if isequal(ExampleArray,{PrimaryArray{SelectedRow,1:3} ProcessedArray{SelectedRow,2:3}}) && SelectedRow == 1
            ExampleArray = {PrimaryArray{2,1:3} ProcessedArray{2,2:3}};
            UpdateVisualReferences({OriginalVisual,ExampleArray{5}(:,:,1),OriginalVisual.Position(3),OriginalLabel,OriginalSizeLabel},{ProcessedVisual,ExampleArray{5}(:,:,1),ProcessedVisual.Position(3),ProcessedLabel,ProcessedSizeLabel});
        elseif isequal(ExampleArray,{PrimaryArray{SelectedRow,1:3} ProcessedArray{SelectedRow,2:3}})
            ExampleArray = {PrimaryArray{1,1:3} ProcessedArray{1,2:3}};
            UpdateVisualReferences({OriginalVisual,ExampleArray{5}(:,:,1),OriginalVisual.Position(3),OriginalLabel,OriginalSizeLabel},{ProcessedVisual,ExampleArray{5}(:,:,1),ProcessedVisual.Position(3),ProcessedLabel,ProcessedSizeLabel});
        end
        PrimaryArray(SelectedRow,:) = [];
        ProcessedArray(SelectRow,:) = [];
        PrimaryTable.Data = PrimaryArray(:,1);
        SetsCounter.Text = sprintf('%d Datasets Active',height(PrimaryArray));
        if size(ExampleArray{5},3) > 2
            DisplayComposite(ProcessedVisual,ExampleArray{5}(:,:,2:end),ReferenceArray(:,6),'Auto');
            ProcessedLabel.Text = 'Processed Unmixed Image';
        elseif size(ExampleArray{5},3) > 1
            DisplayColored(ProcessedVisual,ExampleArray{5}(:,:,2),ReferenceArray{1,6});
            ProcessedLabel.Text = sprintf('Processed %s Image',ReferenceArray{1,4});
        end
    end
    
    function ModifyRefTable(~,Event)
    % Adjusts chemical reference for that selected row
        SelectedRow = Event.InteractionInformation.Row;
        if isempty(SelectedRow)
            return;
        end
        try
            ReferenceArray(SelectedRow,:) = ChemicalRefParameters(ScreenSize,ReferenceArray(SelectedRow,:),ReferenceArray,LoadFig,'Ref');
        catch
            return;
        end
        ReferenceTable.Data = ReferenceArray(:,4);
        GraphSpectra(SpectraAxes);
        if ~isempty(ExampleArray) && size(ExampleArray{5},3) > 2
            DisplayComposite(ProcessedVisual,ExampleArray{5}(:,:,2:end),ReferenceArray(:,6),'Auto');
        elseif ~isempty(ExampleArray) && size(ExampleArray{5},3) > 1
            DisplayColored(ProcessedVisual,ExampleArray{5}(:,:,2),ReferenceArray{1,6});
        end
    end

    function DeleteRefTable(~,Event)
    % Deletes reference data set
        SelectedRow = Event.InteractionInformation.Row;
        if isempty(SelectedRow)
            return;
        elseif height(ReferenceArray) == 1
            ReferenceArray = {};
            ReferenceTable.Data = {};
            hold(SpectraAxes,'off');
            legend(SpectraAxes,'off');
            plot(SpectraAxes,0,0,'LineStyle','None','Marker','None');
            ReferenceLoad.Text = 'Load a Chemical Reference';
            return;
        end
        ReferenceArray(SelectedRow,:) = [];
        ReferenceTable.Data = ReferenceArray(:,4);
        GraphSpectra(SpectraAxes);
    end

    % Home functions
    function LoadPrimary()
    % Prompts the user for the directory with the primary datasets
        ToggleChildrenEnable(LoadFig);
        [FormatSelector,LoadFormat,FormatConfirm] = FormatUI(ScreenSize);
        FormatConfirm.ButtonPushedFcn = @(~,~)LoadFromDirectory;
        uiwait(FormatSelector);
        ToggleChildrenEnable(LoadFig);

        function LoadFromDirectory()
        % Loads directory files
            try
                DataFormat = LoadFormat.Value;
                uiresume(FormatSelector)
                close(FormatSelector)
                Path = uigetdir('','Select directory for primary dataset(s)');
                LoadFig.Visible = 'off';
                LoadFig.Visible = 'on';
                if strcmp(DataFormat,'Plain Text Array (*.txt)')
                    AllFiles = dir(fullfile(Path,'*.txt'));
                elseif strcmp(DataFormat,'Tag Image File (*.tif, *.tiff)')
                    AllFiles = [dir(fullfile(Path,'*.tif')),dir(fullfile(Path,'*.tiff'))];
                end
            catch
                uialert(LoadFig,'Loading encountered an error. If this was unexpected, please verify the integrity of the directory.','Load Error','Icon','Error');
                return;
            end
            if isempty(AllFiles)
                uialert(LoadFig,sprintf('The directory you selected had no files. Verify the file type in the Format Selector and the correct directory.'),'No Files','Icon','Warning');
                return;
            end
            PrimaryArray = cell(length(AllFiles),3);
            ProcessedArray = cell(length(AllFiles),3);
            Progress = uiprogressdlg(LoadFig,'Title','Loading Data','Message','Beginning data load');
            CompletedFiles = -1;
            if length(AllFiles) > 5 || ~isempty(gcp('nocreate'))
                Queue = parallel.pool.DataQueue;
                afterEach(Queue,@(~)UpdateProgress());
                ParPool = gcp;
                Futures = cell(1,length(AllFiles));
                for q = 1:length(AllFiles)
                    PrimaryArray{q,1} = AllFiles(q).name;
                    Futures{q} = parfeval(ParPool,@LoadFile,1,fullfile(Path,AllFiles(q).name),DataFormat,Queue);
                end
                for q = 1:length(AllFiles)
                    PrimaryArray{q,2} = fetchOutputs(Futures{q});
                end
            else
                for q = 1:length(AllFiles)
                    PrimaryArray{q,1} = AllFiles(q).name;
                    PrimaryArray{q,2} = LoadFile(fullfile(Path,AllFiles(q).name),DataFormat);
                    UpdateProgress();
                end
            end
            try
                PrimaryArray(:,1) = cellfun(@(X)regexprep(X,'\.(txt|tiff|tif)$',''),PrimaryArray(:,1),'UniformOutput',false);
                if strcmp(DataFormat,'Plain Text Array (*.txt)')
                    Progress.Message = 'Finalizing data loading';
                    Progress.Value = 1;   
                    PrimaryArray = TxtStackShapeUI(ScreenSize,PrimaryArray,'MainData');
                    ProcessedArray = PrimaryArray;
                    close(Progress)
                elseif strcmp(DataFormat,'Tag Image File (*.tif, *.tiff)')
                    Progress.Message = 'Finalizing data loading';
                    ProcessedArray(:,2) = PrimaryArray(:,2);
                    HeldAverage = cell(size(PrimaryArray,1),1);
                    parfor p = 1:size(PrimaryArray,1)
                        HeldAverage{p} = mean(PrimaryArray{p,2},3);
                    end
                    [PrimaryArray(:,3),ProcessedArray(:,3)] = deal(HeldAverage);
                    clear HeldAverage;
                    Progress.Value = 1;
                    close(Progress)
                end
                LoadFig.Visible = 'off';
                LoadFig.Visible = 'on';
                clear AllFiles Futures Queue CompletedFiles;
            catch
                uialert(LoadFig,'Reshaping was quit or failed. If this was unexpected, enter debugging mode before trying again.','Reshaping Error','Icon','Error');
                close(Progress)
                return;
            end
            ExampleArray = {PrimaryArray{1,1:3},PrimaryArray{1,2:3}};
            UpdateVisualReferences({OriginalVisual,ExampleArray{5}(:,:,1),OriginalVisual.Position(3),OriginalLabel,OriginalSizeLabel},{ProcessedVisual,ExampleArray{5}(:,:,1),ProcessedVisual.Position(3),ProcessedLabel,ProcessedSizeLabel});
            PrimaryTable.Data = PrimaryArray(:,1);
            SetsCounter.Text = sprintf('%d Datasets Loaded',height(PrimaryArray));
            PrimaryLoad.Text = 'Set New Data Folder';
            PrimaryLoad.Tooltip = 'Clears all existing datasets and loads from a new folder.';

            function UpdateProgress()
                CompletedFiles = CompletedFiles+1;
                Progress.Message = sprintf('Loading files from selected folder (%d/%d)',CompletedFiles,length(AllFiles));
                Progress.Value = CompletedFiles/length(AllFiles);
            end
        end
    end

    function ImportState()
    % Future importing interface for importing data states
        uialert(LoadFig,'Importing save states is currently in development. Thank you for your patience.','State Import WIP','Icon','Error');
    end

    % Reference functions
    function LoadNewRef()
    % Loads new chemical reference
        ToggleChildrenEnable(LoadFig);
        [FormatSelector,LoadFormat,FormatConfirm] = FormatUI(ScreenSize);
        FormatConfirm.ButtonPushedFcn = @(~,~)LoadRefFile(FormatSelector,LoadFormat,'Ref');
        uiwait(FormatSelector);
        if ~isempty(ReferenceArray)
            ReferenceLoad.Text = 'Load Additional Chemical Reference';
        end
        ToggleChildrenEnable(LoadFig);
    end

    function LoadRefFile(Selector,Format,Style)
    % Loads chemical reference file
        DataFormat = Format.Value;
        uiresume(Selector)
        close(Selector)
        if strcmp(DataFormat,'Plain Text Array (*.txt)')
            [FileName,FilePath] = uigetfile({'*.txt','Plain Text Array (*.txt)'},'Select chemical reference file');
        elseif strcmp(DataFormat,'Tag Image File (*.tif, *.tiff)')
            [FileName,FilePath] = uigetfile({'*.tif;*.tiff','Tag Image File (*.tif, *.tiff)'},'Select chemical reference file');
        end
        LoadFig.Visible = 'off';
        LoadFig.Visible = 'on';
        if isnumeric(FileName) || isnumeric(FilePath)
            uialert(LoadFig,'The chemical reference file selection was invalid. Verify the file type in the Format Selector and the target file.','Invalid Chemical Reference File','Icon','Error');
            return;
        end
        try
            RefProgress = uiprogressdlg(LoadFig,'Title','Loading chemical reference data','Message','Loading reference','Indeterminate','on');
            if strcmp(DataFormat,'Plain Text Array (*.txt)')
                LoadedRef = LoadFile(fullfile(FilePath,FileName),DataFormat);
                RefProgress.Message = 'Reshaping .txt files';
                RefFile = TxtStackShapeUI(ScreenSize,{FileName,LoadedRef},'ReferenceData');
            elseif strcmp(DataFormat,'Tag Image File (*.tif, *.tiff)')
                RefFile = {FileName,LoadFile(fullfile(FilePath,FileName),DataFormat)};
            end
        catch
            uialert(LoadFig,'Reshaping was quit or failed. If this was unexpected, verify file formats and try again in debugging mode.','Reshaping Error','Icon','Error');
            close(RefProgress)
            return;
        end
        try
            RefProgress.Message = 'Setting reference parameters (see pop-up window)';
            [RefFile,NewFits] = ChemicalRefParameters(ScreenSize,RefFile,ReferenceArray,LoadFig,Style);
            if strcmp(Style,'Ref')
                ReferenceArray = [ReferenceArray; RefFile];
                AddedFitData = [AddedFitData;NewFits];
                ReferenceTable.Data = ReferenceArray(:,4);
            elseif strcmp(Style,'Fit')
                FitData = NewFits;
                FitPresets.Items = {'','Blank','DMSO','Lipid'};
                FitPresets.Value = '';
            end
            FitTable.Data = [FitData;AddedFitData];
            GraphSpectra(SpectraAxes);
            close(RefProgress);
        catch
            uialert(LoadFig,'The chemical reference mapping interface unexpectedly closed.','Chemical Reference Mapping Closed','Icon','Error');
            return;
        end
    end

    % Fit functions
    function GetBackgroundFit()
    % Loads reference for background peak(s) selection
        ToggleChildrenEnable(ReferencesPanel,FitPanel,AdjustmentsPanel);
        [FormatSelector,LoadFormat,FormatConfirm] = FormatUI(ScreenSize);
        FormatConfirm.ButtonPushedFcn = @(~,~)LoadRefFile(FormatSelector,LoadFormat,'Fit');
        uiwait(FormatSelector);
        ToggleChildrenEnable(ReferencesPanel,FitPanel,AdjustmentsPanel);
    end

    function WaveCalibrate = GraphSpectra(SpectrumAxes)
    % Graphs spectra by wavenumber polynomial fitting with calibrated values
        if isempty(ReferenceArray) || any(xor(isnan(cell2mat(FitTable.Data(:,2))),isnan(cell2mat(FitTable.Data(:,3))))) || (all(isnan(cell2mat(FitTable.Data(:,2)))) && all(isnan(cell2mat(FitTable.Data(:,3)))))
            return;
        else
            WaveCalibrate = polyval(polyfit(abs(round(cell2mat(FitTable.Data(:,2)))),abs(round(cell2mat(FitTable.Data(:,3)))),1),1:length(ReferenceArray{1,3}));
            for g = 1:height(ReferenceArray)
                plot(SpectrumAxes,WaveCalibrate,normalize(ReferenceArray{g,3},'Range'),'LineWidth',2,'Color',ReferenceArray{g,6},'DisplayName',ReferenceArray{g,4});
                hold(SpectrumAxes,'on');
            end
            hold(SpectrumAxes,'off');
            legend(SpectrumAxes,'Location','Best','FontSize',9);
        end
    end

    function DisplayFitPresets()
    % Set presets for FitData primary values
        switch FitPresets.Value
            case 'Blank'
                Changes = {'Background',NaN,NaN;'Background',NaN,NaN};
            case 'DMSO'
                Changes = {'DMSO',40,2912;'DMSO',77,2997};
            case 'Lipid'
                Changes = {'Lipid',13,2853;'Lipid',80,3002};
        end
        if exist('Changes','var')
            FitData = Changes;
        end
        FitTable.Data = [FitData;AddedFitData];
        FitPresets.Items = {'Blank','DMSO','Lipid'};
        GraphSpectra(SpectraAxes);
    end

    % Processing functions
    function LaunchDenoise()
    % Launches the UI tab for denoising
        ToggleChildrenEnable(PrimaryPanel,ProcessingPanel,AdjustmentsPanel);
        if isempty(PrimaryArray) || isempty(ProcessedArray) || isempty(ExampleArray)
            uialert(LoadFig,'There is no data! Please load data before attempting background removal.','No Data','Icon','Error');
            ToggleChildrenEnable(PrimaryPanel,ProcessingPanel,AdjustmentsPanel);
            return;
        else
            if strcmp(DenoisingChoice.Value,'BM#D')
                uialert(LoadFig,'The BM#D UI is undergoing reconfiguration to comply with distribution rights. Thank you for your patience.','BM#D Adjustments WIP','Icon','Error');
                ToggleChildrenEnable(PrimaryPanel,ProcessingPanel,AdjustmentsPanel);
            end
        end
    end

    function LaunchRemoval()
    % Launches the UI tab for background removal
        ToggleChildrenEnable(PrimaryPanel,ProcessingPanel,AdjustmentsPanel);
        if isempty(PrimaryArray) || isempty(ProcessedArray) || isempty(ExampleArray)
            uialert(LoadFig,'There is no data! Please load data before attempting background removal.','No Data','Icon','Error');
            ToggleChildrenEnable(PrimaryPanel,ProcessingPanel,AdjustmentsPanel);
            return;
        end
        PreviousExample = ExampleArray(:,4:5);
        SubtractTab = uitab(LoadGroup,'Title','Subtract');
        OriginalSubtractPanel = uipanel(SubtractTab,'Position',ResolutionScaler([10 10 430 430]),'BackgroundColor',[0.5234 0.8086 0.75]);
        uilabel(OriginalSubtractPanel,'Position',[0 OriginalSubtractPanel.Position(4) 0 0]+ResolutionScaler([5 -30 250 30]),'Text','Current Data','FontWeight','Bold','FontSize',20);
        OriginalSubtractVisual = uiaxes(OriginalSubtractPanel,'Position',ResolutionScaler([20 10 390 390]),'XTick',[],'YTick',[]);
        
        SubtractOperationsPanel = uipanel(SubtractTab,'Position',ResolutionScaler([450 10 920 430]),'BackgroundColor',[0.4414 0.5977 0.8672]);
        uilabel(SubtractOperationsPanel,'Position',[0 OriginalSubtractPanel.Position(4) 0 0]+ResolutionScaler([5 -30 800 30]),'Text',sprintf('%s Parameters',BackgroundChoice.Value),'FontWeight','Bold','FontSize',20);
        ConfirmSubtract = uibutton(SubtractOperationsPanel,'Position',([SubtractOperationsPanel.Position(3) 0 0 0]+ResolutionScaler([-550 10 550 30]))./([2 1 1 1]),'Text',sprintf('Confirm Parameters for %s Background Removal',BackgroundChoice.Value),'FontWeight','Bold','FontSize',16);
        uibutton(SubtractOperationsPanel,'Position',ResolutionScaler([780 10 130 30]),'Text','Cancel Current Background Removal','WordWrap','On','FontAngle','Italic','FontSize',10,'Tooltip','Cancel and close subtraction tab.','ButtonPushedFcn',@(~,~)CancelSubtraction);
        uilabel(SubtractOperationsPanel,'Position',[0 SubtractOperationsPanel.Position(4) 0 0]+ResolutionScaler([810 -25 100 20]),'Text',sprintf('%d Datasets',height(PrimaryArray)),'FontSize',14,'HorizontalAlignment','Right','VerticalAlignment','Top');
        SubtractMask = uiaxes(SubtractOperationsPanel,'Position',ResolutionScaler([10 50 350 350]),'XTick',[],'YTick',[]);
        
        UpdatedSubtractPanel = uipanel(SubtractTab,'Position',ResolutionScaler([1380 10 430 430]),'BackgroundColor',[0.4648 0.4766 0.8477]);
        uilabel(UpdatedSubtractPanel,'Position',[0 UpdatedSubtractPanel.Position(4) 0 0]+ResolutionScaler([5 -30 250 30]),'Text','Updated Data','FontWeight','Bold','FontSize',20);
        UpdatedSubtractVisual = uiaxes(UpdatedSubtractPanel,'Position',ResolutionScaler([20 10 390 390]),'XTick',[],'YTick',[]);
        axis([OriginalSubtractVisual SubtractMask UpdatedSubtractVisual],'image');
        colormap(OriginalSubtractVisual,'Bone');
        colormap(SubtractMask,'Copper');
        colormap(UpdatedSubtractVisual,'Bone');
        UpdateVisualReferences({OriginalSubtractVisual,ExampleArray{5}(:,:,1),OriginalSubtractVisual.Position(3),'',''},{UpdatedSubtractVisual,ExampleArray{5}(:,:,1),UpdatedSubtractVisual.Position(3),'',''}, ...
            {SubtractMask,ones(size(ExampleArray{5}(:,:,1),[1,2])),SubtractMask.Position(3),'',''});
        if strcmp(BackgroundChoice.Value,'Binary Mask')
            ConfirmSubtract.ButtonPushedFcn = @(~,~)ConfirmBinaryMask;
            BinaryHistogram = uiaxes(SubtractOperationsPanel,'Position',ResolutionScaler([370 120 540 280]));%,'XTick',[]);
            FilteredCounts = UniqueNonZeroCounts(ExampleArray{5}(:,:,1));
            BH = histogram(BinaryHistogram,FilteredCounts,'FaceColor',SubtractOperationsPanel.BackgroundColor,'NumBins',20);
            ylim(BinaryHistogram,[0 max(BH.Values)]);
            xlim(BinaryHistogram,[min(FilteredCounts,[],'All') max(FilteredCounts,[],'All')]);
            grid(BinaryHistogram,'on');
            BH.NumBins = 50;
            title(BinaryHistogram,'Intensity Counts');
            BinarySlider = uislider(GridSliderPanel(SubtractOperationsPanel,ResolutionScaler([490 50 410 60]),SubtractOperationsPanel.BackgroundColor),'Limits',[min(min(FilteredCounts,[],'All'),0) max(FilteredCounts,[],'All')], ...
                'Value',BH.BinEdges(find(BH.Values(find(BH.Values==max(BH.Values),1,'first'):end)<20,1,'first')+find(BH.Values==max(BH.Values),1,'first')-1)+BH.BinWidth/2,'ValueChangedFcn',@(Source,~)SlideBinary(Source));
            SlideLine = xline(BinaryHistogram,BinarySlider.Value,'Color',[0.7422 0.4844 0.918],'LineWidth',2);
            BinaryInput = uieditfield(SubtractOperationsPanel,'Numeric','Position',ResolutionScaler([400 70 80 20]),'FontSize',14,'Value',BinarySlider.Value,'ValueChangedFcn',@(Source,~)SlideBinary(Source));
            SlideBinary(BinarySlider);
        elseif strcmp(BackgroundChoice.Value,'Gaussian Blur')
            ConfirmSubtract.ButtonPushedFcn = @(~,~)ConfirmGaussianBlur;
            GaussianHistogram = uiaxes(SubtractOperationsPanel,'Position',ResolutionScaler([370 120 540 280]),'XTick',[]);
            grid(GaussianHistogram,'on');
            title(GaussianHistogram,'Intensity Frequency Comparison');
            Sigma = [0.5 0.5 0.5];
            Kernel = [3 3 3];
            STip = sprintf('Sigma values must be positive numbers.\n\nScalar uses same value for all directions (2 for 2D Gaussian and 3 for 3D Gaussian).\n\nVector uses a unique value for each direction.');
            KTip = sprintf('Kernel size values must be positive odd integers.\n\nDefault uses 2*ceil(2*σ+1) for each σ value\n\nScalar uses the same size for all directions\n\nVector uses a unique value for each direction (2 for 2D Gaussian and 3 for 3D Gaussian).');
            uilabel(SubtractOperationsPanel,'Position',ResolutionScaler([390 100 100 20]),'Text','Blur Domain:','FontSize',14,'VerticalAlignment','Center','FontWeight','Bold');
            uilabel(SubtractOperationsPanel,'Position',ResolutionScaler([610 100 100 20]),'Text','Dimensions:','FontSize',14,'VerticalAlignment','Center','FontWeight','Bold');
            uilabel(SubtractOperationsPanel,'Position',ResolutionScaler([390 75 100 20]),'Text','Sigma Value:','FontSize',14,'VerticalAlignment','Center','FontWeight','Bold');
            uilabel(SubtractOperationsPanel,'Position',ResolutionScaler([390 50 100 20]),'Text','Filter Kernel:','FontSize',14,'VerticalAlignment','Center','FontWeight','Bold');
            FilterType = uidropdown(SubtractOperationsPanel,'Position',ResolutionScaler([500 100 100 20]),'Items',{'Spatial','Frequency'},'FontSize',13,'ValueChangedFcn',@(~,~)PreviewGaussian());
            FilterDimension = uidropdown(SubtractOperationsPanel,'Position',ResolutionScaler([710 100 190 20]),'Items',{'2D Gaussian','3D Gaussian'},'FontSize',13,'ValueChangedFcn',@(~,~)SigmaDisplay());
            SigmaType = uidropdown(SubtractOperationsPanel,'Position',ResolutionScaler([500 75 100 20]),'Items',{'Scalar','Vector'},'FontSize',13,'ValueChangedFcn',@(~,~)SigmaDisplay(),'ToolTip',STip);
            SizeType = uidropdown(SubtractOperationsPanel,'Position',ResolutionScaler([500 50 100 20]),'Items',{'Default','Scalar','Vector'},'FontSize',13,'ValueChangedFcn',@(~,~)SizeDisplay(),'ToolTip',KTip);
            FirstSigmaLabel = uilabel(SubtractOperationsPanel,'Position',ResolutionScaler([610 75 20 20]),'Text','σ:','FontSize',14,'VerticalAlignment','Center','FontWeight','Bold','ToolTip',STip);
            FirstSigmaField = uieditfield(SubtractOperationsPanel,'Numeric','Position',ResolutionScaler([630 75 70 20]),'FontSize',13,'ValueChangedFcn',@(Source,Event)SubtractFieldCheck(Source,Event),'Value',0.5,'ToolTip',STip);
            SecondSigmaLabel = uilabel(SubtractOperationsPanel,'Position',ResolutionScaler([710 75 20 20]),'Text','Y:','FontSize',14,'VerticalAlignment','Center','FontWeight','Bold','Visible','off','ToolTip',STip);
            SecondSigmaField = uieditfield(SubtractOperationsPanel,'Numeric','Position',ResolutionScaler([730 75 70 20]),'FontSize',13,'ValueChangedFcn',@(Source,Event)SubtractFieldCheck(Source,Event),'Value',0.5,'Visible','off','ToolTip',STip);
            ThirdSigmaLabel = uilabel(SubtractOperationsPanel,'Position',ResolutionScaler([810 75 20 20]),'Text','Z:','FontSize',14,'VerticalAlignment','Center','FontWeight','Bold','Visible','off','ToolTip',STip);
            ThirdSigmaField = uieditfield(SubtractOperationsPanel,'Numeric','Position',ResolutionScaler([830 75 70 20]),'FontSize',13,'ValueChangedFcn',@(Source,Event)SubtractFieldCheck(Source,Event),'Value',0.5,'Visible','off','ToolTip',STip);
            FirstSizeLabel = uilabel(SubtractOperationsPanel,'Position',ResolutionScaler([610 50 20 20]),'Text','N:','FontSize',14,'VerticalAlignment','Center','FontWeight','Bold','ToolTip',KTip);
            FirstSizeField = uieditfield(SubtractOperationsPanel,'Numeric','Position',ResolutionScaler([630 50 70 20]),'FontSize',13,'ValueChangedFcn',@(Source,Event)SubtractFieldCheck(Source,Event),'Value',3,'ToolTip',KTip);
            SecondSizeLabel = uilabel(SubtractOperationsPanel,'Position',ResolutionScaler([710 50 20 20]),'Text','Y:','FontSize',14,'VerticalAlignment','Center','FontWeight','Bold','Visible','off','ToolTip',KTip);
            SecondSizeField = uieditfield(SubtractOperationsPanel,'Numeric','Position',ResolutionScaler([730 50 70 20]),'FontSize',13,'ValueChangedFcn',@(Source,Event)SubtractFieldCheck(Source,Event),'Value',3,'Visible','off','ToolTip',KTip);
            ThirdSizeLabel = uilabel(SubtractOperationsPanel,'Position',ResolutionScaler([810 50 20 20]),'Text','Z:','FontSize',14,'VerticalAlignment','Center','FontWeight','Bold','Visible','off','ToolTip',KTip);
            ThirdSizeField = uieditfield(SubtractOperationsPanel,'Numeric','Position',ResolutionScaler([830 50 70 20]),'FontSize',13,'ValueChangedFcn',@(Source,Event)SubtractFieldCheck(Source,Event),'Value',3,'Visible','off','ToolTip',KTip);
            PreviewGaussian();
        end
        fontname(LoadFig,GetFont());
        LoadGroup.SelectedTab = SubtractTab;

        function SlideBinary(Source)
        % Change masking and histogram labeling
            switch Source
                case BinarySlider
                    BinaryInput.Value = BinarySlider.Value;
                case BinaryInput
                    if BinaryInput.Value < BinarySlider.Limits(1) || BinaryInput.Value > BinarySlider.Limits(2)
                        uialert(LoadFig,sprintf('%f is not a valid entry. Threshold values must be between the image intensity range from %f to %f. Reverting to previous entry.',BinaryInput.Value,BinarySlider.Limits(1),BinarySlider.Limits(2)),'Invalid Binary Mask Threshold','Icon','Error');
                        BinaryInput.Value = BinarySlider.Value;
                        return;
                    end
                    BinarySlider.Value = BinaryInput.Value;   
            end
            SlideLine.Value = BinarySlider.Value;
            [UpdatedPreview,CreatedMask] = BinaryMaskSubtraction(ExampleArray(1,4:5));
            imagesc(SubtractMask,CreatedMask{1}(:,:,1));
            imagesc(UpdatedSubtractVisual,UpdatedPreview{1,2});
        end

        function [OutArray,CurrentMask] = BinaryMaskSubtraction(InsertArray)
        % Performs binary mask operation
            for p = height(InsertArray):-1:1
                CurrentMask{p} = InsertArray{p,2}(:,:,1)<BinarySlider.Value;
                SpectrumMask = mean(InsertArray{p,1}.*repmat(CurrentMask{p},[1,1,size(InsertArray{p,1},3)]),[1,2]);
                OutArray{p,1} = InsertArray{p,1}-SpectrumMask(ones(1,size(InsertArray{p,1},1)),ones(1,size(InsertArray{p,1},2)),:);
                OutArray{p,2}(:,:,1) = mean(OutArray{p,1},3);
            end
        end

        function ConfirmBinaryMask()
        % Confirms binary mask parameters and applies to all data sets
            BinaryProgress = uiprogressdlg(LoadFig,'Title','Subtracting binary masks','Message','Binary mask background removal ongoing','Indeterminate','on');
            ProcessedArray(:,2:3) = BinaryMaskSubtraction(ProcessedArray(:,2:3));
            ExampleArray(:,4:5) = BinaryMaskSubtraction(ExampleArray(:,4:5));
            BinaryProgress.Message = 'Finished subtraction!';
            pause(0.1); 
            close(BinaryProgress);
            EndSubtract();
        end

        function [OutArray,Heatmap] = Gaussian2D(InsertArray)
        % Performs 2D Gaussian blurring
            for p = height(InsertArray):-1:1
                for h = size(InsertArray{p,1},3):-1:1
                    OutArray{p,1}(:,:,h) = imgaussfilt(InsertArray{p,1}(:,:,h),Sigma(1:2),'FilterSize',Kernel(1:2),'FilterDomain',lower(FilterType.Value));
                end
                OutArray{p,2}(:,:,1) = mean(OutArray{p,1},3);
                Heatmap{p} = abs(mean(InsertArray{p,1}-OutArray{p,1},3));
            end
        end

        function [OutArray,Heatmap] = Gaussian3D(InsertArray)
        % Performs 2D Gaussian blurring
            for p = height(InsertArray):-1:1
                OutArray{p,1} = imgaussfilt3(InsertArray{p,1},Sigma(1:3),'FilterSize',Kernel(1:3),'FilterDomain',lower(FilterType.Value));
                OutArray{p,2}(:,:,1) = mean(OutArray{p,1},3);
                Heatmap{p} = abs(mean(InsertArray{p,1}-OutArray{p,1},3));
            end
        end

        function PreviewGaussian()
        % Perform Gaussian operations for the preview in the UI
            if strcmp(FilterDimension.Value,'2D Gaussian')
                [UpdatedPreview,Maps] = Gaussian2D(ExampleArray(1,4:5));               
            elseif strcmp(FilterDimension.Value,'3D Gaussian')
                [UpdatedPreview,Maps] = Gaussian3D(ExampleArray(1,4:5));
            end
            imagesc(SubtractMask,Maps{1});
            imagesc(UpdatedSubtractVisual,UpdatedPreview{1,2});
            FilteredBase = UniqueNonZeroCounts(PreviousExample{1,2});
            FilteredOut = UniqueNonZeroCounts(ExampleArray{1,4});
            FB = histogram(GaussianHistogram,FilteredBase,'FaceColor',[0.6350 0.0780 0.1840],'FaceAlpha',0.4,'EdgeColor','None','NumBins',15);
            hold(GaussianHistogram,'on');
            FO = histogram(GaussianHistogram,FilteredOut,'FaceColor',[0.9290 0.6940 0.1250],'FaceAlpha',0.4,'EdgeColor','None','NumBins',15);
            legend(GaussianHistogram,'Before Gaussian Blur','After Gaussian Blur');
            ylim(GaussianHistogram,[0 max([max(FB.Values),max(FO.Values)])]);
            xlim(GaussianHistogram,[min([min(FilteredBase,[],'All'),min(FilteredOut,[],'All')]) max([max(FilteredBase,[],'All'),max(FilteredOut,[],'All')])]);
            hold(GaussianHistogram,'off');
        end

        function SigmaDisplay()
            if strcmp(SigmaType.Value,'Scalar')
                SecondSigmaField.Value = FirstSigmaField.Value;
                ThirdSigmaField.Value = FirstSigmaField.Value;
                FirstSigmaLabel.Text = 'σ:';
                SecondSigmaLabel.Visible = 'off';
                SecondSigmaField.Visible = 'off';
                ThirdSigmaLabel.Visible = 'off';
                ThirdSigmaField.Visible = 'off';
            elseif strcmp(SigmaType.Value,'Vector')
                FirstSigmaLabel.Text = 'X:';
                SecondSigmaLabel.Visible = 'on';
                SecondSigmaField.Visible = 'on';
                ThirdSigmaLabel.Visible = 'off';
                ThirdSigmaField.Visible = 'off';
                if strcmp(FilterDimension.Value,'3D Gaussian')
                    ThirdSigmaLabel.Visible = 'on';
                    ThirdSigmaField.Visible = 'on';
                end
            end
            SizeDisplay();
        end
        
        function SizeDisplay()
            if strcmp(SizeType.Value,'Default') && strcmp(SigmaType.Value,'Scalar')
                FirstSizeField.Value = 2*ceil(2*FirstSigmaField.Value)+1;
                SecondSizeField.Value = FirstSizeField.Value;
                ThirdSizeField.Value = FirstSizeField.Value;
                FirstSizeLabel.Text = 'N:';
                SecondSizeLabel.Visible = 'off';
                SecondSizeField.Visible = 'off';
                ThirdSizeLabel.Visible = 'off';
                ThirdSizeField.Visible = 'off';
            elseif strcmp(SizeType.Value,'Default') && strcmp(SigmaType.Value,'Vector')
                FirstSizeField.Value = 2*ceil(2*FirstSigmaField.Value)+1;
                SecondSizeField.Value = 2*ceil(2*SecondSigmaField.Value)+1;
                ThirdSizeField.Value = 2*ceil(2*ThirdSigmaField.Value)+1;
                FirstSizeLabel.Text = 'X:';
                SecondSizeLabel.Visible = 'on';
                SecondSizeField.Visible = 'on';
                ThirdSizeLabel.Visible = 'off';
                ThirdSizeField.Visible = 'off';
                if strcmp(FilterDimension.Value,'3D Gaussian')
                    ThirdSizeLabel.Visible = 'on';
                    ThirdSizeField.Visible = 'on';
                end
            elseif strcmp(SizeType.Value,'Scalar')
                SecondSizeField.Value = FirstSizeField.Value;
                ThirdSizeField.Value = FirstSizeField.Value;
                FirstSizeLabel.Text = 'N:';
                SecondSizeLabel.Visible = 'off';
                SecondSizeField.Visible = 'off';
                ThirdSizeLabel.Visible = 'off';
                ThirdSizeField.Visible = 'off';
            elseif strcmp(SizeType.Value,'Vector')
                FirstSizeLabel.Text = 'X:';
                SecondSizeLabel.Visible = 'on';
                SecondSizeField.Visible = 'on';
                ThirdSizeLabel.Visible = 'off';
                ThirdSizeField.Visible = 'off';
                if strcmp(FilterDimension.Value,'3D Gaussian')
                    ThirdSizeLabel.Visible = 'on';
                    ThirdSizeField.Visible = 'on';
                end
            end
            Sigma = [FirstSigmaField.Value SecondSigmaField.Value ThirdSigmaField.Value];
            Kernel = [FirstSizeField.Value SecondSizeField.Value ThirdSizeField.Value];
            PreviewGaussian();
        end

        function SubtractFieldCheck(Source,Event)
        % Ensures correct values for the various uieditfields
            switch Source
                case {FirstSigmaField,SecondSigmaField,ThirdSigmaField}
                    if Event.Value < 0
                        uialert(LoadFig,sprintf('%f is not a valid entry. Sigma values must be positive numbers. Reverting to previous entry.',Event.Value),'Invalid Sigma','Icon','Error');
                        Source.Value = Event.PreviousValue;
                        return;
                    end
                    if strcmp(SigmaType.Value,'Scalar')
                        SecondSigmaField.Value = FirstSigmaField.Value;
                        ThirdSigmaField.Value = FirstSigmaField.Value;
                    end
                    Sigma = [FirstSigmaField.Value SecondSigmaField.Value ThirdSigmaField.Value];
                    if strcmp(SizeType.Value,'Default')
                        FirstSizeField.Value = 2*ceil(2*FirstSigmaField.Value)+1;
                        SecondSizeField.Value = 2*ceil(2*SecondSigmaField.Value)+1;
                        ThirdSizeField.Value = 2*ceil(2*ThirdSigmaField.Value)+1;
                    end
                    PreviewGaussian();
                case {FirstSizeField,SecondSizeField,ThirdSizeField}
                    if Event.Value < 0 || mod(Event.Value,1) ~= 0 || mod(Event.Value,2) ~= 1
                        uialert(LoadFig,sprintf('%f is not a valid entry. Size values must be positive odd integers. Reverting to previous entry.',Event.Value),'Invalid Size','Icon','Error');
                        Source.Value = Event.PreviousValue;
                        return;
                    end
                    if strcmp(SizeType.Value,'Scalar')
                        SecondSizeField.Value = FirstSizeField.Value;
                        ThirdSizeField.Value = FirstSizeField.Value;
                    elseif strcmp(SizeType.Value,'Default') && strcmp(SigmaType.Value,'Scalar')
                        SizeType.Value = 'Scalar';
                    elseif strcmp(SizeType.Value,'Default') && strcmp(SigmaType.Value,'Vector')
                        SizeType.Value = 'Vector';
                    end
                    Kernel = [FirstSizeField.Value SecondSizeField.Value ThirdSizeField.Value];
                    PreviewGaussian();
            end
        end

        function ConfirmGaussianBlur()
        % Confirms Gaussian blur parameters and updates 
            GaussianProgress = uiprogressdlg(LoadFig,'Title',sprintf('Creating %s Blur',FilterDimension.Value),'Message','Gaussian blur ongoing','Indeterminate','on');
            if strcmp(FilterDimension.Value,'2D Gaussian')
                ProcessedArray(:,2:3) = Gaussian2D(ProcessedArray(:,2:3));
                ExampleArray(:,4:5) = Gaussian2D(ExampleArray(:,4:5));
            elseif strcmp(FilterDimension.Value,'3D Gaussian')
                ProcessedArray(:,2:3) = Gaussian3D(ProcessedArray(:,2:3));
                ExampleArray(:,4:5) = Gaussian3D(ExampleArray(:,4:5));
            end
            GaussianProgress.Message = 'Finished blurring!';
            pause(0.1); 
            close(GaussianProgress);
            EndSubtract();
        end

        function CancelSubtraction()
        % Ccancels current subtraction and restore old values
            ExampleArray(:,4:5) = PreviousExample;
            EndSubtract();
            delete(SubtractTab);
        end

        function EndSubtract()
        % Closes tab and restores processing abilities
            ToggleChildrenEnable(PrimaryPanel,ProcessingPanel,AdjustmentsPanel);
            imagesc(ProcessedVisual,ExampleArray{5}(:,:,1));
            ToggleChildrenEnable(SubtractTab);
            LoadGroup.SelectedTab = HomeTab;
        end
    end

    function LaunchUnmixing()
    % Launches the UI tab for compositional unmixing
        ToggleChildrenEnable(PrimaryPanel,ReferencesPanel,ProcessingPanel,AdjustmentsPanel);
        if isempty(PrimaryArray) || isempty(ProcessedArray) || isempty(ExampleArray)
            uialert(LoadFig,'There is no data! Please load data before attempting unmixing.','No Data','Icon','Error');
            ToggleChildrenEnable(PrimaryPanel,ReferencesPanel,ProcessingPanel,AdjustmentsPanel);
            return;
        elseif isempty(ReferenceArray)
            uialert(LoadFig,'There are no chemical references! Please load references before attempting unmixing.','No References','Icon','Error');
            ToggleChildrenEnable(PrimaryPanel,ReferencesPanel,ProcessingPanel,AdjustmentsPanel);
            return;
        elseif any(arrayfun(@(Rows)size(PrimaryArray{Rows,2},3),1:size(PrimaryArray,1)) ~= length(ReferenceArray{1,3}))
            uialert(LoadFig,sprintf(['There is a mismatch in some of your data. You have reference spectra that are %d in length, but the number of spectral bands in some of your input data does not match that.' ...
                ' Check sizes and remove any incompatible files from the primary list.'],length(ReferenceArray{1,3})),'Dimension Mismatch','Icon','Error');
            ToggleChildrenEnable(PrimaryPanel,ReferencesPanel,ProcessingPanel,AdjustmentsPanel);
            return;
        end
        PreviousExample = ExampleArray(:,5);
        UnmixingTab = uitab(LoadGroup,'Title','Unmix');
        OriginalUnmixPanel = uipanel(UnmixingTab,'Position',ResolutionScaler([10 10 430 430]),'BackgroundColor',[0.6289 0.7734 0.8164]);
        uilabel(OriginalUnmixPanel,'Position',[0 OriginalUnmixPanel.Position(4) 0 0]+ResolutionScaler([5 -30 250 30]),'Text','Current Data','FontWeight','Bold','FontSize',20);
        OriginalUnmixVisual = uiaxes(OriginalUnmixPanel,'Position',ResolutionScaler([20 10 390 390]),'XTick',[],'YTick',[]);

        UnmixOperationsPanel = uipanel(UnmixingTab,'Position',ResolutionScaler([450 10 780 430]),'BackgroundColor',[0.7227 0.582 0.9258]);
        uilabel(UnmixOperationsPanel,'Position',[0 UnmixOperationsPanel.Position(4) 0 0]+ResolutionScaler([5 -30 750 30]),'Text',sprintf('%s Preview',UnmixingChoice.Value),'FontWeight','Bold','FontSize',20);
        CombinedUnmixVisual = uiaxes(UnmixOperationsPanel,'Position',ResolutionScaler([20 40 360 360]),'XTick',[],'YTick',[]);
        CombinedLabel = uilabel(UnmixOperationsPanel,'Position',ResolutionScaler([20 10 360 30]),'FontSize',16,'HorizontalAlignment','Center','VerticalAlignment','Center');
        SingleUnmixVisual = uiaxes(UnmixOperationsPanel,'Position',ResolutionScaler([400 40 360 360]),'XTick',[],'YTick',[]);
        SingleLabel = uilabel(UnmixOperationsPanel,'Position',ResolutionScaler([400 10 360 30]),'Text',ReferenceArray{1,4},'FontSize',16,'HorizontalAlignment','Center','VerticalAlignment','Center');
        BrowseLeftButton = uibutton(UnmixOperationsPanel,'Position',ResolutionScaler([400 10 40 30]),'Text','<','FontWeight','Bold','FontSize',21,'Enable','off','ButtonPushedFcn',@(Source,~)BrowseUnmix(Source));
        BrowseRightButton = uibutton(UnmixOperationsPanel,'Position',ResolutionScaler([720 10 40 30]),'Text','>','FontWeight','Bold','FontSize',21,'ButtonPushedFcn',@(Source,~)BrowseUnmix(Source));
        
        UnmixParametersPanel = uipanel(UnmixingTab,'Position',ResolutionScaler([1240 10 580 430]),'BackgroundColor',[0.9258 0.7773 0.3984]);
        uilabel(UnmixParametersPanel,'Position',[0 UnmixParametersPanel.Position(4) 0 0]+ResolutionScaler([5 -30 400 30]),'Text',sprintf('%s Parameters',UnmixingChoice.Value),'FontWeight','Bold','FontSize',20);
        uibutton(UnmixParametersPanel,'Position',([UnmixParametersPanel.Position(3) 0 0 0]+ResolutionScaler([-560 360 560 30]))./([2 1 1 1]),'Text',sprintf('Auto-Calibrate %s',UnmixingChoice.Value),'FontSize',15,'ButtonPushedFcn',@(~,~)AutoCalibrateLASSO);
        CoefficientsTable = uitable(UnmixParametersPanel,'Position',([UnmixParametersPanel.Position(3) 0 0 0]+ResolutionScaler([-560 125 560 230]))./([2 1 1 1]),'ColumnName',{'Reference Map','Lambda'}, ...
            'ColumnEditable',[false true],'ColumnFormat',{'char','numeric'},'ColumnWidth',{'auto','auto'},'FontSize',16,'CellEditCallback',@(Source,Event)LambdaEdit(Event));          
        uilabel(UnmixParametersPanel,'Position',ResolutionScaler([10 100 180 20]),'Text','Advanced Parameters:','FontWeight','Bold','FontSize',15);         
        uilabel(UnmixParametersPanel,'Position',ResolutionScaler([10 75 120 20]),'Text','ADMM Parameter:','FontSize',13,'VerticalAlignment','Center');
        ADMMField = uieditfield(UnmixParametersPanel,'Numeric','Position',ResolutionScaler([135 75 130 20]),'Value',1,'FontSize',14,'HorizontalAlignment','Right','Placeholder','ADMM Parameter','ValueChangedFcn',@(Source,Event)UpdateAdvancedParam(Source,Event));
        uilabel(UnmixParametersPanel,'Position',ResolutionScaler([275 75 160 20]),'Text','Regularization Balance:','FontSize',13,'VerticalAlignment','Center');
        RegularizationField = uieditfield(UnmixParametersPanel,'Numeric','Position',ResolutionScaler([440 75 130 20]),'Value',1,'FontSize',14,'HorizontalAlignment','Right','Placeholder','Regularization Balance','ValueChangedFcn',@(Source,Event)UpdateAdvancedParam(Source,Event));            
        uilabel(UnmixParametersPanel,'Position',ResolutionScaler([10 50 120 20]),'Text','Iteration Limit:','FontSize',13,'VerticalAlignment','Center');
        IterationField = uieditfield(UnmixParametersPanel,'Numeric','Position',ResolutionScaler([135 50 130 20]),'Value',10,'FontSize',14,'HorizontalAlignment','Right','Placeholder','Iteration Limit','ValueChangedFcn',@(Source,Event)UpdateAdvancedParam(Source,Event));
        uilabel(UnmixParametersPanel,'Position',ResolutionScaler([275 50 160 20]),'Text','Residuals Tolerance:','FontSize',13,'VerticalAlignment','Center');
        ToleranceField = uieditfield(UnmixParametersPanel,'Numeric','Position',ResolutionScaler([440 50 130 20]),'Value',1e-5,'FontSize',14,'HorizontalAlignment','Right','Placeholder','Residuals Tolerance','ValueChangedFcn',@(Source,Event)UpdateAdvancedParam(Source,Event));                     
        uibutton(UnmixParametersPanel,'Position',ResolutionScaler([10 10 430 30]),'Text',sprintf('Confirm %s Parameters',UnmixingChoice.Value),'FontWeight','Bold','FontSize',16,'ButtonPushedFcn',@(~,~)ConfirmUnmix);
        uibutton(UnmixParametersPanel,'Position',ResolutionScaler([450 10 120 30]),'Text',sprintf('Cancel Current %s Unmixing',UnmixingChoice.Value),'WordWrap','On','FontAngle','Italic','FontSize',10,'Tooltip','Cancel and close unmixing tab.','ButtonPushedFcn',@(~,~)CancelUnmix);
        CurrentDisplay = 1;
        for h = height(ReferenceArray):-1:1
            CoefficientsTable.Data{h,1} = ReferenceArray{h,4};
            CoefficientsTable.Data{h,2} = NaN;
        end
        if height(ReferenceArray) == 1
            BrowseRightButton.Enable = 'off';
        end
        axis([OriginalUnmixVisual CombinedUnmixVisual SingleUnmixVisual],'image');
        colormap(OriginalUnmixVisual,'Bone');
        colormap(SingleUnmixVisual,'Bone');
        colormap(CombinedUnmixVisual,'Bone');
        UpdateVisualReferences({OriginalUnmixVisual,ExampleArray{5}(:,:,1),OriginalUnmixVisual.Position(3),'',''},{CombinedUnmixVisual,zeros(size(ExampleArray{5},1),size(ExampleArray{5},2)),CombinedUnmixVisual.Position(3),'',CombinedLabel}, ...
            {SingleUnmixVisual,zeros(size(ExampleArray{5},1),size(ExampleArray{5},2)),SingleUnmixVisual.Position(3),'',''});
        CombinedLabel.Text = 'Combined Image';
        ExampleArray{5} = repmat(ExampleArray{5}(:,:,1),[1,1,height(ReferenceArray)+1]);
        imagesc(SingleUnmixVisual,ExampleArray{5}(:,:,1));
        imagesc(CombinedUnmixVisual,ExampleArray{5}(:,:,1));
        fontname(LoadFig,GetFont());
        LoadGroup.SelectedTab = UnmixingTab;
        
        function LambdaEdit(Event)
        % Performs quick LASSO previews
            if Event.Indices(2) == 2 && Event.NewData ~= Event.PreviousData
                LASSOPreviewProgress = uiprogressdlg(LoadFig,'Title','Previewing unmixing','Message',sprintf('Running unmixing for %s with λ = %f',ReferenceArray{Event.Indices(1),4},Event.NewData),'Indeterminate','on');        
                [OutputMaps,Flag] = NNegLasso(ExampleArray{4},cell2mat([ReferenceArray(:,3)]),[NaN(1,Event.Indices(1)-1),Event.NewData,NaN(1,height(ReferenceArray)-Event.Indices(1))],ADMMField.Value,ToleranceField.Value,IterationField.Value,RegularizationField.Value);    
                ExampleArray{5}(:,:,Event.Indices(1)+1) = OutputMaps(:,:,Event.Indices(1));
                if Flag == 1
                    LASSOPreviewProgress.Message = 'Finished unmixing preview!';
                    pause(0.1); 
                    close(LASSOPreviewProgress);
                    uialert(LoadFig,sprintf('The change in λ to %f made LASSO run for maximum number of iterations. It is likely that this result did not converge on a value and residuals were high. It is suggested you change it and try again.', ...
                        CoefficientsTable.Data{Event.Indices(1),Event.Indices(2)}),'LASSO Warning','Icon','Warning');
                    CoefficientsTable.Data{Event.Indices(1),Event.Indices(2)} = Event.PreviousData;
                else
                    BrowseUnmix(Event.Indices(1));
                    if height(ReferenceArray) > 1
                        ValidLambdas = find(~isnan([CoefficientsTable.Data{:,2}]));
                        DisplayComposite(CombinedUnmixVisual,ExampleArray{5}(:,:,ValidLambdas+1),ReferenceArray(ValidLambdas,6),'Auto');
                    else
                        DisplayColored(CombinedUnmixVisual,ExampleArray{5}(:,:,1+CurrentDisplay),ReferenceArray{CurrentDisplay,6});
                    end
                    LASSOPreviewProgress.Message = 'Finished unmixing preview!';
                    pause(0.1);
                    close(LASSOPreviewProgress);
                end
            end
        end
        
        function UpdateAdvancedParam(Source,Event)
        % Redoes unmixing with updated advanced parameters
            switch Source
                case {ADMMField,ToleranceField}
                    if Event.Value < 0
                        Source.Value = Event.PreviousValue;
                        uialert(LoadFig,sprintf('%f is not a valid entry. Entries must be positive!',Event.Value),'Invalid Advanced Parameter','Icon','Error');
                        return;
                    end
                case IterationField
                    if Event.Value < 1 || Event.Value ~= floor(Event.Value)
                        Source.Value = Event.PreviousValue;
                        uialert(LoadFig,sprintf('%f is not a valid entry. Entries must be non-zero integers!',Event.Value),'Invalid Advanced Parameter','Icon','Error');
                        return;
                    end
                case RegularizationField
                    if Event.Value > 1 || Event.Value < 0
                        Source.Value = Event.PreviousValue;
                        uialert(LoadFig,sprintf('%f is not a valid entry. Entries must be range from 0 to 1!',Event.Value),'Invalid Advanced Parameter','Icon','Error');
                        return;
                    end
            end
            if Event.Value ~= Event.PreviousValue && any(~isnan([CoefficientsTable.Data{:,2}]))
                LASSOPreviewProgress = uiprogressdlg(LoadFig,'Title','Previewing unmixing','Message',sprintf('Running unmixing on all current λ with %s change',Source.Placeholder),'Indeterminate','on');
                ValidLambdas = find(~isnan([CoefficientsTable.Data{:,2}]));
                [OutputMaps,Flag] = NNegLasso(ExampleArray{4},cell2mat([ReferenceArray(:,3)]),cell2mat(CoefficientsTable.Data(:,2))',ADMMField.Value,ToleranceField.Value,IterationField.Value,RegularizationField.Value);
                ExampleArray{5}(:,:,ValidLambdas+1) = OutputMaps(:,:,ValidLambdas);
                if Flag == 1
                    LASSOPreviewProgress.Message = 'Finished unmixing preview!';
                    pause(0.1); 
                    close(LASSOPreviewProgress);
                    uialert(LoadFig,sprintf('The change in %s to %f made LASSO run for maximum number of iterations. It is likely that this result did not converge on a value and residuals were high. It is suggested you change it and try again.', ...
                        Source.Placeholder,Event.Value),'LASSO Warning','Icon','Warning');
                    Source.Value = Event.PreviousValue;
                else
                    BrowseUnmix(ValidLambdas(1));
                    if height(ReferenceArray) > 1
                        DisplayComposite(CombinedUnmixVisual,ExampleArray{5}(:,:,ValidLambdas+1),ReferenceArray(ValidLambdas,6),'Auto');
                    else
                        DisplayColored(CombinedUnmixVisual,ExampleArray{5}(:,:,1+CurrentDisplay),ReferenceArray{CurrentDisplay,6});
                    end
                    LASSOPreviewProgress.Message = 'Finished unmixing preview!';
                    pause(0.1);
                    close(LASSOPreviewProgress);
                end
            end
        end

        function BrowseUnmix(Source)
        % Browses the chemical reference map previews
            BrowseLeftButton.Enable = 'on';
            BrowseRightButton.Enable = 'on';
            if Source == BrowseLeftButton
                CurrentDisplay = CurrentDisplay-1;
            elseif Source == BrowseRightButton
                CurrentDisplay = CurrentDisplay+1;     
            else
                CurrentDisplay = Source;
            end
            if CurrentDisplay == height(ReferenceArray)
                BrowseRightButton.Enable = 'off';
            elseif CurrentDisplay == 1
                BrowseLeftButton.Enable = 'off';
            end
            SingleLabel.Text = ReferenceArray{CurrentDisplay,4};
            if isnan(CoefficientsTable.Data{CurrentDisplay,2})
                imagesc(SingleUnmixVisual,ExampleArray{5}(:,:,1+CurrentDisplay));
                colormap(SingleUnmixVisual,'Bone');
            else
                DisplayColored(SingleUnmixVisual,ExampleArray{5}(:,:,1+CurrentDisplay),ReferenceArray{CurrentDisplay,6});
            end     
        end

        function AutoCalibrateLASSO()
        % Automatically calculates LASSO lambda coefficients
            uialert(LoadFig,'Automatically determining the optimal LASSO coefficients is currently in development and is unavailable at this time. Thank you for your patience.','Auto-Calibrate WIP','Icon','Error');
        end

        function ConfirmUnmix()
        % Checks for parameters and performs batch unmixing
            if any(~isnan([CoefficientsTable.Data{:,2}]))
                UnmixProgress = uiprogressdlg(LoadFig,'Title','LASSO Unmixing','Message','Preparing LASSO unmixing');
                for q = 1:height(ProcessedArray)
                    UnmixProgress.Message = sprintf('Performing spectral unmixing on data set %d/%d',q,height(PrimaryArray));
                    ProcessedArray{q,3}(:,:,2:height(ReferenceArray)+1) = NNegLasso(ProcessedArray{q,2},cell2mat([ReferenceArray(:,3)]),cell2mat(CoefficientsTable.Data(:,2))',ADMMField.Value,ToleranceField.Value,IterationField.Value,RegularizationField.Value);
                    UnmixProgress.Value = q/height(ProcessedArray);
                end
                if height(ReferenceArray) > 1
                    DisplayComposite(ProcessedVisual,ExampleArray{5}(:,:,2:end),ReferenceArray(:,6),'Auto');
                    ProcessedLabel.Text = 'Processed Unmixed Image';
                else
                    DisplayColored(ProcessedVisual,ExampleArray{5}(:,:,2),ReferenceArray{1,6});
                    ProcessedLabel.Text = sprintf('Processed %s Image',ReferenceArray{1,4});
                end
                UnmixProgress.Message = 'Finished batch unmixing!';
                CoefficientsArray = CoefficientsTable.Data;
                pause(0.1);
                close(UnmixProgress);
                EndUnmix();
            end
        end
        
        function CancelUnmix()
        % Cancels unmixing and restores previous values  
            ExampleArray(:,5) = PreviousExample;
            EndUnmix();
            delete(UnmixingTab);          
        end

        function EndUnmix()
        % Closes tab and restores processing abilities
            ToggleChildrenEnable(PrimaryPanel,ReferencesPanel,ProcessingPanel,AdjustmentsPanel);
            BrowseLeftButton.Enable = 'on';
            BrowseRightButton.Enable = 'on';
            ToggleChildrenEnable(UnmixingTab);
            LoadGroup.SelectedTab = HomeTab;
        end
    end

    % Adjustment & Export functions
    function Quantifications()
    % Manages all reference colors and combined images    
        if isempty(PrimaryArray) || isempty(ProcessedArray) || isempty(ExampleArray)
            uialert(LoadFig,'There is no data! Please load data before attempting background removal.','No Data','Icon','Error');
            return;
        else
            uialert(LoadFig,'Quantification logic is currently being developed. Thank you for your patience.','Quantification Calculations WIP','Icon','Error');
        end
    end

    function ExportAdjusting()
    % UI for final data contrast/brightness adjustment
        ToggleChildrenEnable(PrimaryPanel,ReferencesPanel,FitPanel,ProcessingPanel,AdjustmentsPanel);
        if isempty(PrimaryArray) || isempty(ProcessedArray) || isempty(ExampleArray)
            uialert(LoadFig,'There is no data to export! Please make sure there are active datasets before adjusting and exporting.','No Data','Icon','Error');
            ToggleChildrenEnable(PrimaryPanel,ReferencesPanel,FitPanel,ProcessingPanel,AdjustmentsPanel);
            return;
        end
        AdjustTab = uitab(LoadGroup,'Title','Adjust');
        CBFramesPanel = uipanel(AdjustTab,'Position',ResolutionScaler([1230 180 590 260]),'BackgroundColor',[0.4844 0.5820 0.8086]);
        uilabel(CBFramesPanel,'Position',[0 CBFramesPanel.Position(4) 0 0]+ResolutionScaler([5 -30 570 30]),'Text','Key Frames','FontWeight','Bold','FontSize',20);
        if isempty(ReferenceArray) || any(xor(isnan(cell2mat(FitTable.Data(:,2))), isnan(cell2mat(FitTable.Data(:,3))))) || (all(isnan(cell2mat(FitTable.Data(:,2)))) && all(isnan(cell2mat(FitTable.Data(:,3)))))
            FramesQuestion = questdlg('There currently is no spectral wave calibration which would remove the option to select key frames. Would you like to proceed without this?', ...
                'Missing Calibration','Return to Home for Calibration','Proceed without Calibration','Return to Home for Calibration');
            switch FramesQuestion
                case 'Return to Home for Calibration'
                    ToggleChildrenEnable(PrimaryPanel,ReferencesPanel,FitPanel,ProcessingPanel,AdjustmentsPanel);
                    delete(AdjustTab); 
                    return;
                otherwise
                    uilabel(CBFramesPanel,'Position',ResolutionScaler([10 10 570 240]),'Text','No Calibration Data','FontSize',18,'FontAngle','Italic','WordWrap','On','HorizontalAlignment','Center','VerticalAlignment','Center', ...
                        'Tooltip','No calibration data was imported from the Home tab, meaning either reference spectra or background adjustments were not detected. If key frames selection is desired, cancel this operation and properly calibrate data before trying again.');
            end
        else
            uilabel(CBFramesPanel,'Position',ResolutionScaler([30 215 380 20]),'Text','Chemical Reference Spectra','FontSize',15,'HorizontalAlignment','Center');
            KeyFramesAxes = uiaxes(CBFramesPanel,'Position',ResolutionScaler([10 10 390 205]));
            ylim(KeyFramesAxes,[-0.01 1.01]);
            xlabel(KeyFramesAxes,sprintf('Raman Shift (cm^{-1})'),'FontSize',14);
            ylabel(KeyFramesAxes,'Normalized Intensity','FontSize',14);
            grid(KeyFramesAxes,'on');
            KeyFramesAxes.Toolbar.Visible = 'off';
            WaveCalibrate = GraphSpectra(KeyFramesAxes);
            uilabel(CBFramesPanel,'Position',ResolutionScaler([405 210 80 20]),'Text','Select View:','FontSize',12,'HorizontalAlignment','Center');
            FrameRefList = uilistbox(CBFramesPanel,'Position',ResolutionScaler([405 40 80 170]),'Items',[{'All'};ReferenceArray(:,4)],'ValueChangedFcn',@(~,~)FrameRefChoice());
            WaveFrameEntry = uieditfield(CBFramesPanel,'Numeric','Position',ResolutionScaler([490 190 90 20]),'Limits',[min(WaveCalibrate) max(WaveCalibrate)],'Value',min(WaveCalibrate),'ValueDisplayFormat','%.0f cm^-1');
            WaveFrameButton = uibutton(CBFramesPanel,'Position',ResolutionScaler([490 115 90 70]),'Text','Add Raman Shift Frame','FontSize',14,'WordWrap','On','ButtonPushedFcn',@(Source,~)AddFrame(Source));
            SpectraFrameButton = uibutton(CBFramesPanel,'Position',ResolutionScaler([490 40 90 70]),'Text','Select Frame on Spectra','FontSize',14,'WordWrap','On','ButtonPushedFcn',@(Source,~)AddFrame(Source));
            uibutton(CBFramesPanel,'Position',ResolutionScaler([405 10 175 25]),'Text','Clear All Key Frames','FontSize',14,'WordWrap','On','FontAngle','Italic','ButtonPushedFcn',@(~,~)DeleteAllFrames());
        end
        PrimaryInUse = find(strcmp(PrimaryArray(:,1),ExampleArray{1}));
        CBLibraryPanel = uipanel(AdjustTab,'Position',ResolutionScaler([10 10 210 430]),'BackgroundColor',[0.2031 0.6992 0.7266]);
        uilabel(CBLibraryPanel,'Position',[0 CBLibraryPanel.Position(4) 0 0]+ResolutionScaler([5 -30 200 30]),'Text','Image Library','FontWeight','Bold','FontSize',20);
        CBLibrary = cell(4+(size(ExampleArray{5},3)-1)+(size(ExampleArray{5},3)>2),4);
        CBLibrary(1:4,1:2) = {'Raw Stack',ExampleArray{2};'Raw Average',ExampleArray{3};'Processed Stack',ExampleArray{4};'Processed Average',ExampleArray{5}(:,:,1)};
        CBLibrary(:,3:4) = repmat({NaN,[0 255 1 0 1]},size(CBLibrary,1),1);
        for v = 1:size(ExampleArray{5},3)-1
            CBLibrary(4+v,1:4) = {ReferenceArray{v,4},ExampleArray{5}(:,:,v+1),ReferenceArray{v,6},[0 255 1 0 1]};
        end
        if size(ExampleArray{5},3) > 2
            CBLibrary(end,1:4) = {'Components Combined',NaN,NaN,[0 255 1 0 1]};
            CBLibrary{end,2} = CreateCBComposite();
        end
        CBLibraryList = uilistbox(CBLibraryPanel,'Position',ResolutionScaler([10 150 190 250]),'Items',CBLibrary(:,1),'ValueChangedFcn',@(Source,Event)NewCBFocus());
        uibutton(CBLibraryPanel,'Position',ResolutionScaler([10 120 190 25]),'Text','Remove Current','FontSize',13,'FontWeight','Bold','ButtonPushedFcn',@(Source,Event)RemoveLibraryListing());
        uilabel(CBLibraryPanel,'Position',ResolutionScaler([10 95 190 20]),'Text','Add Z-Projection:','FontWeight','Bold','FontSize',15);
        ZFocus = uidropdown(CBLibraryPanel,'Position',ResolutionScaler([10 70 190 20]),'Items',{'Raw Stack','Processed Stack'},'FontSize',14);
        ZType = uidropdown(CBLibraryPanel,'Position',ResolutionScaler([10 45 190 20]),'Items',{'Average','Minimum Intensity','Maximum Intensity','Sum of Slices','Standard Deviation','Median'},'FontSize',14);
        ZHandles = {@(x)mean(x,3),@(x)min(x,[],3),@(x)max(x,[],3),@(x)sum(x,3),@(x)std(x,0,3),@(x)median(x,3)};
        uibutton(CBLibraryPanel,'Position',ResolutionScaler([10 10 190 30]),'Text','Add Z-Projection','FontSize',14,'ButtonPushedFcn',@(~,~)AddZItem());

        CBPanel = uipanel(AdjustTab,'Position',ResolutionScaler([230 10 990 430]),'BackgroundColor',[0.2266 0.5352 0.7383]);
        uilabel(CBPanel,'Position',[0 CBPanel.Position(4) 0 0]+ResolutionScaler([5 -30 900 30]),'Text','Contrast/Brightness Adjustment','FontWeight','Bold','FontSize',20);
        CBFocusLabel = uilabel(CBPanel,'Position',ResolutionScaler([10 385 360 20]),'Text',CBLibrary{1,1},'FontSize',15,'FontAngle','Italic','HorizontalAlignment','Center');
        CBFocus = uiaxes(CBPanel,'Position',ResolutionScaler([10 25 360 360]),'XTick',[],'YTick',[]);
        axis(CBFocus,'image');
        CBSizeLabel = uilabel(CBPanel,'Position',ResolutionScaler([10 10 360 20]),'Text','','FontSize',15,'HorizontalAlignment','Center');
        AdjustAxesSize(CBFocus,size(CBLibrary{1,2},[1,2]),CBFocus.Position(3),CBFocusLabel,CBSizeLabel);
        imagesc(CBFocus,CBLibrary{1,2}(:,:,1));
        colormap(CBFocus,'Bone');
        uilabel(CBPanel,'Position',ResolutionScaler([375 355 255 30]),'Text','Minimum-Maximum:','FontSize',17,'FontWeight','Bold');
        MinMaxSlider = uislider(GridSliderPanel(CBPanel,ResolutionScaler([375 315 255 40]),CBPanel.BackgroundColor),'Range','Limits',[0 255],'Value',[0 255],'MajorTicks',[],'MinorTicks',[],'ValueChangingFcn',@(Source,Event)AdjustmentParameters(Source,Event));
        uilabel(CBPanel,'Position',ResolutionScaler([375 280 255 30]),'Text','Contrast:','FontSize',17,'FontWeight','Bold');
        ContrastSlider = uislider(GridSliderPanel(CBPanel,ResolutionScaler([375 240 255 40]),CBPanel.BackgroundColor),'Limits',[1/255 1],'Value',1,'MajorTicks',[],'MinorTicks',[],'ValueChangingFcn',@(Source,Event)AdjustmentParameters(Source,Event));
        uilabel(CBPanel,'Position',ResolutionScaler([375 205 255 30]),'Text','Brightness:','FontSize',17,'FontWeight','Bold');
        BrightnessSlider = uislider(GridSliderPanel(CBPanel,ResolutionScaler([375 165 255 40]),CBPanel.BackgroundColor),'Limits',[-127.5 127.5],'Value',0,'MajorTicks',[],'MinorTicks',[],'ValueChangingFcn',@(Source,Event)AdjustmentParameters(Source,Event));
        uibutton(CBPanel,'Position',ResolutionScaler([375 130 125 30]),'Text','Automatically Set','FontSize',13,'FontAngle','Italic','WordWrap','On');
        uibutton(CBPanel,'Position',ResolutionScaler([505 130 125 30]),'Text','Reset Adjustments','FontSize',13,'FontAngle','Italic','WordWrap','On','ButtonPushedFcn',@(Source,Event)ResetSliders());
        uilabel(CBPanel,'Position',ResolutionScaler([375 95 255 30]),'Text','Stack Browser:','FontSize',17,'FontWeight','Bold');
        StackSlider = uislider(GridSliderPanel(CBPanel,ResolutionScaler([375 30 255 65]),CBPanel.BackgroundColor),'Limits',[1 size(CBLibrary{1,2},3)],'Value',1,'MinorTicks',[],'ValueChangingFcn',@(Source,Event)AdjustmentParameters(Source,Event));
        CBHist = uiaxes(CBPanel,'Position',ResolutionScaler([635 200 345 185]),'XTick',[],'YTick',[]);
        set(CBHist,'Color',repmat(0.96,1,3));
        CreateCBHist();
        CBHist.Toolbar.Visible = 'off';
        MinimumField = uieditfield(CBPanel,'Numeric','Position',ResolutionScaler([640 185 50 20]),'Limits',[0 255],'Value',MinMaxSlider.Value(1),'ValueDisplayFormat','%.2f','ValueChangedFcn',@(Source,Event)AdjustmentParameters(Source,Event),'HorizontalAlignment','Left');
        MaximumField = uieditfield(CBPanel,'Numeric','Position',ResolutionScaler([925 185 50 20]),'Limits',[0 255],'Value',MinMaxSlider.Value(2),'ValueDisplayFormat','%.2f','ValueChangedFcn',@(Source,Event)AdjustmentParameters(Source,Event));
        uilabel(CBPanel,'Position',ResolutionScaler([650 155 140 20]),'Text','Colormap:','FontSize',12,'HorizontalAlignment','Center');
        ColorManage = uibutton(CBPanel,'Position',ResolutionScaler([650 115 140 40]),'Text','','Enable','off','ButtonPushedFcn',@(Source,Event)ChangeCBColor());
        MiniComposite = uiaxes(CBPanel,'Position',ResolutionScaler([810 10 170 170]),'XTick',[],'YTick',[]);
        axis(MiniComposite,'image');
        AdjustAxesSize(MiniComposite,size(ProcessedArray{PrimaryInUse,3}(:,:,1),[1,2]),MiniComposite.Position(3),'','');
        imagesc(MiniComposite,CBLibrary{end,2});
        MiniComposite.Toolbar.Visible = 'off';
        linkaxes([CBFocus,MiniComposite]);

        CBPrimaryPanel = uipanel(AdjustTab,'Position',ResolutionScaler([1230 10 400 160]),'BackgroundColor',[0.6289 0.7734 0.8164]);
        uilabel(CBPrimaryPanel,'Position',[0 CBPrimaryPanel.Position(4) 0 0]+ResolutionScaler([5 -30 390 30]),'Text','Set Primary Data','FontWeight','Bold','FontSize',20);
        uilabel(CBPrimaryPanel,'Position',ResolutionScaler([10 110 380 20]),'Text','Right Click to Set:','FontSize',12,'HorizontalAlignment','Center');
        CBPrimaryTable = uitable(CBPrimaryPanel,'Position',ResolutionScaler([10 10 380 105]),'Data',PrimaryArray(:,1),'ColumnName','Datasets','ColumnEditable',false,'ColumnFormat',{'char'});
        CBPrimaryTable.ContextMenu = CreateContext(LoadFig,{'Set as Primary Dataset','View Dataset'},{@SetPrimaryCB,@ViewPrimaryTable},@(Source,Event)ToggleVisible(Source,Event));

        CBExportPanel = uipanel(AdjustTab,'Position',ResolutionScaler([1640 10 180 160]),'BackgroundColor',[0.4531 0.5859 0.7289]);
        uilabel(CBExportPanel,'Position',[0 CBExportPanel.Position(4) 0 0]+ResolutionScaler([5 -30 170 30]),'Text','Set Export','FontWeight','Bold','FontSize',20);
        uibutton(CBExportPanel,'Position',ResolutionScaler([10 95 160 30]),'Text','Cancel All Adjustments','WordWrap','On','FontAngle','Italic','FontSize',11,'Tooltip','Cancel and close the export preparation tab.','ButtonPushedFcn',@(~,~)CancelExportAdjust());
        uibutton(CBExportPanel,'Position',ResolutionScaler([10 10 160 80]),'Text','Apply All Adjustments and Begin Final Export','WordWrap','On','FontWeight','Bold','FontSize',14,'Tooltip','Select data for final export.','ButtonPushedFcn',@(~,~)ConfirmAdjust());
        fontname(LoadFig,GetFont());
        LoadGroup.SelectedTab = AdjustTab;

        function NewCBFocus()
        % Sets the new CBPanel focal data set
            MinMaxSlider.Value = CBLibrary{CBLibraryList.ValueIndex,4}(1:2);
            ContrastSlider.Value = CBLibrary{CBLibraryList.ValueIndex,4}(3);
            BrightnessSlider.Value = CBLibrary{CBLibraryList.ValueIndex,4}(4);
            MinimumField.Value = MinMaxSlider.Value(1);
            MaximumField.Value = MinMaxSlider.Value(2);
            CBFocusLabel.Text = CBLibrary{CBLibraryList.ValueIndex,1};
            AdjustAxesSize(CBFocus,size(CBLibrary{CBLibraryList.ValueIndex,2},[1,2]),CBFocus.Position(3),CBFocusLabel,CBSizeLabel);
            StackSlider.Value = 1;
            if size(CBLibrary{CBLibraryList.ValueIndex,2},3) == 1 || strcmp(CBLibrary{CBLibraryList.ValueIndex,1},'Components Combined')
                StackSlider.ValueChangingFcn = @(~,~)disp([]);
            else
                StackSlider.ValueChangingFcn = @(Source,Event)AdjustmentParameters(Source,Event);
                StackSlider.Limits = [1 size(CBLibrary{CBLibraryList.ValueIndex,2},3)];
                StackSlider.Value = CBLibrary{CBLibraryList.ValueIndex,4}(5);
            end
            UpdateCBDisplay();
            CreateCBHist();
        end

        function UpdateCBDisplay()
        % Updates the displayed preview with the new adjustment values
            if strcmp(CBLibraryList.Value,'Components Combined')
                imagesc(CBFocus,AdjustImage8(CBLibrary{5+height(ReferenceArray),2},CBLibrary{5+height(ReferenceArray),4}(1:2)));
                ColorManage.BackgroundColor = repmat(0.96,1,3);
                ColorManage.Enable = 'off';
                imagesc(MiniComposite,AdjustImage8(CBLibrary{CBLibraryList.ValueIndex,2},CBLibrary{5+height(ReferenceArray),4}(1:2)));
            elseif isnan(CBLibrary{CBLibraryList.ValueIndex,3})
                imagesc(CBFocus,AdjustImage8(CBLibrary{CBLibraryList.ValueIndex,2}(:,:,CBLibrary{CBLibraryList.ValueIndex,4}(5)),MinMaxSlider.Value));
                colormap(CBFocus,'Bone');
                ColorManage.BackgroundColor = repmat(0.96,1,3);
                ColorManage.Enable = 'off';
            else
                imagesc(CBFocus,AdjustImage8(CBLibrary{CBLibraryList.ValueIndex,2}(:,:,1),MinMaxSlider.Value));
                colormap(CBFocus,linspace(0,1,255)'*CBLibrary{CBLibraryList.ValueIndex,3});
                ColorManage.BackgroundColor = CBLibrary{CBLibraryList.ValueIndex,3};
                ColorManage.Enable = 'on';
                if size(ExampleArray{5},3) > 2
                    CBLibrary{5+height(ReferenceArray),2} = CreateCBComposite();
                    imagesc(MiniComposite,AdjustImage8(CBLibrary{5+height(ReferenceArray),2},CBLibrary{5+height(ReferenceArray),4}(1:2)));
                end
            end
        end

        function CBComposite = CreateCBComposite()
        % Creates the composite CB image for both display and combination images
            if size(CBLibrary,1) >= 5+height(ReferenceArray) && strcmp(CBLibrary{5+height(ReferenceArray),1},'Components Combined')
                CBComposite = zeros([size(CBLibrary{5,2}(:,:,1),[1,2]),height(ReferenceArray)]);
                for q = height(ReferenceArray):-1:1
                    CBComposite(:,:,q) = AdjustImage8(CBLibrary{4+q,2}(:,:,1),CBLibrary{4+q,4}(1:2));
                end
                CBComposite = CreateComposite(CBComposite,CBLibrary(5:4+height(ReferenceArray),3));
            else
                CBComposite = ones(size(ProcessedArray{PrimaryInUse,3}(:,:,1),[1,2]))*244.8;
            end
        end

        function RemoveLibraryListing()
        % Removes the selected row from the library list if non-essential
            if CBLibraryList.ValueIndex <= 4+(size(ExampleArray{5},3)-1)+(size(ExampleArray{5},3)>2)
                uialert(LoadFig,sprintf(['Cannot delete any standard image sets.\nThese include:\n-First instances of Raw Stack, Raw Average, Processed Stack, or Processed Average\n-Unmixed images and generated composites\n\n' ...
                    'If adjustments are unnecessary, you may ignore and omit them in the final export UI.']),'Removing Standard Image Sets','Icon','Warning');
                return;
            end
            CBLibraryList.Value = CBLibrary{CBLibraryList.ValueIndex-1,1};
            NewCBFocus();
            CBLibrary(CBLibraryList.ValueIndex+1,:) = [];
            CBLibraryList.Items = CBLibrary(:,1);
            FrameRefChoice();
        end

        function AddZItem()
        % Adds Z-projections for the selected type and operation
            ZOperation = ZHandles(strcmp(ZType.Items,ZType.Value));
            if strcmp(ZFocus.Value,'Raw Stack')
                NewZData = ZOperation{1}(PrimaryArray{PrimaryInUse,2});
            elseif strcmp(ZFocus.Value,'Processed Stack')
                NewZData = ZOperation{1}(ProcessedArray{PrimaryInUse,2});
            end
            CBLibrary(end+1,1:4) = {[regexp(ZFocus.Value,'^\w+\s','match','once'),ZType.Value],NewZData,NaN,[0 255 1 0 1]};
            CBLibraryList.Items = CBLibrary(:,1);
            CBLibraryList.ValueIndex = height(CBLibrary);
            NewCBFocus();
        end

        function AdjustmentParameters(Source,Event)
        % Detects the adjusting slider and starts the logic cascade while updating the CB values
            StackSet = round(StackSlider.Value);
            switch Source
                case MinMaxSlider
                    if MinimumField.Value~=Event.Value(1)
                        MinimumAdjusted(Event.Value(1));
                    elseif MaximumField.Value~=Event.Value(2)
                        MaximumAdjusted(Event.Value(2))
                    end
                case MinimumField
                    MinimumAdjusted(Event.Value)
                case MaximumField
                    MaximumAdjusted(Event.Value)
                case ContrastSlider
                    ContrastAdjusted(Event.Value);
                case BrightnessSlider
                    BrightnessAdjusted(Event.Value);
                case StackSlider
                    StackSet = round(Event.Value);
            end
            CBLibrary{CBLibraryList.ValueIndex,4} = [MinMaxSlider.Value,ContrastSlider.Value,BrightnessSlider.Value,StackSet];
            UpdateCBDisplay();
            set(CBHist.UserData.TriangleHandle,'XData',[MinMaxSlider.Value,fliplr(MinMaxSlider.Value)],'YData',[0,0,CBHist.YLim(2),0]);
        end

        function MinimumAdjusted(NewMinimum)
        % Makes adjustments based on changing the minimum value
            MinMaxSlider.Value = [max(0,min(254,NewMinimum)),max(MinMaxSlider.Value(2),min(254,NewMinimum)+1)];
            MinimumField.Value = MinMaxSlider.Value(1);
            MaximumField.Value = MinMaxSlider.Value(2);
            UpdateContrastSlider();
            UpdateBrightnessSlider();
        end

        function MaximumAdjusted(NewMaximum)
        % Makes adjustments based on changing the maximum value
            MinMaxSlider.Value = [min(MinMaxSlider.Value(1),max(1,NewMaximum)-1),min(255,NewMaximum)];
            MinimumField.Value = MinMaxSlider.Value(1);
            MaximumField.Value = MinMaxSlider.Value(2);
            UpdateContrastSlider();
            UpdateBrightnessSlider();
        end

        function ContrastAdjusted(NewContrast)
        % Makes adjustments based on changing the contrast value
            MidPoint = (MinMaxSlider.Value(1)+MinMaxSlider.Value(2))/2;
            Range = max(1,NewContrast*255);
            if MinMaxSlider.Value(1) == 0 && MinMaxSlider.Value(2) ~= 255
                MinMaxSlider.Value = [0,min(255,Range)];
            elseif MinMaxSlider.Value(2) == 255 && MinMaxSlider.Value(1) ~= 0
                MinMaxSlider.Value = [max(0,255-Range),255];
            else
                MinMaxSlider.Value = [max(0,MidPoint-Range/2),min(255,MidPoint+Range/2)];
            end
            MinimumField.Value = MinMaxSlider.Value(1);
            MaximumField.Value = MinMaxSlider.Value(2);
            UpdateBrightnessSlider();
        end

        function BrightnessAdjusted(NewBrightness)
        % Makes adjustments based on changing the brightness value
            Range = MinMaxSlider.Value(2)-MinMaxSlider.Value(1);
            Min = MinMaxSlider.Value(1) + NewBrightness;
            Max = Min+Range; 
            if Min<0
                Min = 0;
                Max = min(255,Min+Range);
            end
            if Max>255
                Max = 255;
                Min = max(0,Max-Range);
            end
            if Max-Min<1
                if Min == 0
                    Max = 1;
                elseif Max==255
                    Min = 254;
                else
                    Max = min(255,Min+1);
                end
            end
            MinMaxSlider.Value = [Min,Max];
            MinimumField.Value = Min;
            MaximumField.Value = Max;
            UpdateContrastSlider();
        end

        function UpdateContrastSlider()
        % Updates the contrast slider considering the new Min/Max
            ContrastSlider.Value = (MinMaxSlider.Value(2)-MinMaxSlider.Value(1))/255;
        end

        function UpdateBrightnessSlider()
        % Updates the brightness slider considering the new Min/Max
            BrightnessSlider.Value = (MinMaxSlider.Value(1) + MinMaxSlider.Value(2))/2-127.5;
        end

        function ResetSliders()
        % Resets sliders to default position with no adjustments
            MinMaxSlider.Value = [0 255];
            MinimumField.Value = MinMaxSlider.Value(1);
            MaximumField.Value = MinMaxSlider.Value(2);
            ContrastSlider.Value = 1;
            BrightnessSlider.Value = 0;
            CBLibrary{CBLibraryList.ValueIndex,4} = [MinMaxSlider.Value,ContrastSlider.Value,BrightnessSlider.Value,round(StackSlider.Value)];
            UpdateCBDisplay();
            set(CBHist.UserData.TriangleHandle,'XData',[MinMaxSlider.Value,fliplr(MinMaxSlider.Value)],'YData',[0,0,CBHist.YLim(2),0]);
        end

        function CreateCBHist()
        % Creates the histogram of intensity values
            if strcmp(CBLibraryList.Value,'Components Combined')
                HistImage = rgb2gray(CBLibrary{CBLibraryList.ValueIndex,2});
            else
                HistImage = CBLibrary{CBLibraryList.ValueIndex,2};
            end
            HistImage = HistImage(:);
            if isnan(CBLibrary{CBLibraryList.ValueIndex,3})
                HistColor = repmat(0.2,1,3);
            else
                HistColor = CBLibrary{CBLibraryList.ValueIndex,3};
            end
            CBHist.UserData.HistHandle = histogram(CBHist,HistImage,10,'FaceColor',HistColor);
            xlim(CBHist,[min(HistImage),max(HistImage)]);
            hold(CBHist,'on');
            CBHist.UserData.TriangleHandle = plot(CBHist,[MinMaxSlider.Value,fliplr(MinMaxSlider.Value)],[0,0,CBHist.YLim(2),0],'b-','LineWidth',1.5);
            hold(CBHist,'off');
        end

        function ChangeCBColor()
        % Changes the color used for the corresponding image color set
            NewColor = uisetcolor(CBLibrary{CBLibraryList.ValueIndex,3});
            if size(ExampleArray{5},3) > 1 && CBLibraryList.ValueIndex < 5+height(ReferenceArray)
                Component = char(CBLibraryList.Value);
            else
                Component = char(extractBetween(CBLibrary{CBLibraryList.ValueIndex,1},'(',')'));
            end
            for C = 1:height(CBLibrary)
                if strcmp(CBLibrary{C,1},Component)||endsWith(CBLibrary{C,1},strcat('(',Component,')'))
                    CBLibrary{C,3} = NewColor;
                end
            end
            UpdateCBDisplay();
            ColorManage.BackgroundColor = NewColor;
            set(CBHist.UserData.HistHandle,'FaceColor',NewColor);
            LoadFig.Visible = 'off';
            LoadFig.Visible = 'on';
            if size(ExampleArray{5},3) == 1
                ReferenceArray{strcmp(ReferenceArray(:,4),Component),6} = NewColor;
            end
            FrameRefChoice();
            UpdateCBDisplay();
        end

        function SetPrimaryCB(~,Event)
        % Changes which data set is used for visual previews
            SelectedRow = Event.InteractionInformation.Row;
            if isempty(SelectedRow)
                return;
            else
                PrimaryInUse = SelectedRow;
            end
            CBLibrary(1:4,2) = {PrimaryArray{PrimaryInUse,2};PrimaryArray{PrimaryInUse,3};ProcessedArray{PrimaryInUse,2};ProcessedArray{PrimaryInUse,2}(:,:,1)};        
            for n = 1:size(ExampleArray{5},3)-1
                CBLibrary{4+n,2} = ProcessedArray{PrimaryInUse,3}(:,:,n+1);
            end
            if size(ExampleArray{5},3) > 2
                CBLibrary{5+height(ReferenceArray),2} = CreateCBComposite();
                AdjustAxesSize(MiniComposite,size(ProcessedArray{PrimaryInUse,3}(:,:,1),[1,2]),MiniComposite.Position(3),'','');
                if isnan(CBLibrary{CBLibraryList.ValueIndex,3})
                    imagesc(MiniComposite,AdjustImage8(CBLibrary{5+height(ReferenceArray),2},CBLibrary{5+height(ReferenceArray),4}(1:2)));
                end
            end
            StandardsNum = 4+(size(ExampleArray{5},3)-1)+(size(ExampleArray{5},3)>2);
            for c = 1:max(0,height(CBLibrary)-StandardsNum)
                PostStandard = regexp(CBLibrary{StandardsNum+c,1},'(Processed|Raw)\s(.+)|(Key Frame)\s(\d+)\s\(([^)]+)\)','tokens');
                ZOperation = ZHandles(strcmp(ZType.Items,PostStandard{1}{2}));
                switch PostStandard{1}{1}
                    case 'Raw'
                        CBLibrary{StandardsNum+c,2} = ZOperation{1}(PrimaryArray{PrimaryInUse,2});
                    case 'Processed'
                        CBLibrary{StandardsNum+c,2} = ZOperation{1}(ProcessedArray{PrimaryInUse,2});
                    case 'Key Frame'
                        CBLibrary{StandardsNum+c,2} = ProcessedArray{PrimaryInUse,2}(:,:,str2double(PostStandard{1}{2}));
                end
            end
            CBLibrary(:,4) = cellfun(@(v)[v(1:4),1],CBLibrary(:,4),'UniformOutput',false);
            NewCBFocus();
        end

        function FrameRefChoice()
        % Changes graphed spectra used for key frame selection
            ExistingLines = findall(KeyFramesAxes,'Type','ConstantLine');
            delete(ExistingLines);
            switch FrameRefList.Value
                case 'All'
                    for g = 1:height(ReferenceArray)
                        if size(ExampleArray{5},3) > 1
                            plot(KeyFramesAxes,WaveCalibrate,normalize(ReferenceArray{g,3},'Range'),'LineWidth',2,'Color',CBLibrary{4+g,3},'DisplayName',ReferenceArray{g,4});
                        else
                            plot(KeyFramesAxes,WaveCalibrate,normalize(ReferenceArray{g,3},'Range'),'LineWidth',2,'Color',ReferenceArray{g,6},'DisplayName',ReferenceArray{g,4});
                        end
                        hold(KeyFramesAxes,'on');
                    end
                    hold(KeyFramesAxes,'off');
                    legend(KeyFramesAxes,'Location','Best','FontSize',9);
                otherwise
                    if size(ExampleArray{5},3) > 1
                        plot(KeyFramesAxes,WaveCalibrate,normalize(ReferenceArray{FrameRefList.ValueIndex-1,3},'Range'),'LineWidth',2,'Color',CBLibrary{4+FrameRefList.ValueIndex-1,3},'DisplayName',ReferenceArray{FrameRefList.ValueIndex-1,4});
                    else
                        plot(KeyFramesAxes,WaveCalibrate,normalize(ReferenceArray{FrameRefList.ValueIndex-1,3},'Range'),'LineWidth',2,'Color',ReferenceArray{FrameRefList.ValueIndex-1,6},'DisplayName',ReferenceArray{FrameRefList.ValueIndex-1,4});
                    end
            end
            StandardsNum = 4+(size(ExampleArray{5},3)-1)+(size(ExampleArray{5},3)>2);
            for c = 1:max(0,height(CBLibrary)-StandardsNum)
                hold(KeyFramesAxes,'on');
                PostStandard = regexp(CBLibrary{StandardsNum+c,1},'(Processed|Raw)\s(.+)|(Key Frame)\s(\d+)\s\(([^)]+)\)','tokens');
                if strcmp(PostStandard{1}{1},'Key Frame')
                    xline(KeyFramesAxes,WaveCalibrate(str2double(PostStandard{1}{2})),'HandleVisibility','off');
                end
            end
            hold(KeyFramesAxes,'off');
        end

        function AddFrame(Source)
        % Adds a key frame to the CBLibrary
            switch Source
                case WaveFrameButton
                    WaveToAdd = WaveFrameEntry.Value;
                case SpectraFrameButton
                    ClearPlotInterface(KeyFramesAxes);
                    ToggleChildrenEnable(AdjustTab);
                    try
                        ClickPoint = drawpoint(KeyFramesAxes);
                        WaveToAdd = ClickPoint.Position(1);
                        delete(ClickPoint);
                        LoadFig.Pointer = 'Arrow';
                        ToggleChildrenEnable(AdjustTab);
                    catch
                        uialert(LoadFig,'Failed to add spectral frame from plot. Please try again or manually enter.','Key Frame Error','Icon','Warning');
                        ToggleChildrenEnable(AdjustTab);
                        return;
                    end
            end    
            [~,FrameNumber] = min(abs(WaveCalibrate-WaveToAdd));
            hold(KeyFramesAxes,'on');
            xline(KeyFramesAxes,WaveCalibrate(FrameNumber),'HandleVisibility','off');
            hold(KeyFramesAxes,'off');
            if strcmp(FrameRefList.Value,'All')
                CurrentHeight = height(CBLibrary);
                CBLibrary(CurrentHeight+height(ReferenceArray),1:4) = {'Blank',NaN,NaN,NaN};
                for r = 1:height(ReferenceArray)
                    if size(ExampleArray{5},3) > 1
                        CBLibrary(CurrentHeight+r,1:4) = {sprintf('Key Frame %d (%s)',FrameNumber,ReferenceArray{r,4}),ProcessedArray{PrimaryInUse,2}(:,:,FrameNumber),CBLibrary{4+r,3},[0 255 1 0 1]};
                    else
                        CBLibrary(CurrentHeight+r,1:4) = {sprintf('Key Frame %d (%s)',FrameNumber,ReferenceArray{r,4}),ProcessedArray{PrimaryInUse,2}(:,:,FrameNumber),ReferenceArray{r,6},[0 255 1 0 1]};
                    end
                end
            else
                if size(ExampleArray{5},3) > 1
                    CBLibrary(end+1,1:4) = {sprintf('Key Frame %d (%s)',FrameNumber,FrameRefList.Value),ProcessedArray{PrimaryInUse,2}(:,:,FrameNumber),CBLibrary{4+FrameRefList.ValueIndex-1,3},[0 255 1 0 1]};
                else
                    CBLibrary(end+1,1:4) = {sprintf('Key Frame %d (%s)',FrameNumber,FrameRefList.Value),ProcessedArray{PrimaryInUse,2}(:,:,FrameNumber),ReferenceArray{FrameRefList.ValueIndex-1,6},[0 255 1 0 1]};
                end
            end
            CBLibraryList.Items = CBLibrary(:,1);
            CBLibraryList.ValueIndex = height(CBLibrary);
            NewCBFocus();
            uiwait(LoadFig);
        end

        function DeleteAllFrames()
        % Deletes all key frames 
            Matches = [];
            StandardsNum = 4+(size(ExampleArray{5},3)-1)+(size(ExampleArray{5},3)>2);
            while CBLibraryList.ValueIndex  > StandardsNum
                CBLibraryList.Value = CBLibrary{CBLibraryList.ValueIndex-1,1};
                NewCBFocus();
            end
            for c = 1:max(0,height(CBLibrary)-StandardsNum)
                PostStandard = regexp(CBLibrary{StandardsNum+c,1},'(Processed|Raw)\s(.+)|(Key Frame)\s(\d+)\s\(([^)]+)\)','tokens');
                if strcmp(PostStandard{1}{1},'Key Frame')
                    Matches(end+1) = StandardsNum+c; %#ok<AGROW>
                end
            end
            CBLibrary(Matches,:) = [];
            CBLibraryList.Items = CBLibrary(:,1);
            FrameRefChoice();
        end

        function CancelExportAdjust()
        % Closes tab and restores processing abilities
            ToggleChildrenEnable(PrimaryPanel,ReferencesPanel,ProcessingPanel,AdjustmentsPanel);
            LoadGroup.SelectedTab = HomeTab;
            delete(AdjustTab);          
        end

        function ConfirmAdjust()
            ToggleChildrenEnable(AdjustTab);
            FinalExportSet(CBLibrary,ZHandles,AdjustTab);
        end
    end

    function FinalExportSet(CBLibrary,ZHandles,AdjustTab)
    % Set final export UI
        ExportTab = uitab(LoadGroup,'Title','Export');
        ExportSelectPanel = uipanel(ExportTab,'Position',ResolutionScaler([10 10 1560 430]),'BackgroundColor',[0.4531 0.5859 0.7289]);
        uilabel(ExportSelectPanel,'Position',[0 ExportSelectPanel.Position(4) 0 0]+ResolutionScaler([5 -30 500 30]),'Text','Data Selection','FontWeight','Bold','FontSize',20);
        DataSelection = cell(size(ProcessedArray,1),height(CBLibrary)+1);
        DataSelection(:,1) = ProcessedArray(:,1);
        DataSelection(:,2:end) = {true};
        ExportTable = uitable(ExportSelectPanel,'Position',ResolutionScaler([10 10 1540 390]),'Data',DataSelection,'ColumnName',[{'Data Name'};CBLibrary(:,1)],'ColumnEditable',[false,true(1,height(CBLibrary)+1)], ...
            'ColumnFormat',[{'char'},repmat({'logical'},1,height(CBLibrary)+1)],'ColumnWidth',[{300},repmat({'auto'},1,height(CBLibrary)+1)],'CellEditCallback',@(~,Event)TableEdit(Event));
        ExportTable.ContextMenu = CreateContext(LoadFig,{'Preview Export'},{@PreviewExport},@(Source,Event)ToggleVisible(Source,Event));

        ExportManagePanel = uipanel(ExportTab,'Position',ResolutionScaler([1580 240 230 200]),'BackgroundColor',[0.3242 0.5039 0.6992]);
        uilabel(ExportManagePanel,'Position',[0 ExportManagePanel.Position(4) 0 0]+ResolutionScaler([5 -30 200 30]),'Text','Table Operations','FontWeight','Bold','FontSize',20);
        RowCarrier = 0;
        ColumnCarrier = 0;
        RowApply = uibutton(ExportManagePanel,'Position',ResolutionScaler([10 125 210 40]),'Text',sprintf('Apply to\nRow'),'FontSize',14,'ButtonPushedFcn',@(Source,~)ApplyLastSelect(Source),'Enable','off');
        ColumnApply = uibutton(ExportManagePanel,'Position',ResolutionScaler([10 80 210 40]),'Text',sprintf('Apply to\nColumn'),'FontSize',14,'ButtonPushedFcn',@(Source,~)ApplyLastSelect(Source),'Enable','off');
        CheckApply = uibutton(ExportManagePanel,'Position',ResolutionScaler([10 45 210 30]),'Text','Check All','FontSize',14,'FontAngle','Italic','ButtonPushedFcn',@(Source,~)CheckState(Source));
        UncheckApply = uibutton(ExportManagePanel,'Position',ResolutionScaler([10 10 210 30]),'Text','Uncheck All','FontSize',14,'FontAngle','Italic','ButtonPushedFcn',@(Source,~)CheckState(Source));

        ExportConfirmPanel = uipanel(ExportTab,'Position',ResolutionScaler([1580 70 230 160]),'BackgroundColor',[0.7656 0.5039 0.4688]);
        uilabel(ExportConfirmPanel,'Position',[0 ExportConfirmPanel.Position(4) 0 0]+ResolutionScaler([5 -30 200 30]),'Text','Confirm Export','FontWeight','Bold','FontSize',20);
        ClosingCheck = uicheckbox(ExportConfirmPanel,'Position',ResolutionScaler([10 100 210 30]),'Text','Close Hyperspectral Analysis after all exporting concludes','WordWrap','on','FontSize',13,'Value',1);
        uibutton(ExportConfirmPanel,'Position',ResolutionScaler([10 45 210 50]),'Text',sprintf('Commence Final\nData Export'),'FontSize',17, ...
            'FontWeight','Bold','Tooltip','Proceed with export of all selected datasets','ButtonPushedFcn',@(~,~)FinalSelectionExport());
        uibutton(ExportConfirmPanel,'Position',ResolutionScaler([10 10 210 30]),'Text','Cancel Export','FontAngle','Italic','FontSize',14,'Tooltip','Return to Adjust tab','ButtonPushedFcn',@(~,~)CancelExport());

        AuthorPanel = uipanel(ExportTab,'Position',ResolutionScaler([1580 10 230 50]),'BackgroundColor',[0.8281 0.8242 0.8086]);
        uilabel(AuthorPanel,'Position',ResolutionScaler([5 5 220 40]),'Text',sprintf('Created by Mark Cherepashensky\nJi-Xin Cheng Group @ Boston University\nVersion 0.95 (Released Feb. 2024)'),'FontSize',11,'FontAngle','Italic');

        fontname(LoadFig,GetFont());
        LoadGroup.SelectedTab = ExportTab;

        function PreviewExport(~,Event)
        % Previews what the image will look like    
            SelectedRow = Event.InteractionInformation.Row;
            SelectedColumn = Event.InteractionInformation.Column;
            if isempty(SelectedRow) || isempty(SelectedColumn)
                return;
            else
                disp(SelectedRow)
                disp(SelectedColumn)
            end
        end

        function TableEdit(Event)
        % Captures table edits
            [RowCarrier,ColumnCarrier] = deal(Event.Indices(1),Event.Indices(2));
            DataSelection{RowCarrier,ColumnCarrier} = Event.NewData;
            if Event.NewData == true
                UpdateText = 'Check';
            else
                UpdateText = 'Uncheck';
            end
            RowApply.Text = sprintf('Apply %s to\nRow %d',UpdateText,RowCarrier);
            ColumnApply.Text = sprintf('Apply %s to\nColumn %d',UpdateText,ColumnCarrier);
            RowApply.Enable = 'on';
            ColumnApply.Enable = 'on';
        end

        function ApplyLastSelect(Source)
            switch Source
                case RowApply
                    DataSelection(RowCarrier,2:end) = DataSelection(RowCarrier,ColumnCarrier);
                case ColumnApply
                    DataSelection(:,ColumnCarrier) = DataSelection(RowCarrier,ColumnCarrier);
            end
            ExportTable.Data = DataSelection;
        end

        function CheckState(Source)
        % Total overwrite of all data selections to true or false
            switch Source
                case CheckApply
                    DataSelection(:,2:end) = {true};
                case UncheckApply
                    DataSelection(:,2:end) = {false};
            end
            ExportTable.Data = DataSelection;
        end

        function FinalSelectionExport()
        % Calls for parallel export of all data given selections   
            if all(cell2mat(DataSelection(:,2:end))==0)
                uialert(LoadFig,'No data was selected for export! Please select at least one data set.','Missing Export Selections','Icon','Warning');
                return
            end
            ExportProgress = uiprogressdlg(LoadFig,'Title','Exporting Data','Message','Beginning data export');
            for p = 1:size(ProcessedArray,1)
                OutputDir = fullfile(Path,ProcessedArray{p,1});
                if ~exist(OutputDir,'dir')
                    mkdir(OutputDir)
                end
                ExportProgress.Title = ProcessedArray{p,1};
                for q = 1:size(CBLibrary,1)
                    ExportProgress.Message = sprintf('Exporting column %d of %d',q,size(CBLibrary,1));
                    ExportProgress.Value = q/size(CBLibrary,1);
                    if DataSelection{p,q+1} == 1
                        switch q
                            case 1 % Raw Stack
                                for l = 1:size(PrimaryArray{p,2},3)
                                    [Frame,GMap] = gray2ind(AdjustImage8(PrimaryArray{p,2}(:,:,l),CBLibrary{q,4}(1:2)),256);
                                    if l == 1
                                        imwrite(Frame,GMap,fullfile(OutputDir,'Raw Stack.gif'),'Gif');
                                    else
                                        imwrite(Frame,GMap,fullfile(OutputDir,'Raw Stack.gif'),'Gif','WriteMode','Append');
                                    end
                                end
                            case 2 % Raw Average
                                imwrite(AdjustImage8(PrimaryArray{p,3},CBLibrary{q,4}(1:2)),fullfile(OutputDir,'Raw Average.tif'),'Tif');
                            case 3 % Processed Stack
                                for l = 1:size(ProcessedArray{p,2},3)
                                    [Frame,GMap] = gray2ind(AdjustImage8(ProcessedArray{p,2}(:,:,l),CBLibrary{q,4}(1:2)),256);
                                    if l == 1
                                        imwrite(Frame,GMap,fullfile(OutputDir,'Processed Stack.gif'),'Gif');
                                    else
                                        imwrite(Frame,GMap,fullfile(OutputDir,'Processed Stack.gif'),'Gif','WriteMode','Append');
                                    end
                                end
                            case 4 % Processed Average
                                imwrite(AdjustImage8(ProcessedArray{p,3}(:,:,1),CBLibrary{q,4}(1:2)),fullfile(OutputDir,'Processed Average.tif'),'Tif');
                            otherwise
                                PostStandard = regexp(CBLibrary{q,1},'(Processed|Raw)\s(.+)|(Key Frame)\s(\d+)\s\(([^)]+)\)','tokens');
                                if q <= 4+height(ReferenceArray) && size(ExampleArray{5},3) > 1 % Spectral Components
                                    imwrite(AdjustImage8(ProcessedArray{p,3}(:,:,1+(q-4)),CBLibrary{q,4}(1:2)),linspace(0,1,255)'*CBLibrary{q,3},fullfile(OutputDir,[CBLibrary{q,1},'.tif']),'Tif');
                                elseif strcmp(CBLibrary{q,1},'Components Combined') % Composite
                                    CompositeMade = zeros([size(ProcessedArray{p,3}(:,:,1),[1,2]),height(ReferenceArray)]);
                                    for m = height(ReferenceArray):-1:1
                                        CompositeMade(:,:,m) = AdjustImage8(ProcessedArray{p,3}(:,:,1+m),CBLibrary{4+m,4}(1:2));
                                    end
                                    imwrite(AdjustImage8(CreateComposite(CompositeMade,CBLibrary(5:4+height(ReferenceArray),3)),CBLibrary{q,4}(1:2)),fullfile(OutputDir,'Composite Components.tif'),'Tif');
                                elseif strcmp(PostStandard{1}{1},'Raw') % Raw Z-Projections
                                    ZOperation = ZHandles(strcmp({'Average','Minimum Intensity','Maximum Intensity','Sum of Slices','Standard Deviation','Median'},PostStandard{1}{2}));
                                    imwrite(AdjustImage8(ZOperation{1}(PrimaryArray{p,2}),CBLibrary{q,4}(1:2)),fullfile(OutputDir,[PostStandard{1}{1},' ',PostStandard{1}{2},' ',char(string(q)),'l.tif']),'Tif');
                                elseif strcmp(PostStandard{1}{1},'Processed') % Processed Z-Projections
                                    ZOperation = ZHandles(strcmp({'Average','Minimum Intensity','Maximum Intensity','Sum of Slices','Standard Deviation','Median'},PostStandard{1}{2}));
                                    imwrite(AdjustImage8(ZOperation{1}(ProcessedArray{p,2}),CBLibrary{q,4}(1:2)),fullfile(OutputDir,[PostStandard{1}{1},' ',PostStandard{1}{2},' ',char(string(q)),'l.tif']),'Tif');
                                elseif strcmp(PostStandard{1}{1},'Key Frame') % Key Frames
                                    imwrite(AdjustImage8(ProcessedArray{p,2}(:,:,str2double(PostStandard{1}{2})),CBLibrary{q,4}(1:2)),linspace(0,1,255)'*CBLibrary{q,3},fullfile(OutputDir,['Key Frame ',char(string(PostStandard{1}{2})),' (',PostStandard{1}{3},')','.tif']),'Tif');
                                end
                        end
                    end
                end
                DirContentCheck = dir(OutputDir);
                if numel(DirContentCheck(~ismember({DirContentCheck.name}, {'.', '..'}))) == 0
                    rmdir(OutputDir);
                end
            end
            ExportProgress.Message = 'Exporting image data arrays';
            save('HyperspectralAnalysisArrays.mat',"PrimaryArray","ProcessedArray","ReferenceArray","CBLibrary","CoefficientsArray");
            close(ExportProgress);
            if ClosingCheck.Value == 0
                ToggleChildrenEnable(PrimaryPanel,ReferencesPanel,FitPanel,ProcessingPanel,AdjustmentsPanel);
                ToggleChildrenEnable(ExportTab);
                LoadGroup.SelectedTab = HomeTab;
            else
                uiresume(LoadFig);
                delete(LoadFig);
            end
        end

        function CancelExport()
        % Cancels export and returns to Adjust tab
            ToggleChildrenEnable(AdjustTab);
            LoadGroup.SelectedTab = AdjustTab;
            delete(ExportTab);
        end
    end
end

%% External UI Functions
function varargout = FormatUI(ScreenSize)
% Creates a small UI to prompt user for the format of the load files
    FormatSelector = uifigure('Position',[(ScreenSize(3)-300)/2 (ScreenSize(4)-200)/2 300 170],'Name','Format Selector');
    uilabel(FormatSelector,'Position',[(FormatSelector.Position(3)-300)/2 145 300 25],'Text','Select Format of Data File(s):','FontSize',15,'FontWeight','Bold','HorizontalAlignment','Center');
    LoadFormat = uidropdown(FormatSelector,'Position',[(FormatSelector.Position(3)-250)/2 120 250 20],'Items',{''},'FontSize',14,'DropDownOpeningFcn',@(~,~)PrefaceText(),'ValueChangedFcn',@(~,~)PrefaceText());
    FormatPreface = uilabel(FormatSelector,'Position',[(FormatSelector.Position(3)-250)/2 50 250 60],'Text','','WordWrap','on','FontSize',14,'FontAngle','Italic','VerticalAlignment','Top');
    FormatConfirm = uibutton(FormatSelector,'Position',[(FormatSelector.Position(3)-150)/2 10 150 30],'Text','Confirm Format','FontSize',15,'Enable','off','ButtonPushedFcn',@(~,~)LoadFromDirectory);
    fontname(FormatSelector,GetFont());
    varargout{1} = FormatSelector;
    varargout{2} = LoadFormat;
    varargout{3} = FormatConfirm;

    function PrefaceText()
        % Updates format preface
        LoadFormat.Items = {'Plain Text Array (*.txt)','Tag Image File (*.tif, *.tiff)'};
        if strcmp(LoadFormat.Value,'Plain Text Array (*.txt)')
            FormatPreface.Text = 'Text arrays should be in an A by (B*C) format where A is width, B is height, and C is number of frames';
        elseif strcmp(LoadFormat.Value,'Tag Image File (*.tif, *.tiff)')
            FormatPreface.Text = 'Tag image files should already be raw image stacks';
        end
        FormatConfirm.Enable = 'on';
    end
end

function OutputData = LoadFile(varargin)
% Loads data depending on format
    File = varargin{1};
    Type = varargin{2};
    if strcmp(Type,'Plain Text Array (*.txt)')
        OutputData = readmatrix(File);
    elseif strcmp(Type,'Tag Image File (*.tif, *.tiff)')
        OutputData = imread(File);
    end
    if nargin == 3
        send(varargin{3},true);
    end
end

function OutputArray = TxtStackShapeUI(ScreenSize,InputArray,LoaderType)
% Takes a *.txt file array and reshapes it according to user inputs
    ReshapeFig = uifigure('Position',[(ScreenSize(3)-1000)/2 (ScreenSize(4)-300)/2 1000 300],'Name','Reshaping *.txt Inputs');
    TableData = cell(size(InputArray,1),5);
    for q = 1:size(InputArray,1)
        TableData{q,1} = InputArray{q,1}; % File name
        TableData{q,2} = false; % Square checkbox
        TableData{q,3} = size(InputArray{q,2},1); % Width
        TableData{q,4} = []; % Height
        TableData{q,5} = []; % Slices
    end
    uilabel(ReshapeFig,'Position',[(ReshapeFig.Position(3)-300)/2 270 300 30],'Text','Reshaping Imported Data','FontWeight','Bold','FontSize',17,'HorizontalAlignment','Center','VerticalAlignment','Bottom');
    MasterTable = uitable(ReshapeFig,'Position',[20 50 960 210],'Data',TableData,'ColumnName',{'File Name','Square?','Width','Height','Slices'},'ColumnEditable',[false true false true true], ...
        'ColumnFormat',{'char','logical','numeric','numeric','numeric'},'ColumnWidth',{'auto','fit','fit','fit','fit'},'CellEditCallback',@(Source,Event)TableEdit(Source,Event));
    AllButton = uibutton(ReshapeFig,'Position',[800 265 180 25],'Text','Apply to All Data','FontSize',13,'Enable','off','ButtonPushedFcn',@(Source,Event)ApplyToAll(Source),'Tooltip','Apply previous column entry to all data sets.');
    ConfirmReshape = uibutton(ReshapeFig,'Position',[(ReshapeFig.Position(3)-180)/2 10 180 30],'Text','Confirm Data Shapes','FontSize',15,'ButtonPushedFcn',@(~,~)ConfirmTable);
    fontname(ReshapeFig,GetFont());
    uiwait(ReshapeFig);

    function UpdateTableData(NewRow,NewCol,NewVal)
    % Adjusts the height and slices columns in the table
        if NewCol == 2 && NewVal == true
            TableData{NewRow,2} = NewVal;
            TableData{NewRow,4} = TableData{NewRow,3};
            TableData{NewRow,5} = size(InputArray{NewRow,2},2)/TableData{NewRow,4};
        elseif NewCol == 2 && NewVal == false && TableData{NewRow,4} == TableData{NewRow,3}
            TableData{NewRow,2} = NewVal;
            TableData{NewRow,4} = [];
            TableData{NewRow,5} = [];
        elseif NewCol == 4
            TableData{NewRow,4} = NewVal;
            TableData{NewRow,5} = size(InputArray{NewRow,2},2)/TableData{NewRow,4};
            if TableData{NewRow,4} == TableData{NewRow,3}
                TableData{NewRow,2} = true;
            else
                TableData{NewRow,2} = false;
            end
        elseif NewCol == 5
            TableData{NewRow,5} = NewVal;
            TableData{NewRow,4} = size(InputArray{NewRow,2},2)/TableData{NewRow,5};
            if TableData{NewRow,4} == TableData{NewRow,3}
                TableData{NewRow,2} = true;
            else
                TableData{NewRow,2} = false;
            end
        end
    end

    function TableEdit(Source,Event)
    % Calls manual adjustments to table entries
        [EventRow,EventCol] = deal(Event.Indices(1),Event.Indices(2));
        UpdateTableData(EventRow,EventCol,Event.NewData);
        Source.Data = TableData;
        AllButton.Enable = 'on';
        setappdata(AllButton,'LastEdit',Event.Indices);
        setappdata(AllButton,'LastValue',Event.NewData);
    end

    function ApplyToAll(Source)
    % Calls automatic adjustments to table entries
        LastEdit = getappdata(Source,'LastEdit');
        LastValue = getappdata(Source,'LastValue');
        if ~isempty(LastEdit)
            for k = 1:size(TableData,1)
                UpdateTableData(k,LastEdit(2),LastValue);
            end
            MasterTable.Data = TableData;
        end
    end

    function ConfirmTable()
    % Reshapes the data inside the input array to the table values
        EmptyCells = cellfun(@isempty,TableData);
        if any(EmptyCells(:))
            uialert(ReshapeFig,'The table contains empty entries! Please fill out all image parameters before proceeding.','Incomplete Entries','Icon','Warning');
            return;
        end
        ConfirmReshape.Enable = 'off';
        ProgressReshape = uiprogressdlg(ReshapeFig,'Title','Reshaping Data','Message','Beginning data reshape');
        if strcmp(LoaderType,'MainData')
            OutputArray = cell(size(InputArray));
            OutputArray(:,1) = InputArray(:,1);
            for k = 1:size(InputArray,1)
                ProgressReshape.Message = sprintf('Reshaping image stack (%d/%d)',k,size(InputArray,1));
                ProgressReshape.Value = k/size(InputArray,1);
                OutputArray{k,2} = reshape(InputArray{k,2},TableData{k,4},TableData{k,3},TableData{k,5});
                OutputArray{k,3} = mean(OutputArray{k,2},3);
            end
        elseif strcmp(LoaderType,'ReferenceData')
            ProgressReshape.Message = 'Reshaping chemical reference map';
            ProgressReshape.Value = 0.5;
            OutputArray = {InputArray{1},reshape(InputArray{2},TableData{4},TableData{3},TableData{5})};
        end
        ProgressReshape.Message = 'Exporting reshape(s) to central UI';
        ProgressReshape.Value = 1;
        close(ProgressReshape);
        uiresume(ReshapeFig);
        close(ReshapeFig);
    end
end

function [OutputParameters,NewFits] = ChemicalRefParameters(ScreenSize,RefParam,RefArray,CentralUI,CallType)
% Sets parameters for the ROI
    RefParamFig = uifigure('Position',[(ScreenSize(3)-690)/2 (ScreenSize(4)-580)/2 690 580],'Name','Chemical Reference Map Parameters','CloseRequestFcn',@(Source,~)CloseRestore(Source));
    ConfirmRef = uibutton(RefParamFig,'Position',[350 10 330 30],'Text','Confirm Reference Map','FontSize',16,'FontWeight','Bold','ButtonPushedFcn',@(~,~)ConfirmRefMap);
    if size(RefParam,2) == 7
        OutputParameters = RefParam;
        uilabel(RefParamFig,'Position',[(RefParamFig.Position(3)-600)/2 (RefParamFig.Position(4)-30) 600 30],'Text','Modifying Chemical Reference Map','FontWeight','Bold','FontSize',22,'HorizontalAlignment','Center','VerticalAlignment','Center');
    elseif strcmp(CallType,'Ref')
        OutputParameters = [RefParam,{ones(1,size(RefParam{2},3)),'',1,rand(1,3),{}}];
        uilabel(RefParamFig,'Position',[(RefParamFig.Position(3)-600)/2 (RefParamFig.Position(4)-30) 600 30],'Text','Creating a Chemical Reference Map','FontWeight','Bold','FontSize',22,'HorizontalAlignment','Center','VerticalAlignment','Center');
    elseif strcmp(CallType,'Fit')
        OutputParameters = [RefParam,{ones(1,size(RefParam{2},3)),'',1,rand(1,3),{}}];
        uilabel(RefParamFig,'Position',[(RefParamFig.Position(3)-600)/2 (RefParamFig.Position(4)-30) 600 30],'Text','Setting Background Chemical Map','FontWeight','Bold','FontSize',22,'HorizontalAlignment','Center','VerticalAlignment','Center');
    end
    uilabel(RefParamFig,'Position',[(RefParamFig.Position(3)-670)/2 (RefParamFig.Position(4)-55) 670 20],'Text',OutputParameters{1},'FontAngle','Italic','FontSize',16,'HorizontalAlignment','Center');
    PreviousParameters = OutputParameters;
    BrowserPanel = uipanel(RefParamFig,'Position',[10 10 330 500],'BackgroundColor',[0.7227 0.582 0.9258]);
    uilabel(BrowserPanel,'Position',[5 BrowserPanel.Position(4)-30 200 30],'Text','Stack Browser','FontWeight','Bold','FontSize',20);
    ReferenceLabel = uilabel(BrowserPanel,'Position',[30 455 270 20],'Text',sprintf('%s Reference Map',OutputParameters{4}),'FontSize',15','FontAngle','Italic','HorizontalAlignment','Center');
    ReferenceStack = uiaxes(BrowserPanel,'Position',[30 175 270 270],'XTick',[],'YTick',[]);
    axis(ReferenceStack,'image');
    ReferenceSizeLabel = uilabel(BrowserPanel,'Position',[30 155 270 20],'Text','','FontSize',15,'HorizontalAlignment','Center');
    AdjustAxesSize(ReferenceStack,size(OutputParameters{2},[1,2]),ReferenceStack.Position(3),ReferenceLabel,ReferenceSizeLabel)
    imagesc(ReferenceStack,OutputParameters{2}(:,:,OutputParameters{5}));
    BrowseBox = uieditfield(BrowserPanel,'Numeric','Position',[285 100 35 40],'Value',OutputParameters{5},'Limits',[1 size(OutputParameters{2},3)],'FontSize',12,'HorizontalAlignment','Center','ValueChangedFcn',@(~,~)UpdateRefStack('Field'),'RoundFractionalValues','on');
    BrowseSlider = uislider(GridSliderPanel(BrowserPanel,[10 90 270 60],BrowserPanel.BackgroundColor),'Limits',[1 size(OutputParameters{2},3)],'Value',OutputParameters{5},'ValueChangedFcn',@(~,~)UpdateRefStack('Slider'));
    uibutton(BrowserPanel,'Position',[10 50 150 30],'Text','Draw Circle ROI','FontSize',14,'ButtonPushedFcn',@(~,~)ROIDraw('Circle'));
    uibutton(BrowserPanel,'Position',[170 50 150 30],'Text','Draw Polygon ROI','FontSize',14,'ButtonPushedFcn',@(~,~)ROIDraw('Polygon'));
    uibutton(BrowserPanel,'Position',[10 10 150 30],'Text','Draw Freehand ROI','FontSize',14,'ButtonPushedFcn',@(~,~)ROIDraw('Freehand'));
    uibutton(BrowserPanel,'Position',[170 10 150 30],'Text','Point Erase ROI(s)','FontSize',14,'ButtonPushedFcn',@(~,~)ROIRemove);

    ParametersPanel = uipanel(RefParamFig,'Position',[350 50 330 460],'BackgroundColor',[0.9258 0.7773 0.3984]);
    uilabel(ParametersPanel,'Position',[5 ParametersPanel.Position(4)-30 270 30],'Text','Configure Parameters','FontWeight','Bold','FontSize',20);
    uilabel(ParametersPanel,'Position',[10 410 110 20],'Text','Set Name:','FontSize',15);
    RefField = uieditfield(ParametersPanel,'Position',[100 410 220 20],'Value',OutputParameters{4},'FontSize',15,'HorizontalAlignment','Right','Placeholder','Reference Name','ValueChangedFcn',@(~,~)UpdateRefName);
    uilabel(ParametersPanel,'Position',[10 380 150 20],'Text','Color Selector:','FontSize',15);
    ColorPicker = uibutton(ParametersPanel,'Position',[120 380 200 20],'Text','','BackgroundColor',OutputParameters{6},'ButtonPushedFcn',@(~,~)NewColor);
    uilabel(ParametersPanel,'Position',[10 350 250 20],'Text','Existing Reference Colors:','FontSize',15);
    ColorTable = uitable(ParametersPanel,'Position',[10 50 310 300],'ColumnName',{'Reference Map','Color'},'ColumnEditable',[false false],'ColumnFormat',{'char','char'},'ColumnWidth',{'auto','auto'});
    if ~isempty(RefArray)
        ExistingNames = RefArray(:,4);
        ExistingColors = RefArray(:,6);
        ColorTable.Data = cell(length(ExistingNames),1);
        for h = 1:length(ExistingNames)
            OtherColor = uistyle('BackgroundColor',ExistingColors{h});
            addStyle(ColorTable,OtherColor,'cell',[h,2]);
            ColorTable.Data{h,1} = ExistingNames{h};
            ColorTable.Data{h,2} = '';
        end
    end
    AddToFit = uicheckbox(ParametersPanel,'Position',[10 10 310 30],'Text','Add to Raman Spectra Fit','FontSize',15,'ValueChangedFcn',@(~,~)ChangeConfirm);
    if strcmp(CallType,'Fit')
        AddToFit.Enable = 'off';
        AddToFit.Value = 1;
        ChangeConfirm();
    elseif size(RefParam,2) == 7
        AddToFit.Enable = 'off';
        AddToFit.Value = 0;
        ChangeConfirm();
    end
    UpdateRefStack('Slider');
    clear RefParam RefArray;
    
    fontname(RefParamFig,GetFont());
    RefParamFig.Visible = 'off';
    RefParamFig.Visible = 'on';
    waitfor(ReferenceLabel,'Text','Done');

    function UpdateRefName()
    % Updates chemical reference name from input
        ReferenceLabel.Text = sprintf('%s Reference Map',RefField.Value);
        OutputParameters{4} = RefField.Value;
    end

    function UpdateRefStack(Source)
    % Updates reference stack displayed
        if strcmp(Source,'Slider')
            OutputParameters{5} = round(BrowseSlider.Value);
        elseif strcmp(Source,'Field')
            OutputParameters{5} = round(BrowseBox.Value);
        end
        BrowseSlider.Value = OutputParameters{5};
        BrowseBox.Value = OutputParameters{5};
        ClearPlotInterface(ReferenceStack);
        imagesc(ReferenceStack,OutputParameters{2}(:,:,OutputParameters{5}));
        hold(ReferenceStack,'on');
        for g = 1:length(OutputParameters{7})
            BoundaryROI = OutputParameters{7}{g};
            patch(ReferenceStack,'XData',BoundaryROI(:,2),'YData',BoundaryROI(:,1),'FaceColor',OutputParameters{6},'FaceAlpha',0.5,'EdgeColor','None');
        end
        hold(ReferenceStack,'off');
    end

    function NewColor()
    % Sets a new color
        OutputParameters{6} = uisetcolor(OutputParameters{6});
        ColorPicker.BackgroundColor = OutputParameters{6};
        UpdateRefStack('Slider');
        CentralUI.Visible = 'off';
        RefParamFig.Visible = 'off';
        CentralUI.Visible = 'on';
        RefParamFig.Visible = 'on';
    end

    function ROIDraw(Style)
    % Draws new ROI onto the figure plots
        ClearPlotInterface(ReferenceStack);
        ToggleChildrenEnable(RefParamFig);
        try
            switch Style
                case 'Circle'
                    NewROI = drawcircle(ReferenceStack);
                    Theta = linspace(0,2*pi,360);
                    XVals = NewROI.Center(1) + NewROI.Radius*cos(Theta);
                    YVals = NewROI.Center(2) + NewROI.Radius*sin(Theta);
                case {'Polygon','Freehand'}
                    if strcmp(Style,'Polygon')
                        NewROI = drawpolygon(ReferenceStack);
                    elseif strcmp(Style,'Freehand')
                        NewROI = drawfreehand(ReferenceStack);
                    end
                    XVals = NewROI.Position(:,1);
                    YVals = NewROI.Position(:,2);
            end
            delete(NewROI);
            ROIMask = poly2mask(XVals,YVals,size(OutputParameters{2},1),size(OutputParameters{2},2));
            [B,~,N] = bwboundaries(ROIMask,'NoHoles');
            Boundaries = arrayfun(@(k)B{k},1:N,'UniformOutput',false);
            OutputParameters{7} = [OutputParameters{7},Boundaries(1)];
            UpdateRefStack('Field');
        catch
            uialert(RefParamFig,'ROI drawing failed, shape incomplete. Please try again.','Incomplete ROI','Icon','Warning');
        end
        ToggleChildrenEnable(RefParamFig);
    end

    function ROIRemove()
    % Removes a selected ROI on the figure plots
        ClearPlotInterface(ReferenceStack);
        ToggleChildrenEnable(RefParamFig);
        try
            ClickPoint = drawpoint(ReferenceStack);
            ClickSpot = ClickPoint.Position;
            delete(ClickPoint);
            RemovedROIs = false(1,length(OutputParameters{7}));
            for g = 1:length(OutputParameters{7})
                BoundaryROI = OutputParameters{7}{g};
                if inpolygon(ClickSpot(1),ClickSpot(2),BoundaryROI(:,2),BoundaryROI(:,1))
                    RemovedROIs(g) = true;
                end
            end
            OutputParameters{7}(RemovedROIs) = [];
            UpdateRefStack('Field');
        catch
            uialert(RefParamFig,'Failed to remove ROI. Please try again.','ROI Removal Error','Icon','Warning');
        end
        ToggleChildrenEnable(RefParamFig);
    end

    function ChangeConfirm()
    % Adjusts confirm text depending on AddToFit
        if AddToFit.Value == 1
            ConfirmRef.Text = 'Set Characteristic Peaks';
        elseif AddToFit.Value == 0
            ConfirmRef.Text = 'Confirm Reference Map';
        end
    end

    function CloseRestore(Source)
    % Restores the original state before closing
        if Source == RefParamFig
            OutputParameters = PreviousParameters;
            delete(RefParamFig);
        end
    end

    function ConfirmRefMap()
    % Confirm output of the reference management UI
        ConfirmRef.Enable = 'off';
        if isempty(OutputParameters{4})
            uialert(RefParamFig,'Missing name for this chemical reference!','Incomplete Entries','Icon','Error');
            ConfirmRef.Enable = 'on';
            return;
        elseif isempty(OutputParameters{7})
            uialert(RefParamFig,'No ROIs selected for this chemical reference!','Incomplete Entries','Icon','Error');
            ConfirmRef.Enable = 'on';
            return;
        else
            ROIMasks = cellfun(@(x)poly2mask(x(:,2),x(:,1),size(OutputParameters{2},1),size(OutputParameters{2},2)),OutputParameters{7},'UniformOutput',false);
            CombinedROIMask = any(cat(3,ROIMasks{:}),3);
            for g = 1:length(OutputParameters{3})
                MaskedROI = OutputParameters{2}(:,:,g).*CombinedROIMask;
                OutputParameters{3}(g) = mean(MaskedROI(MaskedROI>0));
            end
            if AddToFit.Value == 1
                RefParamFig.Visible = 'off';
                NewFits = SpectralFind(OutputParameters(3:6),ScreenSize);
            else
                NewFits = {};
            end
            ReferenceLabel.Text = 'Done';
            delete(RefParamFig);
        end
    end
end

function FitsArray = SpectralFind(SpecParams,ScreenSize)
% Establishes key peaks of a chemical reference spectra
    SpecPeakFig = uifigure('Position',[(ScreenSize(3)-860)/2 (ScreenSize(4)-600)/2 860 600],'Name','Selecting Characteristic Spectral Peaks');
    uilabel(SpecPeakFig,'Position',[(SpecPeakFig.Position(3)-750)/2 (SpecPeakFig.Position(4)-30) 750 30],'Text',sprintf('Labeling Characteristic %s Peaks',SpecParams{2}),'FontWeight','Bold','FontSize',20,'HorizontalAlignment','Center','VerticalAlignment','Center');
    SpecParams{1} = normalize(SpecParams{1},'Range');
    PeaksData = {SpecParams{2},NaN,NaN,NaN;SpecParams{2},NaN,NaN,NaN};
    OperationsPanel = uipanel(SpecPeakFig,'Position',[520 10 330 560],'BackgroundColor',SpecParams{4});
    uilabel(OperationsPanel,'Position',[5 OperationsPanel.Position(4)-30 220 30],'Text','Characteristic Peaks','FontWeight','Bold','FontSize',20);
    uilabel(OperationsPanel,'Position',[10 515 250 20],'Text','Number of Characteristic Peaks:','FontSize',15);
    PeakNum = uidropdown(OperationsPanel,'Position',[260 510 60 20],'Items',arrayfun(@num2str,1:7,'UniformOutput',false),'Value','2','FontSize',15,'ValueChangedFcn',@(~,~)ChangePeakNum);
    uibutton(OperationsPanel,'Position',[(OperationsPanel.Position(3)-310)/2 470 310 30],'Text','Auto-Detect Peaks','FontSize',15,'ButtonPushedFcn',@(~,~)AutoDetect);
    PeaksTable = uitable(OperationsPanel,'Position',[(OperationsPanel.Position(3)-310)/2 50 310 405],'Data',PeaksData(:,2:3),'ColumnName',{'Frame Number','Wavenumber'},'ColumnEditable',[true true], ...
        'ColumnFormat',{'numeric','numeric'},'ColumnWidth',{'auto','auto'},'CellEditCallback',@(Source,Event)PlotCharacteristicPeaks(Event));
    uibutton(OperationsPanel,'Position',[(OperationsPanel.Position(3)-310)/2 10 310 30],'Text','Confirm Characteristic Peaks','FontSize',16,'FontWeight','Bold','ButtonPushedFcn',@(~,~)ConfirmPeaks);
    PeakAxes = uiaxes(SpecPeakFig,'Position',[10 10 500 560],'XLim',[1 length(SpecParams{1})],'YLim',[-0.05 1.05]);
    PlotCharacteristicPeaks()
    xlabel(PeakAxes,'Frame (#)','FontSize',15);
    ylabel(PeakAxes,'Normalized Intensity','FontSize',15);
    grid(PeakAxes,'on');

    fontname(SpecPeakFig,GetFont());
    uiwait(SpecPeakFig);

    function PlotCharacteristicPeaks(varargin)
    % Plots characteristic peaks and any labels
        PeaksData(:,2:3) = PeaksTable.Data;
        if nargin == 1
            Event = varargin{1};
            [EventRow,EventCol] = deal(Event.Indices(1),Event.Indices(2));
            if EventCol == 1 && (Event.NewData < 1 || Event.NewData > length(SpecParams{1}))
                PeaksTable.Data{EventRow,EventCol} = Event.PreviousData;
                return;
            elseif EventCol == 1 && Event.NewData ~= Event.PreviousData
                PeaksData{EventRow,4} = NaN;
                PeaksData{EventRow,2} = round(Event.NewData);
                if isnan(Event.PreviousData)
                    PeaksData{EventRow,3} = NaN;
                end
            end
        end
        plot(PeakAxes,1:length(SpecParams{1}),SpecParams{1},'Color',SpecParams{4},'LineWidth',2);
        hold(PeakAxes,'on');
        for l = 1:height(PeaksData)
            if ~isnan(PeaksData{l,2})
                PeaksData{l,4} = SpecParams{1}(PeaksData{l,2});
                plot(PeakAxes,PeaksData{l,2},PeaksData{l,4},'^','MarkerSize',11,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',SpecParams{4});
                if ~isnan(PeaksData{l,3})
                    text(PeakAxes,PeaksData{l,2},PeaksData{l,4}+0.03,sprintf('%d cm^{-1}',PeaksData{l,3}),'FontSize',12,'HorizontalAlignment','Center','VerticalAlignment','Bottom');
                end
            end
        end
        PeaksTable.Data = PeaksData(:,2:3);
        hold(PeakAxes,'off');
        legend(PeakAxes,sprintf('Normalized %s',SpecParams{2}),'FontSize',12);
    end
    
    function ChangePeakNum()
    % Changes number of peaks to be found
        PeaksToFind = str2double(PeakNum.Value);
        PeaksData = [PeaksData;repmat({SpecParams{2},NaN,NaN,NaN},PeaksToFind-height(PeaksData),1)];
        PeaksData = PeaksData(1:PeaksToFind,:);
        PeaksTable.Data = PeaksData(:,2:3);
        PlotCharacteristicPeaks()
    end
    
    function AutoDetect()
    % Automatically find peaks of certain value
        ToggleChildrenEnable(OperationsPanel);
        [PeakIndex,FrameIndex] = findpeaks(SpecParams{1},'NPeaks',height(PeaksData),'MinPeakDistance',7,'MinPeakProminence',0.03);
        for l = 1:length(FrameIndex)
            PeaksData(l,:) = {SpecParams{2},FrameIndex(l),NaN,PeakIndex(l)};
        end
        PeaksTable.Data = PeaksData(:,2:3);
        PlotCharacteristicPeaks();
        ToggleChildrenEnable(OperationsPanel);
    end
    
    function ConfirmPeaks()
    % Validates peak selection and return correct array
        if any(isnan(cell2mat(PeaksData(:,2)))) || any(isnan(cell2mat(PeaksData(:,3))))
            uialert(SpecPeakFig,'The table is missing entries! Please ensure all characteristic peaks are properly identified with a frame and wavenumber.','Incomplete Entries','Icon','Warning');
            return;
        end
        FitsArray = PeaksData(:,1:3);
        close(SpecPeakFig);
    end
end

%% Utility Functions
function Flag = CheckValidInstalls()
% Determines if minimum MATLAB version and toolboxes installed are valid
    RequiredToolboxes = {'Signal Processing Toolbox','Image Processing Toolbox','Statistics and Machine Learning Toolbox','Parallel Computing Toolbox'};
    Flag = 1;
    AddonsTable = matlab.addons.installedAddons();
    MissingToolboxes = RequiredToolboxes(~ismember(RequiredToolboxes,AddonsTable.Name) | ~ismember(RequiredToolboxes,AddonsTable.Name(AddonsTable.Enabled)));
    if isMATLABReleaseOlderThan('R2023b')
        Flag = 0;
        fprintf(2,'<strong>MATLAB version is not at least 2023b, an update is required!</strong>\n');
    end
    for q = 1:length(MissingToolboxes)
        Flag = 0;
        fprintf(2,'<strong>The %s is missing or not enabled.</strong>\n',MissingToolboxes{q});
    end
    if Flag == 0
        disp('You can manage this in the Home Tab of the MATLAB window within "Add-Ons" or from your account on the MathWorks website.');
    end
end

function OSFont = GetFont()
% Gets font based on OS
    if ispc
        OSFont = 'Century Schoolbook';
    elseif ismac
        OSFont = 'Hoefler Text';
    else
        OSFont = 'Arial';
    end
end

function PositionScaled = ResolutionScaler(InputVec)
% Scales to screen resolution
    ScreenSize = get(groot,'ScreenSize');
    PositionScaled = floor(InputVec*min([ScreenSize(3)/1920,ScreenSize(4)/1080]));
    %PositionScaled = floor(InputVec.*repmat((ScreenSize(3:4)./[1920,1080]),1,length(InputVec)/2));
end

function ToggleChildrenEnable(varargin)
% Toggles enabled state of UI object children
    for p = 1:nargin
        AllChildren = findall(varargin{p});
        ElementsToFlip = AllChildren(arrayfun(@(x)isa(x,'matlab.ui.control.Button') || isa(x,'matlab.ui.control.Slider') || isa(x,'matlab.ui.control.EditField') || ...
                                              isa(x,'matlab.ui.control.DropDown') || isa(x,'matlab.ui.control.Table') || isa(x,'matlab.ui.control.ListBox') || isa(x,'matlab.ui.control.RangeSlider'),AllChildren));
        for u = 1:length(ElementsToFlip)
            if strcmp(ElementsToFlip(u).Enable,'on')
                NewState = 'off';
            else
                NewState = 'on';
            end
            ElementsToFlip(u).Enable = NewState;
        end
    end
end

function MenuMade = CreateContext(Home,MenuItems,MenuFunctions,MenuVisibility)
% Creates context menus for UI objects   
    MenuMade = uicontextmenu(Home,'ContextMenuOpeningFcn',MenuVisibility);
    for q = 1:length(MenuItems)
        uimenu(MenuMade,'Text',MenuItems{q},'MenuSelectedFcn',MenuFunctions{q})
    end
end

function ToggleVisible(Source,Event)
% Hides context menus unless over table
    ClickRow = ~isempty(Event.InteractionInformation.Row);
    MenuItems = Source.Children;
    for q = 1:length(MenuItems)
        MenuItems(q).Visible = ClickRow;
    end
end

function AdjustAxesSize(varargin)
% Dynamically readjust axes elements to fit image aspect ratio
    UIAxes = varargin{1};
    ImageDimensions = varargin{2};
    MaxSize = varargin{3};
    AspectRatio = ImageDimensions(2)/ImageDimensions(1);
    OldAxesPosition = UIAxes.Position;
    if AspectRatio > 1
        UIAxes.Position = [OldAxesPosition(1) OldAxesPosition(2) MaxSize round(MaxSize/AspectRatio)];
    else
        UIAxes.Position = [OldAxesPosition(1) OldAxesPosition(2) round(MaxSize*AspectRatio) MaxSize];
    end
    UIAxes.YLim = [0 ImageDimensions(1)];
    UIAxes.XLim = [0 ImageDimensions(2)];
    if ~strcmp(varargin{4},'')
        OldTopLabelPosition = varargin{4}.Position;
        varargin{4}.Position = [OldTopLabelPosition(1)+(UIAxes.Position(3)-OldAxesPosition(3))/2 OldTopLabelPosition(2)+(UIAxes.Position(4)-OldAxesPosition(4)) OldTopLabelPosition(3) OldTopLabelPosition(4)];
    end
    if ~strcmp(varargin{5},'')
        OldSizeLabelPosition = varargin{5}.Position;
        varargin{5}.Position = [OldSizeLabelPosition(1)+(UIAxes.Position(3)-OldAxesPosition(3))/2 OldSizeLabelPosition(2) OldSizeLabelPosition(3) OldSizeLabelPosition(4)];
        varargin{5}.Text = sprintf('%dx%d pixels',ImageDimensions(2),ImageDimensions(1));
    end
end

function UpdateVisualReferences(varargin)
% Updates visual references    
    % Format = {Axes,Data,SizeLimit,Label,SizeLabel}
    for w = nargin:-1:1
        AdjustAxesSize(varargin{w}{1},size(varargin{w}{2},[1,2]),varargin{w}{3},varargin{w}{4},varargin{w}{5});
        imagesc(varargin{w}{1},varargin{w}{2});
        LinkedObjects(w) = varargin{w}{1};
    end
    linkaxes(LinkedObjects);
end

function ClearPlotInterface(AxesInUse)
% Clears axes interactive tools before setting user interaction
    zoom(AxesInUse,'off');
    pan(AxesInUse,'off');
    datacursormode(AxesInUse,'off');
    brush(AxesInUse,'off');
end

function SliderContainer = GridSliderPanel(ParentObject,PanelPosition,PanelColor)
% Eases creation of panels to contain positionless uisliders
    ParentPanel = uipanel(ParentObject,'Position',PanelPosition,'BorderWidth',0,'Background',PanelColor);
    SliderContainer = uigridlayout(ParentPanel,'RowHeight',{'1x','fit'},'ColumnWidth',{'1x'});
end

function FilteredCounts = UniqueNonZeroCounts(InsertImage)
% Determines unique nonzero pixels within an image array
    [UniqueCounts,~,UniqueIDs] = unique(InsertImage);
    FilteredCounts = UniqueCounts(accumarray(UniqueIDs,1)>1);
end

function DisplayColored(TargetAxes,Image2D,RGBVec)
% Displays an image on a custom RGB color map
    imagesc(TargetAxes,Image2D);
    colormap(TargetAxes,linspace(0,1,255)'*RGBVec);
end

function DisplayComposite(TargetAxes,ImagesMatrix,ColorsArray,varargin)
% Displays composite of images using RGB weights
    if nargin > 3 && strcmp(varargin{1},'Auto')
        for q = 1:size(ImagesMatrix,3)
            ImagesMatrix(:,:,q) = imadjust(ImagesMatrix(:,:,q));
        end
    end
    imagesc(TargetAxes,CreateComposite(ImagesMatrix,ColorsArray));
end

function CompositeImage = CreateComposite(ImagesMatrix,ColorsArray)
% Creates a normalized unit8 version of a composite image
    CompositeImage = zeros([size(ImagesMatrix,[1,2]),3]);
    for q = 1:size(ImagesMatrix,3)
        for Channel = 3:-1:1
            CompositeImage(:,:,Channel) = CompositeImage(:,:,Channel)+double(ImagesMatrix(:,:,q)*ColorsArray{q}(Channel));
        end
    end
    if max(CompositeImage(:)) > 1
        CompositeImage = CompositeImage/max(CompositeImage(:));
    end
    CompositeImage = uint8(CompositeImage*255);
end

function AdjustedImage = AdjustImage8(ImageData,ScaleRange)
% Creates a uint8 imadjust using a 0-255 scaling range
    AdjustedImage = imadjust(im2uint8(rescale(ImageData)),ScaleRange./255,[]);
end

%% Custom Processing Functions
function [ConcentrationMaps,Exit] = NNegLasso(HyperspectralStack,ReferenceSpectra,SparsityVector,ADMMParam,IterationLimit,Tolerance,RegularizationBalance)
% Performs lasso-based unmixing with non-negativity constraint
    HyperspectralStack = double(HyperspectralStack);
    [Nx,Ny,Nz] = size(HyperspectralStack);
    N = Nx*Ny*Nz;
    RefNum = size(ReferenceSpectra,1);
    ConcentrationMaps = zeros(Nx,Ny,RefNum);
    ADMMMultiplier = zeros(Nx,Ny,RefNum);
    ADMMConcentrationEstimate = zeros(Nx,Ny,RefNum);
    R_positive = zeros(Nx,Ny,RefNum);
    Iterations = 0;
    ResidualConcentrations = inf;
    ResidualEstimate = inf;
    ResidualMultiplier = inf;
    RefFocus = find(~isnan(SparsityVector));
    while max([ResidualConcentrations,ResidualEstimate,ResidualMultiplier]) > Tolerance && Iterations < IterationLimit
        Iterations = Iterations+1;
        PreviousConcentrations = ConcentrationMaps;
        PreviousADMMEstimate = ADMMConcentrationEstimate;
        PreviousMultiplier = ADMMMultiplier;
        ConcentrationVariant = PreviousADMMEstimate - ADMMMultiplier;
        SparsityMatrix = [ReferenceSpectra,eye(RefNum)];
        for SpectralReference = RefFocus
            SpectrumSparsity = SparsityVector(SpectralReference);
            TemporaryConcentrations = zeros(Nx*Ny,1);
            SlicedPreviousConcentrations = PreviousConcentrations(:,:,SpectralReference);
            SlicedHyperspectralStack = reshape(HyperspectralStack,Nx*Ny,Nz);
            SlicedConcentrationVariant = reshape(ConcentrationVariant,Nx*Ny,RefNum);
            parfor v = 1:Ny*Nx
                if Iterations == 1 || any(SlicedPreviousConcentrations(v)<0)
                    RightHand = [reshape(SlicedHyperspectralStack(v,:),[Nz,1]); (sqrt(ADMMParam)*SlicedConcentrationVariant(v,:))'];
                    SinglePixelEstimate = lasso(SparsityMatrix',RightHand,'Lambda',SpectrumSparsity,'MaxIter',1e5,'Alpha',RegularizationBalance);
                    TemporaryConcentrations(v) = SinglePixelEstimate(SpectralReference);
                end
            end
            ConcentrationMaps(:,:,SpectralReference) = reshape(TemporaryConcentrations,[Nx,Ny]);
        end
        ADMMConcentrationEstimate = max((ConcentrationMaps+ADMMMultiplier),R_positive);
        ADMMMultiplier = ADMMMultiplier+(ConcentrationMaps-ADMMConcentrationEstimate);
        CalculateResidual = @(Current,Previous)sqrt(sum((Current-Previous).^2,'all'))/sqrt(N);
        ResidualConcentrations = CalculateResidual(ConcentrationMaps,PreviousConcentrations);
        ResidualEstimate = CalculateResidual(ADMMConcentrationEstimate,PreviousADMMEstimate);
        ResidualMultiplier = CalculateResidual(ADMMMultiplier,PreviousMultiplier);  
    end
    if Iterations == IterationLimit && max([ResidualConcentrationMap,ResidualEstimateConcentration,ResidualMultiplier]) > Tolerance
        Exit = 1;
    else
        Exit = 0;
    end
end
