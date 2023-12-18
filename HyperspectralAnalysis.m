%% Attribution
% =========================================================================
% Author: Mark Cherepashensky
% Ji-Xin Cheng Group @ Boston University December 2023
% Version 0.9
%
% The following code is distributed without any warranty, and without
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
HyperspectralUI(get(groot,'ScreenSize'));

%% Central UI
function HyperspectralUI(ScreenSize)
% Central UI for processing hyperspectral images
    % Setting up the UI
    LoadFig = uifigure('Position',ResolutionScaler([(1920-1900)/2 (1080-490)/2 1900 490]),'Name','Hyperspectral Analysis','Resize','off');
    uilabel(LoadFig,'Position',[0 LoadFig.Position(4) LoadFig.Position(3) 0]+ResolutionScaler([5 -40 -10 50]),'Text','Hyperspectral Analysis','FontSize',28,'FontWeight','Bold');
    LoadGroup = uitabgroup(LoadFig,'TabLocation','Left','Position',[0 0 LoadFig.Position(3) LoadFig.Position(4)]+ResolutionScaler([0 0 0 -35]));

    % Home tab
    HomeTab = uitab(LoadGroup,'Title','Home');
    PrimaryPanel = uipanel(HomeTab,'Position',ResolutionScaler([10 225 300 215]),'BackgroundColor',[0.6289 0.7734 0.8164]);
    uilabel(PrimaryPanel,'Position',ResolutionScaler([5 185 160 30]),'Text','Primary Data','FontWeight','Bold','FontSize',20);
    PrimaryArray = {};
    ProcessedArray = {};
    ExampleArray = {};
    Path = '';
    PrimaryLoad = uibutton(PrimaryPanel,'Position',ResolutionScaler([10 140 100 40]),'Text','Set Data Folder','FontSize',14,'WordWrap','on','HorizontalAlignment','Center','ButtonPushedFcn',@(~,~)LoadPrimary());
    SetCounter = uilabel(PrimaryPanel,'Position',ResolutionScaler([120 165 170 20]),'Text','','FontSize',14);
    StitchingLoad = uibutton(PrimaryPanel,'Position',ResolutionScaler([120 140 170 25]),'Text','Stitch Datasets','FontSize',14,'Enable','off');
    uilabel(PrimaryPanel,'Position',ResolutionScaler([10 115 280 20]),'Text','Right Click to Modify:','FontSize',12,'HorizontalAlignment','Center');
    PrimaryTable = uitable(PrimaryPanel,'Position',ResolutionScaler([10 10 280 110]),'ColumnName','Datasets','ColumnEditable',false,'ColumnFormat',{'char'});
    PrimaryTable.ContextMenu = CreateContext(LoadFig, {'Set as Primary Dataset', 'View Dataset', 'Delete Dataset'}, {@SetPrimaryTable, @ViewPrimaryTable, @DeletePrimaryTable}, @(Source,Event)ToggleVisible(Source,Event));
    
    ReferencesPanel = uipanel(HomeTab,'Position',ResolutionScaler([10 10 300 205]),'BackgroundColor',[0.457 0.7266 0.4609]);
    uilabel(ReferencesPanel,'Position',ResolutionScaler([5 175 270 30]),'Text','Chemical Reference Maps','FontWeight','Bold','FontSize',20);
    ReferenceArray = {};
    ReferenceLoad = uibutton(ReferencesPanel,'Position',ResolutionScaler([10 140 280 30]),'Text','Load a Chemical Reference','FontSize',14,'HorizontalAlignment','Center','ButtonPushedFcn',@(~,~)LoadNewRef());
    uilabel(ReferencesPanel,'Position',ResolutionScaler([10 115 280 20]),'Text','Right Click to Modify:','FontSize',12,'HorizontalAlignment','Center');
    ReferenceTable = uitable(ReferencesPanel,'Position',ResolutionScaler([10 10 280 110]),'ColumnName','Reference Maps','ColumnEditable',false,'ColumnFormat',{'char'});
    ReferenceTable.ContextMenu = CreateContext(LoadFig, {'Modify Reference', 'Delete Reference'}, {@ModifyRefTable, @DeleteRefTable}, @(Source,Event)ToggleVisible(Source,Event));

    FitPanel = uipanel(HomeTab,'Position',ResolutionScaler([320 240 400 200]),'BackgroundColor',[0.9258 0.7773 0.3984]);
    uilabel(FitPanel,'Position',ResolutionScaler([5 170 300 30]),'Text','Calibrate Spectra Fitting','FontWeight','Bold','FontSize',20);
    LoadBackground = uibutton(FitPanel,'Position',ResolutionScaler([10 130 190 30]),'Text','Set Background Reference','FontSize',14,'HorizontalAlignment','Center','ButtonPushedFcn',@(~,~)GetBackgroundFit());
    FitData = {'Background', NaN, NaN; 'Background', NaN, NaN};
    AddedFitData = {};
    uilabel(FitPanel,'Position',ResolutionScaler([210 135 65 20]),'Text','Presets:','FontSize',17,'VerticalAlignment','Center');
    FitPresets = uidropdown(FitPanel,'Position',ResolutionScaler([280 135 110 20]),'Items',{'','DMSO','Lipid'},'FontSize',14,'ValueChangedFcn',@(~,~)DisplayFitPresets());
    FitTable = uitable(FitPanel,'Position',ResolutionScaler([10 10 380 115]),'Data',FitData,'ColumnName',{'Source','Frame Number','Wavenumber'},'ColumnEditable',[false true true],'ColumnFormat',{'char','numeric','numeric'},'ColumnWidth',{'auto','auto','auto'});

    ProcessingPanel = uipanel(HomeTab,'Position',ResolutionScaler([320 105 400 125]),'BackgroundColor',[0.8164 0.5312 0.3086]);
    uilabel(ProcessingPanel,'Position',ResolutionScaler([5 95 250 30]),'Text','Processing Techniques','FontWeight','Bold','FontSize',20);
    uilabel(ProcessingPanel,'Position',ResolutionScaler([10 70 200 25]),'Text','Denoising Package:','FontSize',18);
    DenoisingChoice = uidropdown(ProcessingPanel,'Position',ResolutionScaler([200 70 140 20]),'Items',{''},'FontSize',13,'Enable','off');
    ExecuteDenoise = uibutton(ProcessingPanel,'Position',ResolutionScaler([340 70 50 20]),'Text','Run','FontSize',12,'ButtonPushedFcn',@(~,~)LaunchDenoise,'Enable','off');
    uilabel(ProcessingPanel,'Position',ResolutionScaler([10 40 200 25]),'Text','Background Removal:','FontSize',18);
    BackgroundChoice = uidropdown(ProcessingPanel,'Position',ResolutionScaler([200 40 140 20]),'Items',{'Binary Mask','Gaussian Blur'},'FontSize',13);
    ExecuteBackground = uibutton(ProcessingPanel,'Position',ResolutionScaler([340 40 50 20]),'Text','Run','FontSize',12,'ButtonPushedFcn',@(~,~)LaunchRemoval);
    uilabel(ProcessingPanel,'Position',ResolutionScaler([10 10 200 25]),'Text','Spectral Unmixing:','FontSize',18);
    UnmixingChoice = uidropdown(ProcessingPanel,'Position',ResolutionScaler([200 10 140 20]),'Items',{'LASSO'},'FontSize',13);
    ExecuteUnmixing = uibutton(ProcessingPanel,'Position',ResolutionScaler([340 10 50 20]),'Text','Run','FontSize',12,'ButtonPushedFcn',@(~,~)LaunchUnmixing);

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

    AdjustmentsPanel = uipanel(HomeTab,'Position',ResolutionScaler([320 10 230 85]),'BackgroundColor',[0.7656 0.5039 0.4688]);
    uilabel(AdjustmentsPanel,'Position',ResolutionScaler([5 55 200 30]),'Text','Final Adjustments','FontWeight','Bold','FontSize',20);
    ExecuteContrastBright = uibutton(AdjustmentsPanel,'Position',ResolutionScaler([10 10 100 40]),'Text','Contrast & Brightness','FontSize',14,'WordWrap','on');
    ExecuteColorAdjust = uibutton(AdjustmentsPanel,'Position',ResolutionScaler([120 10 100 40]),'Text','Colors for References','FontSize',14,'WordWrap','on','Enable','off');

    ExportPanel = uipanel(HomeTab,'Position',ResolutionScaler([560 10 160 85]),'BackgroundColor',[0.607 0.6109 0.6188]);
    uilabel(ExportPanel,'Position',ResolutionScaler([5 55 150 30]),'Text','Export','FontWeight','Bold','FontSize',20);
    uibutton(ExportPanel,'Position',([ExportPanel.Position(3) 0 0 0]+ResolutionScaler([-120 10 120 40]))./([2 1 1 1]),'Text','Output Results','FontSize',14,'ButtonPushedFcn',@(~,~)TempExport());

    fontname(LoadFig,GetFont());
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
            DisplayComposite(ProcessedVisual,ExampleArray{5}(:,:,2:end),ReferenceArray(:,6));
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
            DisplayComposite(SecondVisual,ExampleArray{5}(:,:,2:end),ReferenceArray(:,6));
            SecondLabel.Text = 'Processed Unmixed Image';
        elseif size(ExampleArray{5},3) > 1
            DisplayColored(SecondVisual,ExampleArray{5}(:,:,2),ReferenceArray{1,6});
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
            SetCounter.Text = 'No Active Datasets';
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
        PrimaryTable.Data = PrimaryArray(:,1);
        SetCounter.Text = sprintf('%d Datasets Active',height(PrimaryArray));
        if size(ExampleArray{5},3) > 2
            DisplayComposite(ProcessedVisual,ExampleArray{5}(:,:,2:end),ReferenceArray(:,6));
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
        ReferenceArray(SelectedRow,:) = ChemicalRefParameters(ScreenSize,ReferenceArray(SelectedRow,:),ReferenceArray,LoadFig,'Ref');
        ReferenceTable.Data = ReferenceArray(:,4);
        GraphSpectra();
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
        GraphSpectra();
    end

    % Home functions
    function LoadPrimary()
    % Function to prompt the user for a directory with the primary datasets
        PrimaryLoad.Enable = 'off';
        [FormatSelector,LoadFormat,FormatConfirm] = FormatUI(ScreenSize);
        FormatConfirm.ButtonPushedFcn = @(~,~)LoadFromDirectory;
        uiwait(FormatSelector);

        function LoadFromDirectory()
        % Function to load files
            DataFormat = LoadFormat.Value;
            uiresume(FormatSelector)
            close(FormatSelector)
            Path = 0;
            while Path == 0
                Path = uigetdir('Data','Select directory for primary dataset(s)');
            end
            LoadFig.Visible = 'off';
            LoadFig.Visible = 'on';
            if strcmp(DataFormat,'Plain Text Array (*.txt)')
                AllFiles = dir(fullfile(Path,'*.txt'));
            elseif strcmp(DataFormat,'Tag Image File (*.tif, *.tiff)')
                AllFiles = [dir(fullfile(Path,'*.tif')), dir(fullfile(Path,'*.tiff'))];
            end
            PrimaryArray = cell(length(AllFiles),3);
            ProcessedArray = cell(length(AllFiles),3);
            Progress = uiprogressdlg(LoadFig,'Title','Loading Data','Message','Beginning data load');
            CompletedFiles = -1;
            if length(AllFiles) > 5
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

            ExampleArray = {PrimaryArray{1,1:3}, PrimaryArray{1,2:3}};
            UpdateVisualReferences({OriginalVisual,ExampleArray{5}(:,:,1),OriginalVisual.Position(3),OriginalLabel,OriginalSizeLabel},{ProcessedVisual,ExampleArray{5}(:,:,1),ProcessedVisual.Position(3),ProcessedLabel,ProcessedSizeLabel});
            PrimaryTable.Data = PrimaryArray(:,1);
            SetCounter.Text = sprintf('%d Datasets Loaded',height(PrimaryArray));
            StitchingLoad.Enable = 'off';
            PrimaryLoad.Text = 'Set New Data Folder';
            PrimaryLoad.Tooltip = 'Clears all existing datasets and loads from a new folder.';
            PrimaryLoad.Enable = 'on';

            function UpdateProgress()
                CompletedFiles = CompletedFiles+1;
                Progress.Message = sprintf('Loading files from selected folder (%d/%d)',CompletedFiles,length(AllFiles));
                Progress.Value = CompletedFiles/length(AllFiles);
            end
        end
    end

    % Reference functions
    function LoadNewRef()
    % Function to load a new chemical reference
        ToggleEnable(ReferenceTable,ReferenceLoad);
        [FormatSelector,LoadFormat,FormatConfirm] = FormatUI(ScreenSize);
        FormatConfirm.ButtonPushedFcn = @(~,~)LoadRefFile(FormatSelector,LoadFormat,'Ref');
        uiwait(FormatSelector);
        ReferenceLoad.Text = 'Load Additional Chemical Reference';
        ToggleEnable(ReferenceTable,ReferenceLoad);
    end

    function LoadRefFile(Selector,Format,Style)
    % Function to load chemical reference file
        DataFormat = Format.Value;
        uiresume(Selector)
        close(Selector)
        FileName = 0;
        while FileName == 0
            if strcmp(DataFormat,'Plain Text Array (*.txt)')
                [FileName,FilePath] = uigetfile({'*.txt','Plain Text Array (*.txt)'},'Select chemical reference file');
            elseif strcmp(DataFormat,'Tag Image File (*.tif, *.tiff)')
                [FileName,FilePath] = uigetfile({'*.tif;*.tiff','Tag Image File (*.tif, *.tiff)'},'Select chemical reference file');
            end
        end
        LoadFig.Visible = 'off';
        LoadFig.Visible = 'on';
        RefProgress = uiprogressdlg(LoadFig,'Title','Loading chemical reference data','Message','Loading reference','Indeterminate','on');
        if strcmp(DataFormat,'Plain Text Array (*.txt)')
            LoadedRef = LoadFile(fullfile(FilePath,FileName),DataFormat);
            RefProgress.Message = 'Finished loading';
            close(RefProgress);
            RefFile = TxtStackShapeUI(ScreenSize,{FileName,LoadedRef},'ReferenceData');
        elseif strcmp(DataFormat,'Tag Image File (*.tif, *.tiff)')
            RefFile = {FileName,LoadFile(fullfile(FilePath,FileName),DataFormat)};
            RefProgress.Message = 'Finished loading';
            close(RefProgress);
        end
        LoadFig.Visible = 'off';
        LoadFig.Visible = 'on';
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
        GraphSpectra();
    end

    % Fit functions
    function GetBackgroundFit()
    % Function to load reference for background peaks
        ToggleEnable(LoadBackground,FitPresets,FitTable);
        [FormatSelector,LoadFormat,FormatConfirm] = FormatUI(ScreenSize);
        FormatConfirm.ButtonPushedFcn = @(~,~)LoadRefFile(FormatSelector,LoadFormat,'Fit');
        uiwait(FormatSelector);
        ToggleEnable(LoadBackground,FitPresets,FitTable);
    end

    function GraphSpectra()
    % Function that graphs spectra when all necessary values are in place
        if isempty(ReferenceArray) || any(xor(isnan(cell2mat(FitTable.Data(:,2))), isnan(cell2mat(FitTable.Data(:,3))))) || (all(isnan(cell2mat(FitTable.Data(:,2)))) && all(isnan(cell2mat(FitTable.Data(:,3)))))
            return;
        else
            WaveCalibrate = polyval(polyfit(abs(round(cell2mat(FitTable.Data(:,2)))),abs(round(cell2mat(FitTable.Data(:,3)))),1),1:length(ReferenceArray{1,3}));
            for g = 1:height(ReferenceArray)
                plot(SpectraAxes,WaveCalibrate,NormalizeMinMax(ReferenceArray{g,3}),'LineWidth',2,'Color',ReferenceArray{g,6},'DisplayName',ReferenceArray{g,4});
                hold(SpectraAxes,'on');
            end
            hold(SpectraAxes,'off');
            legend(SpectraAxes,'Location','Best','FontSize',9);
        end
    end

    function DisplayFitPresets()
    % Function to set presets for FitData primary values
        switch FitPresets.Value
            case 'Blank'
                Changes = {'Background', NaN, NaN; 'Background', NaN, NaN};
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
        GraphSpectra();
    end

    % Processing functions

    function LaunchRemoval()
    % Function to launch the UI tab for background removal
        if isempty(PrimaryArray) || isempty(ProcessedArray) || isempty(ExampleArray)
            uialert(LoadFig,'There is no data! Please load data before attempting background removal.','No Data','Icon','Error');
        else
            ToggleEnable(ExecuteBackground,BackgroundChoice,ExecuteUnmixing,UnmixingChoice,ExecuteContrastBright);
            ExecuteColorAdjust.Enable = 'off';
            PreviousExample = ExampleArray(:,4:5);
            SubtractTab = uitab(LoadGroup,'Title','Subtract');
            OriginalSubtractPanel = uipanel(SubtractTab,'Position',ResolutionScaler([10 10 430 430]),'BackgroundColor',[0.5234 0.8086 0.75]);
            uilabel(OriginalSubtractPanel,'Position',[0 OriginalSubtractPanel.Position(4) 0 0]+ResolutionScaler([5 -30 250 30]),'Text','Current Data','FontWeight','Bold','FontSize',20);
            OriginalSubtractVisual = uiaxes(OriginalSubtractPanel,'Position',ResolutionScaler([20 10 390 390]),'XTick',[],'YTick',[]);
            
            SubtractOperationsPanel = uipanel(SubtractTab,'Position',ResolutionScaler([450 10 920 430]),'BackgroundColor',[0.4414 0.5977 0.8672]);
            uilabel(SubtractOperationsPanel,'Position',[0 OriginalSubtractPanel.Position(4) 0 0]+ResolutionScaler([5 -30 800 30]),'Text',sprintf('%s Parameters',BackgroundChoice.Value),'FontWeight','Bold','FontSize',20);
            ConfirmSubtract = uibutton(SubtractOperationsPanel,'Position',([SubtractOperationsPanel.Position(3) 0 0 0]+ResolutionScaler([-550 10 550 30]))./([2 1 1 1]),'Text',sprintf('Confirm Parameters for %s Background Removal',BackgroundChoice.Value),'FontWeight','Bold','FontSize',16);
            uibutton(SubtractOperationsPanel,'Position',ResolutionScaler([780 10 130 30]),'Text','Cancel Current Background Removal','WordWrap','On','FontAngle','Italic','FontSize',10,'Tooltip','Cancel and close subtraction tab.','ButtonPushedFcn',@(~,~)CancelSubtract);
            uilabel(SubtractOperationsPanel,'Position',[0 SubtractOperationsPanel.Position(4) 0 0]+ResolutionScaler([810 -25 100 20]),'Text',sprintf('%d Datasets',height(PrimaryArray)),'FontSize',14,'HorizontalAlignment','Right','VerticalAlignment','Top');
            SubtractMask = uiaxes(SubtractOperationsPanel,'Position',ResolutionScaler([10 50 350 350]),'XTick',[],'YTick',[]);
            
            UpdatedSubtractPanel = uipanel(SubtractTab,'Position',ResolutionScaler([1380 10 430 430]),'BackgroundColor',[0.4648 0.4766 0.8477]);
            uilabel(UpdatedSubtractPanel,'Position',[0 UpdatedSubtractPanel.Position(4) 0 0]+ResolutionScaler([5 -30 250 30]),'Text','Updated Data','FontWeight','Bold','FontSize',20);
            UpdatedSubtractVisual = uiaxes(UpdatedSubtractPanel,'Position',ResolutionScaler([20 10 390 390]),'XTick',[],'YTick',[]);
            axis([OriginalSubtractVisual SubtractMask UpdatedSubtractVisual],'image');
            colormap(OriginalSubtractVisual,'Bone');
            colormap(SubtractMask,'Copper');
            colormap(UpdatedSubtractVisual,'Bone');
            UpdateVisualReferences({OriginalSubtractVisual,ExampleArray{5}(:,:,1),OriginalSubtractVisual.Position(3),'',''},{UpdatedSubtractVisual,ExampleArray{5}(:,:,1),UpdatedSubtractVisual.Position(3),'',''},{SubtractMask,ones(size(ExampleArray{5}(:,:,1),[1,2])),SubtractMask.Position(3),'',''});
            if strcmp(BackgroundChoice.Value,'Binary Mask')
                ConfirmSubtract.ButtonPushedFcn = @(~,~)ConfirmBinaryMask;
                BinaryHistogram = uiaxes(SubtractOperationsPanel,'Position',ResolutionScaler([370 120 540 280]));%,'XTick',[]);
                FilteredCounts = UniqueNonZeroCounts(ExampleArray{5}(:,:,1));
                BH = histogram(BinaryHistogram,FilteredCounts,'FaceColor',SubtractOperationsPanel.BackgroundColor,'NumBins',20);
                ylim(BinaryHistogram,[0 max(BH.Values)]);
                xlim(BinaryHistogram,[min(FilteredCounts,[],'All') max(FilteredCounts,[],'All')]);
                grid(BinaryHistogram,'on');
                BH.NumBins = 50;
                title(BinaryHistogram,'Intensity Frequency');
                BinaryPanel = uipanel(SubtractOperationsPanel,'Position',ResolutionScaler([400 50 500 60]),'BorderWidth',0,'BackgroundColor',SubtractOperationsPanel.BackgroundColor);
                BinarySlideHolder = uigridlayout(BinaryPanel,'RowHeight',{'1x','fit'},'ColumnWidth',{'1x'});
                BinarySlider = uislider(BinarySlideHolder,'Limits',[min(min(FilteredCounts,[],'All'),0) max(FilteredCounts,[],'All')],'Value',max(FilteredCounts,[],'All')/2,'ValueChangedFcn',@(~,~)SlideBinary());
                SlideLine = xline(BinaryHistogram,BinarySlider.Value,'Color',[0.7422 0.4844 0.918],'LineWidth',2);
                SlideBinary();
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
                FirstSigmaField = uieditfield(SubtractOperationsPanel,'Position',ResolutionScaler([630 75 70 20]),'FontSize',13,'ValueChangedFcn',@(src,event)SubtractFieldCheck(src,event),'Value','0.5','ToolTip',STip);
                SecondSigmaLabel = uilabel(SubtractOperationsPanel,'Position',ResolutionScaler([710 75 20 20]),'Text','Y:','FontSize',14,'VerticalAlignment','Center','FontWeight','Bold','Visible','off','ToolTip',STip);
                SecondSigmaField = uieditfield(SubtractOperationsPanel,'Position',ResolutionScaler([730 75 70 20]),'FontSize',13,'ValueChangedFcn',@(src,event)SubtractFieldCheck(src,event),'Value','0.5','Visible','off','ToolTip',STip);
                ThirdSigmaLabel = uilabel(SubtractOperationsPanel,'Position',ResolutionScaler([810 75 20 20]),'Text','Z:','FontSize',14,'VerticalAlignment','Center','FontWeight','Bold','Visible','off','ToolTip',STip);
                ThirdSigmaField = uieditfield(SubtractOperationsPanel,'Position',ResolutionScaler([830 75 70 20]),'FontSize',13,'ValueChangedFcn',@(src,event)SubtractFieldCheck(src,event),'Value','0.5','Visible','off','ToolTip',STip);
                FirstSizeLabel = uilabel(SubtractOperationsPanel,'Position',ResolutionScaler([610 50 20 20]),'Text','N:','FontSize',14,'VerticalAlignment','Center','FontWeight','Bold','ToolTip',KTip);
                FirstSizeField = uieditfield(SubtractOperationsPanel,'Position',ResolutionScaler([630 50 70 20]),'FontSize',13,'ValueChangedFcn',@(src,event)SubtractFieldCheck(src,event),'Value','3','ToolTip',KTip);
                SecondSizeLabel = uilabel(SubtractOperationsPanel,'Position',ResolutionScaler([710 50 20 20]),'Text','Y:','FontSize',14,'VerticalAlignment','Center','FontWeight','Bold','Visible','off','ToolTip',KTip);
                SecondSizeField = uieditfield(SubtractOperationsPanel,'Position',ResolutionScaler([730 50 70 20]),'FontSize',13,'ValueChangedFcn',@(src,event)SubtractFieldCheck(src,event),'Value','3','Visible','off','ToolTip',KTip);
                ThirdSizeLabel = uilabel(SubtractOperationsPanel,'Position',ResolutionScaler([810 50 20 20]),'Text','Z:','FontSize',14,'VerticalAlignment','Center','FontWeight','Bold','Visible','off','ToolTip',KTip);
                ThirdSizeField = uieditfield(SubtractOperationsPanel,'Position',ResolutionScaler([830 50 70 20]),'FontSize',13,'ValueChangedFcn',@(src,event)SubtractFieldCheck(src,event),'Value','3','Visible','off','ToolTip',KTip);
                PreviewGaussian();
            end
            fontname(LoadFig,GetFont());
            LoadGroup.SelectedTab = SubtractTab;
        end

        function SlideBinary()
        % Function to change masking and histogram labeling
            SlideLine.Value = BinarySlider.Value;
            [UpdatedPreview,CreatedMask] = BinaryMaskSubtraction(ExampleArray(1,4:5));
            imagesc(SubtractMask,CreatedMask{1}(:,:,1));
            imagesc(UpdatedSubtractVisual,UpdatedPreview{1,2});
        end

        function [OutArray,CurrentMask] = BinaryMaskSubtraction(InsertArray)
        % Function that performs binary mask operation
            for p = height(InsertArray):-1:1
                CurrentMask{p} = InsertArray{p,2}(:,:,1)<BinarySlider.Value;
                SpectrumMask = mean(InsertArray{p,1}.*repmat(CurrentMask{p},[1,1,size(InsertArray{p,1},3)]),[1,2]);
                OutArray{p,1} = InsertArray{p,1}-SpectrumMask(ones(1,size(InsertArray{p,1},1)),ones(1,size(InsertArray{p,1},2)),:);
                OutArray{p,2}(:,:,1) = mean(OutArray{p,1},3);
            end
        end

        function ConfirmBinaryMask()
        % Function to confirm binary mask details
            BinaryProgress = uiprogressdlg(LoadFig,'Title','Subtracting binary masks','Message','Binary mask background removal ongoing','Indeterminate','on');
            ProcessedArray(:,2:3) = BinaryMaskSubtraction(ProcessedArray(:,2:3));
            ExampleArray(:,4:5) = BinaryMaskSubtraction(ExampleArray(:,4:5));
            BinaryProgress.Message = 'Finished subtraction!';
            pause(0.1); 
            close(BinaryProgress);
            EndSubtract();
        end

        function [OutArray,Heatmap] = Gaussian2D(InsertArray)
        % Function to perform 2D Gaussian blurring
            for p = height(InsertArray):-1:1
                for h = size(InsertArray{p,1},3):-1:1
                    OutArray{p,1}(:,:,h) = imgaussfilt(InsertArray{p,1}(:,:,h),Sigma(1:2),'FilterSize',Kernel(1:2),'FilterDomain',lower(FilterType.Value));
                end
                OutArray{p,2}(:,:,1) = mean(OutArray{p,1},3);
                Heatmap{p} = abs(mean(InsertArray{p,1}-OutArray{p,1},3));
            end
        end

        function [OutArray,Heatmap] = Gaussian3D(InsertArray)
        % Function to perform 2D Gaussian blurring
            for p = height(InsertArray):-1:1
                OutArray{p,1} = imgaussfilt3(InsertArray{p,1},Sigma(1:3),'FilterSize',Kernel(1:3),'FilterDomain',lower(FilterType.Value));
                OutArray{p,2}(:,:,1) = mean(OutArray{p,1},3);
                Heatmap{p} = abs(mean(InsertArray{p,1}-OutArray{p,1},3));
            end
        end

        function PreviewGaussian()
        % Function to perform Gaussian operations
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
                FirstSizeField.Value = string(2*ceil(2*str2double(FirstSigmaField.Value))+1);
                SecondSizeField.Value = FirstSizeField.Value;
                ThirdSizeField.Value = FirstSizeField.Value;
                FirstSizeLabel.Text = 'N:';
                SecondSizeLabel.Visible = 'off';
                SecondSizeField.Visible = 'off';
                ThirdSizeLabel.Visible = 'off';
                ThirdSizeField.Visible = 'off';
            elseif strcmp(SizeType.Value,'Default') && strcmp(SigmaType.Value,'Vector')
                FirstSizeField.Value = string(2*ceil(2*str2double(FirstSigmaField.Value))+1);
                SecondSizeField.Value = string(2*ceil(2*str2double(SecondSigmaField.Value))+1);
                ThirdSizeField.Value = string(2*ceil(2*str2double(ThirdSigmaField.Value))+1);
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
            Sigma = [str2double(FirstSigmaField.Value) str2double(SecondSigmaField.Value) str2double(ThirdSigmaField.Value)];
            Kernel = [str2double(FirstSizeField.Value) str2double(SecondSizeField.Value) str2double(ThirdSizeField.Value)];
            PreviewGaussian();
        end

        function SubtractFieldCheck(Source,Event)
        % Function to ensure correct values
            switch Source
                case {FirstSigmaField,SecondSigmaField,ThirdSigmaField}
                    if str2double(Event.Value) < 0
                        uialert(LoadFig,sprintf('%s is not a valid entry. Sigma values must be positive numbers. Reverting to previous entry.',Event.Value),'Invalid Sigma','Icon','Error');
                        Source.Value = Event.PreviousValue;
                        return;
                    end
                    if strcmp(SigmaType.Value,'Scalar')
                        SecondSigmaField.Value = FirstSigmaField.Value;
                        ThirdSigmaField.Value = FirstSigmaField.Value;
                    end
                    Sigma = [str2double(FirstSigmaField.Value) str2double(SecondSigmaField.Value) str2double(ThirdSigmaField.Value)];
                    if strcmp(SizeType.Value,'Default')
                        FirstSizeField.Value = string(2*ceil(2*str2double(FirstSigmaField.Value))+1);
                        SecondSizeField.Value = string(2*ceil(2*str2double(SecondSigmaField.Value))+1);
                        ThirdSizeField.Value = string(2*ceil(2*str2double(ThirdSigmaField.Value))+1);
                    end
                    PreviewGaussian();
                case {FirstSizeField,SecondSizeField,ThirdSizeField}
                    if str2double(Event.Value) < 0 || mod(str2double(Event.Value),1) ~= 0 || mod(str2double(Event.Value),2) ~= 1
                        uialert(LoadFig,sprintf('%s is not a valid entry. Size values must be positive odd integers. Reverting to previous entry.',Event.Value),'Invalid Size','Icon','Error');
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
                    Kernel = [str2double(FirstSizeField.Value) str2double(SecondSizeField.Value) str2double(ThirdSizeField.Value)];
                    PreviewGaussian();
            end
        end

        function ConfirmGaussianBlur()
        % Function to confirm gaussian blur details
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

        function CancelSubtract()
        % Function to cancel current subtraction and restore old values
            ExampleArray(:,4:5) = PreviousExample;
            EndSubtract();
            delete(SubtractTab);
        end

        function EndSubtract()
        % Closes tab and restores processing abilities
            ToggleEnable(ExecuteBackground,BackgroundChoice,ExecuteUnmixing,UnmixingChoice,ExecuteContrastBright);
            if size(ProcessedArray{1,3},3) > 1
                ExecuteColorAdjust.Enable = 'on';
            end
            imagesc(ProcessedVisual,ProcessedArray{1,3}(:,:,1));
            LoadGroup.SelectedTab = HomeTab;
        end
    end

    function LaunchUnmixing()
    % Function to launch the UI tab for background removal
        if isempty(PrimaryArray) || isempty(ProcessedArray) || isempty(ExampleArray)
            uialert(LoadFig,'There is no data! Please load data before attempting unmixing.','No Data','Icon','Error');
        elseif isempty(ReferenceArray)
            uialert(LoadFig,'There are no chemical references! Please load references before attempting unmixing.','No References','Icon','Error');
        else
            ToggleEnable(ExecuteBackground,BackgroundChoice,ExecuteUnmixing,UnmixingChoice,ExecuteContrastBright);
            ExecuteColorAdjust.Enable = 'off';
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
            uibutton(UnmixParametersPanel,'Position',([UnmixParametersPanel.Position(3) 0 0 0]+ResolutionScaler([-560 360 560 30]))./([2 1 1 1]),'Text',sprintf('Auto-Calibrate %s',UnmixingChoice.Value),'FontSize',15,'Enable','off');
            CoefficientsTable = uitable(UnmixParametersPanel,'Position',([UnmixParametersPanel.Position(3) 0 0 0]+ResolutionScaler([-560 125 560 230]))./([2 1 1 1]),'ColumnName',{'Reference Map','Lambda'}, ...
                'ColumnEditable',[false true],'ColumnFormat',{'char','numeric'},'ColumnWidth',{'auto','auto'},'FontSize',16,'CellEditCallback',@(src,event)LambdaEdit(event));          
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
        end
        
        function LambdaEdit(Event)
        % Function to perform quick LASSO previews
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
                        DisplayComposite(CombinedUnmixVisual,ExampleArray{5}(:,:,ValidLambdas+1),ReferenceArray(ValidLambdas,6));
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
                        DisplayComposite(CombinedUnmixVisual,ExampleArray{5}(:,:,ValidLambdas+1),ReferenceArray(ValidLambdas,6));
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
                    DisplayComposite(ProcessedVisual,ExampleArray{5}(:,:,2:end),ReferenceArray(:,6));
                    ProcessedLabel.Text = 'Processed Unmixed Image';
                else
                    DisplayColored(ProcessedVisual,ExampleArray{5}(:,:,2),ReferenceArray{1,6});
                    ProcessedLabel.Text = sprintf('Processed %s Image',ReferenceArray{1,4});
                end
                UnmixProgress.Message = 'Finished batch unmixing!';
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
            ToggleEnable(ExecuteBackground,BackgroundChoice,ExecuteUnmixing,UnmixingChoice,ExecuteContrastBright);
            if size(ProcessedArray{1,3},3) > 1
                ExecuteColorAdjust.Enable = 'on';
            end
            LoadGroup.SelectedTab = HomeTab;
        end
    end

    % Export functions
    function TempExport()
    % Function to temporarily export all details. Will be repalced by UI
        if isempty(PrimaryArray) || isempty(ProcessedArray) || isempty(ExampleArray)
            uialert(LoadFig,'Something must be exported. Not all necessary data exists!','Empty Export','Icon','Warning');
            return;
        end
        ExportProgress = uiprogressdlg(LoadFig,'Title','Exporting Data','Message','Beginning data export');
        for b = 1:size(ProcessedArray,1)
            ExportProgress.Message = sprintf('Exporting data set %d/%d',b,size(ProcessedArray,1));
            ExportProgress.Value = b/size(ProcessedArray,1);
            OutputDir = fullfile(Path,ProcessedArray{b,1});
            if ~exist(OutputDir,'dir')
                mkdir(OutputDir);
            end
            for p = 1:height(ReferenceArray)
                for c = 3:-1:1
                    RGBExport(:,:,c) = double(ProcessedArray{b,3}(:,:,p+1))*ReferenceArray{p,6}(c);
                end
                imwrite(max(min(RGBExport,1),0),fullfile(OutputDir,[ProcessedArray{b,1},'_',ReferenceArray{p,4},'.tiff']),'Tiff');
            end
        end
        ExportProgress.Message = 'Export complete!';
        pause(0.1);
        close(ExportProgress);
        uiresume(LoadFig)
        delete(LoadFig)
    end
end

%% External UI Functions
function varargout = FormatUI(ScreenSize)
% Function to create a UI to prompt user for the format of the load files
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
        % Function to update format preface
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
% Function to load data depending on format
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
% Function to take a *.txt file array and reshape according to user
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
        'ColumnFormat',{'char','logical','numeric','numeric','numeric'},'ColumnWidth',{'auto','fit','fit','fit','fit'},'CellEditCallback',@(src,event)TableEdit(src,event));
    AllButton = uibutton(ReshapeFig,'Position',[800 265 180 25],'Text','Apply to All Data','FontSize',13,'Enable','off','ButtonPushedFcn',@(src,event)ApplyToAll(src),'Tooltip','Apply previous column entry to all data sets.');
    ConfirmReshape = uibutton(ReshapeFig,'Position',[(ReshapeFig.Position(3)-180)/2 10 180 30],'Text','Confirm Data Shapes','FontSize',15,'ButtonPushedFcn',@(~,~)ConfirmTable);
    fontname(ReshapeFig,GetFont());
    uiwait(ReshapeFig);

    function UpdateTableData(NewRow,NewCol,NewVal)
    % Function to adjust the height and slices columns in the table
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
    % Function to call manual adjustments to table entries
        [EventRow, EventCol] = deal(Event.Indices(1),Event.Indices(2));
        UpdateTableData(EventRow,EventCol,Event.NewData);
        Source.Data = TableData;
        AllButton.Enable = 'on';
        setappdata(AllButton,'LastEdit',Event.Indices);
        setappdata(AllButton,'LastValue',Event.NewData);
    end

    function ApplyToAll(Source)
    % Function to call automatic adjustments to table entries
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
    % Function to reshape the data inside the input array to the table values
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
% Function that sets parameters for the ROI
    RefParamFig = uifigure('Position',[(ScreenSize(3)-690)/2 (ScreenSize(4)-580)/2 690 580],'Name','Chemical Reference Map Parameters');
    ConfirmRef = uibutton(RefParamFig,'Position',[350 10 330 30],'Text','Confirm Reference Map','FontSize',16,'FontWeight','Bold','ButtonPushedFcn',@(~,~)ConfirmRefMap);
    if size(RefParam,2) == 7
        OutputParameters = RefParam;
        uilabel(RefParamFig,'Position',[(RefParamFig.Position(3)-600)/2 (RefParamFig.Position(4)-30) 600 30],'Text','Modifying Chemical Reference Map','FontWeight','Bold','FontSize',22,'HorizontalAlignment','Center','VerticalAlignment','Center');
    elseif strcmp(CallType,'Ref')
        OutputParameters = [RefParam, {ones(1,size(RefParam{2},3)),'',1,rand(1,3),{}}];
        uilabel(RefParamFig,'Position',[(RefParamFig.Position(3)-600)/2 (RefParamFig.Position(4)-30) 600 30],'Text','Creating a Chemical Reference Map','FontWeight','Bold','FontSize',22,'HorizontalAlignment','Center','VerticalAlignment','Center');
    elseif strcmp(CallType,'Fit')
        OutputParameters = [RefParam, {ones(1,size(RefParam{2},3)),'',1,rand(1,3),{}}];
        uilabel(RefParamFig,'Position',[(RefParamFig.Position(3)-600)/2 (RefParamFig.Position(4)-30) 600 30],'Text','Setting Background Chemical Map','FontWeight','Bold','FontSize',22,'HorizontalAlignment','Center','VerticalAlignment','Center');
    end
    uilabel(RefParamFig,'Position',[(RefParamFig.Position(3)-670)/2 (RefParamFig.Position(4)-55) 670 20],'Text',OutputParameters{1},'FontAngle','Italic','FontSize',16,'HorizontalAlignment','Center');

    BrowserPanel = uipanel(RefParamFig,'Position',[10 10 330 500],'BackgroundColor',[0.7227 0.582 0.9258]);
    uilabel(BrowserPanel,'Position',[5 BrowserPanel.Position(4)-30 200 30],'Text','Stack Browser','FontWeight','Bold','FontSize',20);
    ReferenceLabel = uilabel(BrowserPanel,'Position',[30 455 270 20],'Text',sprintf('%s Reference Map',OutputParameters{4}),'FontSize',15','FontAngle','Italic','HorizontalAlignment','Center');
    ReferenceStack = uiaxes(BrowserPanel,'Position',[30 175 270 270],'XTick',[],'YTick',[]);
    axis(ReferenceStack,'image');
    ReferenceSizeLabel = uilabel(BrowserPanel,'Position',[30 155 270 20],'Text','','FontSize',15,'HorizontalAlignment','Center');
    AdjustAxesSize(ReferenceStack,size(OutputParameters{2},[1,2]),ReferenceStack.Position(3),ReferenceLabel,ReferenceSizeLabel)
    imagesc(ReferenceStack,OutputParameters{2}(:,:,OutputParameters{5}));
    BrowseBox = uieditfield(BrowserPanel,'numeric','Position',[285 100 35 40],'Value',OutputParameters{5},'Limits',[1 size(OutputParameters{2},3)],'FontSize',12,'HorizontalAlignment','Center','ValueChangedFcn',@(~,~)UpdateRefStack('Field'),'RoundFractionalValues','on');
    SliderPanel = uipanel(BrowserPanel,'Position',[10 90 270 60],'BorderWidth',0,'BackgroundColor',[0.7227 0.582 0.9258]);
    SliderHolder = uigridlayout(SliderPanel,'RowHeight',{'1x','fit'},'ColumnWidth',{'1x'});
    BrowseSlider = uislider(SliderHolder,'Limits',[1 size(OutputParameters{2},3)],'Value',OutputParameters{5},'ValueChangedFcn',@(~,~)UpdateRefStack('Slider'));
    CircleROI = uibutton(BrowserPanel,'Position',[10 50 150 30],'Text','Draw Circle ROI','FontSize',14,'ButtonPushedFcn',@(~,~)ROIDraw('Circle'));
    PolygonROI = uibutton(BrowserPanel,'Position',[170 50 150 30],'Text','Draw Polygon ROI','FontSize',14,'ButtonPushedFcn',@(~,~)ROIDraw('Polygon'));
    FreehandROI = uibutton(BrowserPanel,'Position',[10 10 150 30],'Text','Draw Freehand ROI','FontSize',14,'ButtonPushedFcn',@(~,~)ROIDraw('Freehand'));
    RemoveROI = uibutton(BrowserPanel,'Position',[170 10 150 30],'Text','Point Erase ROI(s)','FontSize',14,'ButtonPushedFcn',@(~,~)ROIRemove);

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
    % Function to update chemical reference name from input
        ReferenceLabel.Text = sprintf('%s Reference Map',RefField.Value);
        OutputParameters{4} = RefField.Value;
    end

    function UpdateRefStack(Source)
    % Function to update reference stack displayed
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
    % Function to set new color
        OutputParameters{6} = uisetcolor(OutputParameters{6});
        ColorPicker.BackgroundColor = OutputParameters{6};
        UpdateRefStack('Slider');
        CentralUI.Visible = 'off';
        RefParamFig.Visible = 'off';
        CentralUI.Visible = 'on';
        RefParamFig.Visible = 'on';
    end

    function ROIDraw(Style)
    % Function to draw new ROI onto the figure plots
        ClearPlotInterface(ReferenceStack);
        ToggleEnable(CircleROI,PolygonROI,FreehandROI,RemoveROI,ColorPicker,ConfirmRef);
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
            Boundaries = arrayfun(@(k) B{k}, 1:N, 'UniformOutput',false);
            OutputParameters{7} = [OutputParameters{7},Boundaries(1)];
            UpdateRefStack('Field');
        catch
            uialert(RefParamFig,'ROI drawing failed, shape incomplete. Please try again.','Incomplete ROI','Icon','Warning');
        end
        ToggleEnable(CircleROI,PolygonROI,FreehandROI,RemoveROI,ColorPicker,ConfirmRef);
    end

    function ROIRemove()
    % Function to remove a selected ROI on the figure plots
        ClearPlotInterface(ReferenceStack);
        ToggleEnable(CircleROI,PolygonROI,FreehandROI,RemoveROI,ColorPicker,ConfirmRef);
        try
            ClickPoint = drawpoint(ReferenceStack);
            ClickSpot = ClickPoint.Position;
            delete(ClickPoint);
            RemovedROIs = false(1, length(OutputParameters{7}));
            for g = 1:length(OutputParameters{7})
                BoundaryROI = OutputParameters{7}{g};
                if inpolygon(ClickSpot(1), ClickSpot(2), BoundaryROI(:,2), BoundaryROI(:,1))
                    RemovedROIs(g) = true;
                end
            end
            OutputParameters{7}(RemovedROIs) = [];
            UpdateRefStack('Field');
        catch
            uialert(RefParamFig,'Failed to remove ROI. Please try again.','ROI Removal Error','Icon','Warning');
        end
        ToggleEnable(CircleROI,PolygonROI,FreehandROI,RemoveROI,ColorPicker,ConfirmRef);
    end

    function ChangeConfirm()
    % Function to adjust confirm text depending on AddToFit
        if AddToFit.Value == 1
            ConfirmRef.Text = 'Set Characteristic Peaks';
        elseif AddToFit.Value == 0
            ConfirmRef.Text = 'Confirm Reference Map';
        end
    end

    function ConfirmRefMap()
    % Function to confirm output of this UI
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
            ROIMasks = cellfun(@(x) poly2mask(x(:,2), x(:,1), size(OutputParameters{2},1), size(OutputParameters{2},2)), OutputParameters{7}, 'UniformOutput', false);
            CombinedROIMask = any(cat(3, ROIMasks{:}), 3);
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
            close(RefParamFig);
        end
    end
end

function FitsArray = SpectralFind(SpecParams,ScreenSize)
% Function to establish key peaks of a chemical
    SpecPeakFig = uifigure('Position',[(ScreenSize(3)-860)/2 (ScreenSize(4)-600)/2 860 600],'Name','Selecting Characteristic Spectral Peaks');
    uilabel(SpecPeakFig,'Position',[(SpecPeakFig.Position(3)-750)/2 (SpecPeakFig.Position(4)-30) 750 30],'Text',sprintf('Labeling Characteristic %s Peaks',SpecParams{2}),'FontWeight','Bold','FontSize',20,'HorizontalAlignment','Center','VerticalAlignment','Center');
    SpecParams{1} = NormalizeMinMax(SpecParams{1});
    PeaksData = {SpecParams{2}, NaN, NaN, NaN; SpecParams{2}, NaN, NaN, NaN};
    OperationsPanel = uipanel(SpecPeakFig,'Position',[520 10 330 560],'BackgroundColor',SpecParams{4});
    uilabel(OperationsPanel,'Position',[5 OperationsPanel.Position(4)-30 220 30],'Text','Characteristic Peaks','FontWeight','Bold','FontSize',20);
    uilabel(OperationsPanel,'Position',[10 515 250 20],'Text','Number of Characteristic Peaks:','FontSize',15);
    PeakNum = uidropdown(OperationsPanel,'Position',[260 510 60 20],'Items',arrayfun(@num2str, 1:7, 'UniformOutput', false),'Value','2','FontSize',15,'ValueChangedFcn',@(~,~)ChangePeakNum);
    AutoFind = uibutton(OperationsPanel,'Position',[(OperationsPanel.Position(3)-310)/2 470 310 30],'Text','Auto-Detect Peaks','FontSize',15,'ButtonPushedFcn',@(~,~)AutoDetect);
    PeaksTable = uitable(OperationsPanel,'Position',[(OperationsPanel.Position(3)-310)/2 50 310 405],'Data',PeaksData(:,2:3),'ColumnName',{'Frame Number','Wavenumber'},'ColumnEditable',[true true],'ColumnFormat',{'numeric','numeric'},'ColumnWidth',{'auto','auto'},'CellEditCallback',@(src,event)PlotCharacteristicPeaks(event));
    ConfirmPeakChoice = uibutton(OperationsPanel,'Position',[(OperationsPanel.Position(3)-310)/2 10 310 30],'Text','Confirm Characteristic Peaks','FontSize',16,'FontWeight','Bold','ButtonPushedFcn',@(~,~)ConfirmPeaks);
    PeakAxes = uiaxes(SpecPeakFig,'Position',[10 10 500 560],'XLim',[1 length(SpecParams{1})],'YLim',[-0.05 1.05]);
    PlotCharacteristicPeaks()
    xlabel(PeakAxes,'Frame (#)','FontSize',15);
    ylabel(PeakAxes,'Normalized Intensity','FontSize',15);
    grid(PeakAxes,'on');

    fontname(SpecPeakFig,GetFont());
    uiwait(SpecPeakFig);

    function PlotCharacteristicPeaks(varargin)
    % Function that plots characteristic peaks and any labels
        PeaksData(:,2:3) = PeaksTable.Data;
        if nargin == 1
            Event = varargin{1};
            [EventRow, EventCol] = deal(Event.Indices(1),Event.Indices(2));
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
    % Function to change number of peaks to be found
        PeaksToFind = str2double(PeakNum.Value);
        PeaksData = [PeaksData;repmat({SpecParams{2},NaN,NaN,NaN},PeaksToFind-height(PeaksData),1)];
        PeaksData = PeaksData(1:PeaksToFind,:);
        PeaksTable.Data = PeaksData(:,2:3);
        PlotCharacteristicPeaks()
    end
    
    function AutoDetect()
    % Function to automatically find peaks of certain value
        ToggleEnable(PeakNum,AutoFind,ConfirmPeakChoice,PeaksTable);
        [PeakIndex,FrameIndex] = findpeaks(SpecParams{1},'NPeaks',height(PeaksData),'MinPeakDistance',7,'MinPeakProminence',0.03);
        for l = 1:length(FrameIndex)
            PeaksData(l,:) = {SpecParams{2},FrameIndex(l),NaN,PeakIndex(l)};
        end
        PeaksTable.Data = PeaksData(:,2:3);
        PlotCharacteristicPeaks();
        ToggleEnable(PeakNum,AutoFind,ConfirmPeakChoice,PeaksTable);
    end
    
    function ConfirmPeaks()
    % Function to validate peak selection and return correct array
        if any(isnan(cell2mat(PeaksData(:,2)))) || any(isnan(cell2mat(PeaksData(:,3))))
            uialert(SpecPeakFig,'The table is missing entries! Please ensure all characteristic peaks are properly identified with a frame and wavenumber.','Incomplete Entries','Icon','Warning');
            return;
        end
        FitsArray = PeaksData(:,1:3);
        close(SpecPeakFig);
    end
end

%% Utility Functions
function OSFont = GetFont()
% Function to get font based on OS
    if ispc
        OSFont = 'Century Schoolbook';
    elseif ismac
        OSFont = 'Hoefler Text';
    else
        OSFont = 'Arial';
    end
end

function PositionScaled = ResolutionScaler(InputVec)
% Function to scale to screen resolution
    ScreenSize = get(groot,'ScreenSize');
    PositionScaled = floor(InputVec*min([ScreenSize(3)/1920,ScreenSize(4)/1080]));
    %PositionScaled = floor(InputVec.*repmat((ScreenSize(3:4)./[1920,1080]),1,length(InputVec)/2));
end

function ToggleEnable(varargin)
% Function to toggle the enabled state of a UI element
    for u = 1:nargin
        CurrentElement = varargin{u};
        if strcmp(CurrentElement.Enable,'on')
            NewState = 'off';
        else
            NewState = 'on';
        end
        CurrentElement.Enable = NewState;
    end
end

function MenuMade = CreateContext(Home,MenuItems,MenuFunctions,MenuVisibility)
% Function to create context menus for tables    
    MenuMade = uicontextmenu(Home,'ContextMenuOpeningFcn',MenuVisibility);
    for q = 1:length(MenuItems)
        uimenu(MenuMade,'Text',MenuItems{q},'MenuSelectedFcn',MenuFunctions{q})
    end
end

function ToggleVisible(Source,Event)
% Function to hide menus unless over table
    ClickRow = ~isempty(Event.InteractionInformation.Row);
    MenuItems = Source.Children;
    for q = 1:length(MenuItems)
        MenuItems(q).Visible = ClickRow;
    end
end

function AdjustAxesSize(varargin)
% Function to dynamically readjust axes elements to fit image aspect ratio
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
% Function to update visual references    
    % Format = {Axes,Data,SizeLimit,Label,SizeLabel}
    for w = nargin:-1:1
        AdjustAxesSize(varargin{w}{1},size(varargin{w}{2},[1,2]),varargin{w}{3},varargin{w}{4},varargin{w}{5});
        imagesc(varargin{w}{1},varargin{w}{2});
        LinkedObjects(w) = varargin{w}{1};
    end
    linkaxes(LinkedObjects);
end

function ClearPlotInterface(AxesInUse)
% Function to clear axes interactive tools before setting user interaction
    zoom(AxesInUse,'off');
    pan(AxesInUse,'off');
    datacursormode(AxesInUse,'off');
    brush(AxesInUse,'off');
end

function NormalizedMat = NormalizeMinMax(InVec)
% Function to create normalized matrices based on minimums and maximums
    NormalizedMat = (InVec-min(InVec(:)))./(max(InVec(:))-min(InVec(:)));
end

function FilteredCounts = UniqueNonZeroCounts(InsertImage)
% Function to 
    [UniqueCounts,~,UniqueIDs] = unique(InsertImage);
    FilteredCounts = UniqueCounts(accumarray(UniqueIDs,1)>1);
end

function DisplayColored(TargetAxes,Image2D,RGBVec)
% Function to display an image on a custom RGB color map
    imagesc(TargetAxes,Image2D);
    colormap(TargetAxes,linspace(0,1,255)'*RGBVec);
end

function DisplayComposite(TargetAxes,ImagesMatrix,ColorsArray)
% Function to display composite of images using RGB weights
    imagesc(TargetAxes,CreateComposite(ImagesMatrix,ColorsArray));
end

function CompositeImage = CreateComposite(ImagesMatrix, ColorsArray)
% Function to create an alpha-blended composite image with custom colors
    CompositeImage = zeros([size(ImagesMatrix,[1,2]), 3]);
    for q = 1:size(ImagesMatrix,3)
        for Channel = 3:-1:1
            ColoredImage(:,:,Channel) = NormalizeMinMax(ImagesMatrix(:,:,q))*ColorsArray{q}(Channel);
        end
        CompositeImage = (1-1/size(ImagesMatrix,3))*CompositeImage + 1/size(ImagesMatrix,3)*ColoredImage;
    end
end

%% Custom Processing Functions
function [ConcentrationMaps,Exit] = NNegLasso(HyperspectralStack,ReferenceSpectra,SparsityVector,ADMMParam,IterationLimit,Tolerance,RegularizationBalance)
% Function to perform lasso-based unmixing with non-negativity constraint
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
