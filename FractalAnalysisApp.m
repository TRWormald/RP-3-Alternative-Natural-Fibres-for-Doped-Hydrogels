function FractalAnalysisApp()
    addpath("hausDim\")
    addpath("boxcount\")
    %% Shared Variables
    img = []; % Colour Image Loaded into Programme
    imgGray = []; % Grayscale Image from img
    storedImage = []; % Image Storage dictated by User
    imageCache = []; % Temp Image Storage
    
    binaryImgT2 = []; % Store Of Pre Processed Binary Image for T2
    processedImgT2 = []; % Store of Processed Binary Image for T2
    binaryImgT3 = []; % Image used in determining fractal order

    %% UI STYLES
    styles.Header = {'FontSize', 15, 'FontWeight', 'bold', 'FontColor', [0.12 0.12 0.12]};
    styles.SubText = {'FontSize', 10, 'FontColor', [0.5 0.5 0.5]};
    styles.ButtonText = {'FontSize', 12, 'FontWeight', 'bold', 'FontColor', [0.12 0.12 0.12]};
    styles.ColouredButtonText = {'FontSize', 12, 'FontWeight', 'bold', 'FontColor', [1 1 1]};
    %% Overall Layout
   
    % Initially we obtain the screen size so that we can centre the window
    screensize = get(0, "MonitorPositions"); % Obtaining the screen size
    uiWidth    = 1080; % Window Width
    uiHeight   = 720; %  Window Height

    % Then we define the initial window 'panel' for the app
    appWindow = uifigure(Name="Image Processing App", ...
        Position=[(screensize(1,3)-uiWidth)/2, (screensize(1,4)-uiHeight)/2, uiWidth, uiHeight], ...
        Color=[0.96, 0.96, 0.96], Resize="off"); 

    % We have centred the window on startup and prevented it from being resized
    % We then define the initial grid for the app
    appGrid = uigridlayout(appWindow, [1 1], RowHeight={'1x'}, ColumnWidth={'1x'}, Padding=[0 0 0 0]);
    
    %{
     Since we want to have multiple functions in this app, it is best to
     distribute them over multiple tabs so that the UI doesn't get too
     cluttered
    %}

    % Tab group creation
    tabGroup = uitabgroup(appGrid);
    tabGroup.Layout.Row    = 1;
    tabGroup.Layout.Column = 1;
    tab1 = uitab(tabGroup, Title="Binarisation");       % This tab will deal with binarisation
    tab2 = uitab(tabGroup, Title="Post Processing");    % This tab will process the binarised images
    tab3 = uitab(tabGroup, Title="Fractal Analysis");   % This tab will do a fractal analysis on the binarised images

    %{
    The tabs in this app will follow similar structures with a panel to the left
    with controls whilst the right will have the results (typically a side
    by side comparison of the processed images or graphs)    
    %}

    %% TAB 1 - BINARISATION
    tab1_uiGrid = uigridlayout(tab1, [1,2], ColumnWidth = {256, '1x'}, RowHeight = {'1x'}, ...
        Padding = [12 12 12 12], ColumnSpacing = 12, BackgroundColor = [0.96 0.96 0.96]);

    % ~~~~~~~~~~~~~~~~~~
    % Left Column Layout
    % ~~~~~~~~~~~~~~~~~~
    tab1_leftColumn = uipanel(tab1_uiGrid, BorderType = 'none', BackgroundColor = [1 1 1]);
    tab1_leftColumn.Layout.Column  = 1;
    tab1_leftColumn.Layout.Row     = 1;
    
    % Defining the grid subdividing the left column
    t1_lcGrid = uigridlayout(tab1_leftColumn, [17 1], ...
        RowHeight = {50, 20, 20, 20, 20, 35, 50, 35, 20, 20, 20, 25, 25, 20, 35, 35, '1x'}, ...
        Padding = [20 20 20 20], RowSpacing = 5, BackgroundColor = [1 1 1]);
    
    % File Browse Button
    t1_browseButton = uibutton(t1_lcGrid, 'push', 'Text', "Browse for Image", styles.ColouredButtonText{:}, ...
        BackgroundColor = [0.12 0.44 0.84], ButtonPushedFcn = @onBrowse);
    t1_browseButton.Layout.Row = 1;

    % Divider 1 
    t1_div1 = uilabel(t1_lcGrid, Text=repmat(char(8212),1,15), FontColor=[0.82,0.82,0.82], ...
        HorizontalAlignment='center');
    t1_div1.Layout.Row = 2;

    % File Name Text
    t1_fileNameText = uilabel(t1_lcGrid, 'Text', "No Image Loaded", styles.SubText{:}, HorizontalAlignment='center');
    t1_fileNameText.Layout.Row = 3;

    % Divider 2 
    t1_div2 = uilabel(t1_lcGrid, Text=repmat(char(8212),1,15), FontColor=[0.82,0.82,0.82], ...
        HorizontalAlignment='center');
    t1_div2.Layout.Row = 4;

    % Threshold Section Label
    t1_thresholdTitle = uilabel(t1_lcGrid, 'Text', "Binarisation Threshold", styles.Header{:}, HorizontalAlignment = 'center');
    t1_thresholdTitle.Layout.Row = 5;

    % Threshold Sub-Grid (For Arrows & Value)
    t1_thresholdGrid = uigridlayout(t1_lcGrid, [1 3], ColumnWidth={40,'1x',40}, RowHeight={'1x'}, ...
        Padding=[0 0 0 0], ColumnSpacing=5, BackgroundColor=[1 1 1]);
    t1_thresholdGrid.Layout.Row = 6;

        % Up and Down Arrows
    t1_downButton = uibutton(t1_thresholdGrid,'push', styles.Header{:}, Text="<", FontSize=18, ButtonPushedFcn=@onDownT1);
    t1_downButton.Layout.Row = 1; t1_downButton.Layout.Column = 1;

    t1_upButton = uibutton(t1_thresholdGrid,'push', styles.Header{:}, Text=">", FontSize=18, ButtonPushedFcn=@onUpT1);
    t1_upButton.Layout.Row = 1; t1_upButton.Layout.Column = 3;
        
        % Threshold Value (Static & Overwritten by Functions)
    t1_thresholdValue = uilabel(t1_thresholdGrid, Text="128 / 255", FontSize=22, FontWeight='bold', ...
        FontColor=[0.12 0.44 0.84], HorizontalAlignment='center');
    t1_thresholdValue.Layout.Row = 1; t1_thresholdValue.Layout.Column = 2;

    % Slider
    t1_slider = uislider(t1_lcGrid, Limits=[0 255], Value=128, MajorTicks=[0 64 128 192 255], ...
        MajorTickLabels={'0','64','128','192','255'}, ValueChangedFcn=@onSliderT1, ValueChangingFcn=@onSliderT1);
    t1_slider.Layout.Row = 7;

    % Auto Binarise Button
    t1_autoButton = uibutton(t1_lcGrid, 'push', styles.ButtonText{:}, Text = "Auto (Otsu's Method)", ...
        BackgroundColor = [0.92 0.92 0.92], ButtonPushedFcn = @onAutoT1);
    t1_autoButton.Layout.Row = 8;

    % Divider 3
    t1_div3 = uilabel(t1_lcGrid, Text=repmat(char(8212),1,15), FontColor=[0.82,0.82,0.82], ...
        HorizontalAlignment='center');
    t1_div3.Layout.Row = 9;

    % Image Stats
    t1_imgStatsLabel = uilabel(t1_lcGrid, Text="Image Statistics", FontSize=13, FontWeight='bold', ...
        FontColor=[0.12 0.12 0.12]);
    t1_imgStatsLabel.Layout.Row = 10;

    t1_whiteLabel = uilabel(t1_lcGrid, Text="White (foreground):  --", FontSize=11, FontColor=[0.28 0.28 0.28]);
    t1_whiteLabel.Layout.Row = 11;

    t1_blackLabel = uilabel(t1_lcGrid, Text="Black (background):  --", FontSize=11, FontColor=[0.28 0.28 0.28]);
    t1_blackLabel.Layout.Row = 12;

    t1_resLabel = uilabel(t1_lcGrid, Text="", FontSize=10, FontColor=[0.55 0.55 0.55]);
    t1_resLabel.Layout.Row = 13;

    % Divider 4
    t1_div4 = uilabel(t1_lcGrid, Text=repmat(char(8212),1,15), FontColor=[0.82,0.82,0.82], ...
        HorizontalAlignment='center');
    t1_div4.Layout.Row = 14;

    % Save Button
    t1_saveButton = uibutton(t1_lcGrid, 'push', styles.ColouredButtonText{:}, Text="Save Binarised Image", ...
        BackgroundColor=[0.18 0.62 0.32], ButtonPushedFcn=@onSave);
    t1_saveButton.Layout.Row = 15; 
    
    % Store Button
    t1_storeButton = uibutton(t1_lcGrid, 'push', styles.ColouredButtonText{:}, Text="Store Binarised Image", ...
        BackgroundColor=[0.57 0.0 0.98], ButtonPushedFcn=@onStoreT1);
    t1_storeButton.Layout.Row = 16; 
    
    % ~~~~~~~~~~~~~~~~~~~
    % Right Column Layout
    % ~~~~~~~~~~~~~~~~~~~
    tab1_rightColumn = uipanel(tab1_uiGrid, BorderType = 'none', BackgroundColor = [1 1 1]);
    tab1_rightColumn.Layout.Column  = 2;
    tab1_rightColumn.Layout.Row     = 1;    
    
    % Defining the grid for the right column
    t1_rcGrid = uigridlayout(tab1_rightColumn, [3 2], RowHeight={20,'1x','0.6x'}, ColumnWidth={'1x','1x'}, ...
        Padding=[15 15 15 15], ColumnSpacing=15, RowSpacing=5, BackgroundColor=[1 1 1]);
    
    % Adding the Headings for the Images
    t1_header1 = uilabel(t1_rcGrid, styles.Header{:}, Text="ORIGINAL", HorizontalAlignment='center');
    t1_header1.Layout.Row = 1; t1_header1.Layout.Column = 1;

    t1_header2 = uilabel(t1_rcGrid, styles.Header{:}, Text="BINARISED", HorizontalAlignment='center');
    t1_header2.Layout.Row = 1; t1_header2.Layout.Column = 2;

    % Defining the axes for the Images
    t1_axOriginal = uiaxes(t1_rcGrid);
    t1_axOriginal.Layout.Row = 2; t1_axOriginal.Layout.Column = 1;
    t1_axOriginal.Visible = 'off';

    t1_axBinarised = uiaxes(t1_rcGrid);
    t1_axBinarised.Layout.Row = 2; t1_axBinarised.Layout.Column = 2;
    t1_axBinarised.Visible = 'off';

    t1_axHist = uiaxes(t1_rcGrid);
    t1_axHist.Layout.Row = 3; t1_axHist.Layout.Column = [1 2];
    t1_axHist .Visible = 'off';
    xlabel(t1_axHist, "Pixel Intensity");
    ylabel(t1_axHist, 'Count');
    title(t1_axHist, 'Grayscale Intensity Histogram');

    %% TAB 2 - POST PROCESSING
    tab2_uiGrid = uigridlayout(tab2, [1,2], ColumnWidth = {256, '1x'}, RowHeight = {'1x'}, ...
        Padding = [12 12 12 12], ColumnSpacing = 12, BackgroundColor = [0.96 0.96 0.96]);

    % ~~~~~~~~~~~~~~~~~~
    % Left Column Layout
    % ~~~~~~~~~~~~~~~~~~
    tab2_leftColumn = uipanel(tab2_uiGrid, BorderType = 'none', BackgroundColor = [1 1 1]);
    tab2_leftColumn.Layout.Column  = 1;
    tab2_leftColumn.Layout.Row     = 1;

    t2_lcGrid = uigridlayout(tab2_leftColumn, [10 1], ...
        RowHeight={20, 35, 20, 20, 20, 30, 50, 35, 35, '1x'}, Padding = [20 20 20 20], ...
        RowSpacing = 5, BackgroundColor = [1 1 1]);

    % Image Source Header
    t2_imSourceHead = uilabel(t2_lcGrid, styles.Header{:}, Text = "Image Source", HorizontalAlignment='center');
    t2_imSourceHead.Layout.Row = 1;

    % Use Stored Image Button
    t2_useStoredimage = uibutton(t2_lcGrid, 'push', styles.ColouredButtonText{:}, Text="Use Stored Image", ...
        BackgroundColor=[0.57 0.0 0.98], ButtonPushedFcn=@onUseStoredT2);
    t2_useStoredimage.Layout.Row = 2;

    % Divider 1
    t2_div2 = uilabel(t2_lcGrid, Text=repmat(char(8212),1,15), FontColor=[0.82,0.82,0.82], ...
        HorizontalAlignment='center');
    t2_div2.Layout.Row = 3;

    % Image Source Text
    t2_imageSource = uilabel(t2_lcGrid, styles.SubText{:}, Text = "No Image Selected", HorizontalAlignment = 'center');
    t2_imageSource.Layout.Row = 4;

    % Divider 2
    t2_div2 = uilabel(t2_lcGrid, Text=repmat(char(8212),1,15), FontColor=[0.82,0.82,0.82], ...
        HorizontalAlignment='center');
    t2_div2.Layout.Row = 5;

    % Area Threshold Grid
    t2_areaThreshGrid = uigridlayout(t2_lcGrid, [1 2], RowHeight = {'1x'}, ColumnWidth = {'1x', 75}, ...
        Padding = [0 0 0 0], BackgroundColor = [1 1 1]);
    t2_areaThreshGrid.Layout.Row = 6;
    
    % Area Threshold Title
    t2_areaThreshTitle = uilabel(t2_areaThreshGrid, styles.SubText{:}, FontSize = 12, Text = "Minimum Area (pixels):");
    t2_areaThreshTitle.Layout.Column = 1;

    % Area Threshold Spinner
    t2_areaThreshSpinner = uispinner(t2_areaThreshGrid, Limits = [0 1000], Value = 500, Step = 1);
    t2_areaThreshSpinner.Layout.Column = 2;

    % Remove Small Objects Button
    t2_removeObjButton = uibutton(t2_lcGrid, 'push', styles.ColouredButtonText{:}, Text = "Remove Small Objects", ...
        BackgroundColor = [0.18 0.62 0.32], ButtonPushedFcn = @onRemoveSmallObjects);
    t2_removeObjButton.Layout.Row = 8;

    % Store Button
    t2_storeButton = uibutton(t2_lcGrid, 'push', styles.ColouredButtonText{:}, Text="Store Binarised Image", ...
        BackgroundColor=[0.57 0.0 0.98], ButtonPushedFcn=@onStoreT2);
    t2_storeButton.Layout.Row = 9; 

    % ~~~~~~~~~~~~~~~~~~~
    % Right Column Layout
    % ~~~~~~~~~~~~~~~~~~~
    tab2_rightColumn = uipanel(tab2_uiGrid, BorderType = 'none', BackgroundColor = [1 1 1]);
    tab2_rightColumn.Layout.Column  = 2;
    tab2_rightColumn.Layout.Row     = 1;    

    t2_rcGrid = uigridlayout(tab2_rightColumn, [2 2], RowHeight={20,'1x'}, ColumnWidth={'1x','1x'}, ...
        Padding=[15 15 15 15], ColumnSpacing=15, RowSpacing=5, BackgroundColor=[1 1 1]);

    % Headers
    t2_header1 = uilabel(t2_rcGrid, styles.Header{:}, Text="INPUT BINARY", HorizontalAlignment='center');
    t2_header1.Layout.Row = 1; t2_header1.Layout.Column = 1;
    t2_header2 = uilabel(t2_rcGrid, styles.Header{:}, Text="PROCESSED BINARY", HorizontalAlignment='center');
    t2_header2.Layout.Row = 1; t2_header2.Layout.Column = 2;

    % Axes
    t2_axInput = uiaxes(t2_rcGrid);
    t2_axInput.Layout.Row = 2; t2_axInput.Layout.Column = 1;
    t2_axInput.Visible = 'off';

    t2_axProcessed = uiaxes(t2_rcGrid);
    t2_axProcessed.Layout.Row = 2; t2_axProcessed.Layout.Column = 2;
    t2_axProcessed.Visible = 'off';


    %% TAB 3 - FRACTAL ANALYSIS
    tab3_uiGrid = uigridlayout(tab3, [1,2], ColumnWidth = {256, '1x'}, RowHeight = {'1x'}, ...
        Padding = [12 12 12 12], ColumnSpacing = 12, BackgroundColor = [0.96 0.96 0.96]);

    % ~~~~~~~~~~~~~~~~~~
    % Left Column Layout
    % ~~~~~~~~~~~~~~~~~~
    tab3_leftColumn = uipanel(tab3_uiGrid, BorderType = 'none', BackgroundColor = [1 1 1]);
    tab3_leftColumn.Layout.Column  = 1;
    tab3_leftColumn.Layout.Row     = 1;
    
    t3_lcGrid = uigridlayout(tab3_leftColumn, [13 1], ...
        RowHeight={20, 35, 35, 20, 20, 20, '1x', 20, 20, 20, 50, 50, 0}, Padding = [20 20 20 20], ...
        RowSpacing = 5, BackgroundColor = [1 1 1]);
    
    % Image Source Header
    t3_imSourceHead = uilabel(t3_lcGrid, styles.Header{:}, Text = "Image Source", HorizontalAlignment='center');
    t3_imSourceHead.Layout.Row = 1;

    % Use Stored Image Button
    t3_useStoredimage = uibutton(t3_lcGrid, 'push', styles.ColouredButtonText{:}, Text="Use Stored Image", ...
        BackgroundColor=[0.57 0.0 0.98], ButtonPushedFcn=@onUseStoredT3);
    t3_useStoredimage.Layout.Row = 2;

    % Load Binary Image from File Button
    t3_loadImage = uibutton(t3_lcGrid, 'push', styles.ColouredButtonText{:}, Text = "Load Binary Image from File", ...
        BackgroundColor = [0.12 0.44 0.84], ButtonPushedFcn = @onLoadBinary);
    t3_loadImage.Layout.Row = 3;

    % Divider 1
    t3_div1 = uilabel(t3_lcGrid, Text=repmat(char(8212),1,15), FontColor=[0.82,0.82,0.82], ...
        HorizontalAlignment='center');
    t3_div1.Layout.Row = 4;

    % Image Source Text
    t3_imageSource = uilabel(t3_lcGrid, styles.SubText{:}, Text = "No Image Selected", HorizontalAlignment = 'center');
    t3_imageSource.Layout.Row = 5;

    % Divider 2
    t3_div1 = uilabel(t3_lcGrid, Text=repmat(char(8212),1,15), FontColor=[0.82,0.82,0.82], ...
        HorizontalAlignment='center');
    t3_div1.Layout.Row = 6;

    % Results Title
    t3_imSourceHead = uilabel(t3_lcGrid, styles.Header{:}, Text = "Fractal Dimension Results", HorizontalAlignment='center');
    t3_imSourceHead.Layout.Row = 8;

    % boxcount Results Text
    t3_boxcountResults = uilabel(t3_lcGrid, Text="boxcount D:  --", FontSize=12, FontWeight='bold', ...
        FontColor=[0.12 0.44 0.84], HorizontalAlignment='center');
    t3_boxcountResults.Layout.Row = 9;

    % hausDim Results Text
    t3_hausDimResults = uilabel(t3_lcGrid, Text="hausDim D:  --", FontSize=12, FontWeight='bold', ...
        FontColor=[0.84 0.12 0.12], HorizontalAlignment='center');
    t3_hausDimResults.Layout.Row = 10;
    
    % Run Fractal Analysis Button
    t3_runButton = uibutton(t3_lcGrid, 'push', styles.ColouredButtonText{:}, Text="Run Fractal Analysis",  ...
        BackgroundColor=[0.18 0.62 0.32], ButtonPushedFcn=@onRunFractalAnalysis);
    t3_runButton.Layout.Row = 12;

    % ~~~~~~~~~~~~~~~~~~~
    % Right Column Layout
    % ~~~~~~~~~~~~~~~~~~~
    tab3_rightColumn = uipanel(tab3_uiGrid, BorderType = 'none', BackgroundColor = [1 1 1]);
    tab3_rightColumn.Layout.Column  = 2;
    tab3_rightColumn.Layout.Row     = 1;    

    t3_rcGrid = uigridlayout(tab3_rightColumn, [2 2], RowHeight={20,'1x'}, ColumnWidth={'1x','1x'}, ...
        Padding=[15 15 15 15], ColumnSpacing=15, RowSpacing=5, BackgroundColor=[1 1 1]);

    t3_header1 = uilabel(t3_rcGrid, Text="BOXCOUNT", FontSize=11, FontWeight='bold', ...
        FontColor=[0.44 0.44 0.44], HorizontalAlignment='center');
    t3_header1.Layout.Row = 1; t3_header1.Layout.Column = 1;

    t3_axBoxcount = uiaxes(t3_rcGrid);
    t3_axBoxcount.Layout.Row = 2; t3_axBoxcount.Layout.Column = 1;
    xlabel(t3_axBoxcount, "log(box size)");
    ylabel(t3_axBoxcount, "log(box count)");

    t3_header2 = uilabel(t3_rcGrid, Text="HAUSDIM", FontSize=11, FontWeight='bold', ...
        FontColor=[0.44 0.44 0.44], HorizontalAlignment='center');
    t3_header2.Layout.Row = 1; t3_header2.Layout.Column = 2;

    t3_axHausDim = uiaxes(t3_rcGrid);
    t3_axHausDim.Layout.Row = 2; t3_axHausDim.Layout.Column = 2;
    xlabel(t3_axHausDim, "log(box size)");
    ylabel(t3_axHausDim, "log(box count)");
    



    %% FUNCTIONS
    % ~~~~~~~~~~~~~~~~~~
    % Callback Functions
    % ~~~~~~~~~~~~~~~~~~
    % Callback functions are those which are called when a button is pressed / the user interacts with the programme

    % File Browse
    function onBrowse(~,~)
        [file, path] = uigetfile({'*.jpg;*.jpeg;*.png;*.bmp', ...
            'Image Files (*.jpg,*.jpeg,*.png,*.bmp)'}, "Select an Image");
        if isequal(file, 0)
            return;
        end
        loadImage(fullfile(path, file));
    end

    % Slider
    function onSliderT1(~, event)
        val = round(event.Value);
        t1_slider.Value = val;
        t1_thresholdValue.Text = sprintf("%d / 255", val);
        updateBinary()
    end

    % Arrow Buttons
    function onUpT1(~, ~)
        val = min(255, round(t1_slider.Value) + 1);
        t1_slider.Value   = val;
        t1_thresholdValue.Text = sprintf('%d / 255', val);
        updateBinary();
    end

    function onDownT1(~, ~)
        val = max(0, round(t1_slider.Value) - 1);
        t1_slider.Value   = val;
        t1_thresholdValue.Text = sprintf('%d / 255', val);
        updateBinary();
    end

    % Auto (Otsu's Method)
    function onAutoT1(~,~)
        if isempty(img)
            uialert(appWindow, "Please Load an Image First.", "No Image Loaded");
            return;
        end
        level               = graythresh(imgGray);
        val                 = round(level * 255);
        t1_slider.Value   = val;
        t1_thresholdValue.Text = sprintf("%d / 255", val);
        updateBinary();
    end

    % Save
    function onSave(~,~)
        if isempty(imgGray)
            uialert(appWindow, "Please Load and Threshold an Image First", "Nothing to Save");
            return;
        end
        
        thresh = t1_slider.Value / 255;
        binImg = imgGray >= thresh; 
    
        [file, path] = uiputfile( ...
            {'*.png','PNG Image'; '*.bmp','Bitmap'; '*.tif','TIFF Image'; '*.mat','MATLAB Binary Array'}, ...
            "Save Binarised Image As");
        if isequal(file, 0), return; end
    
        fullpath  = fullfile(path, file);
        [~,~,ext] = fileparts(file);
    
        if strcmpi(ext, '.mat')
            save(fullpath, 'binImg');
        else
            imwrite(uint8(binImg * 255), fullpath);
        end
        uialert(appWindow, ['Saved to: ' fullpath], 'Saved', 'Icon', 'success');
    end

    % Store
    function onStoreT1(~,~)
        if isempty(imgGray)
            uialert(appWindow, "Please Load and Threshold an Image First", "Nothing to Save");
            return;
        end
        thresh = t1_slider.Value / 255;
        storedImage = imgGray >= thresh;

        uialert(appWindow, "Binarised Image Successfully Stored in Memory", "Stored", "Icon","success")
    end

    % Use Stored Image for Tab 2
    function onUseStoredT2(~,~)
        if isempty(storedImage)
            uialert(appWindow, "Please Store an Image.", "No Image");
            return;
        end
        binaryImgT2 = storedImage;
        processedImgT2 = storedImage;
        t2_imageSource.Text      = 'Source: Stored Image';
        t2_imageSource.FontColor = [0.15 0.15 0.15];
        
        t2_axInput.Visible = 'on';
        t2_axProcessed.Visible = 'on';
        imshow(binaryImgT2, 'Parent', t2_axInput);
        applyAxesStyle(t2_axInput);
        updateProcessedViewT2();

        linkaxes([t2_axInput, t2_axProcessed], 'xy');
        axtoolbar(t2_axInput,  {});
        axtoolbar(t2_axProcessed, {});
    end

    % Remove Small Objects
    function onRemoveSmallObjects(~,~)
        if isempty(processedImgT2), return; end
        minArea = t2_areaThreshSpinner.Value;
        processedImgT2 = bwareaopen(processedImgT2, minArea);
        updateProcessedViewT2();
    end

    % Store Tab 2
    function onStoreT2(~,~)
        if isempty(processedImgT2) | processedImgT2 == binaryImgT2 
            uialert(appWindow, "No Processed Image to Store", "Error", icon = "error")
        end
        storedImage = processedImgT2;
        uialert(appWindow, "Processed Image Stored Successfully", "Stored", Icon = "success")
    end

    % Tab 3 Fractal Analysis Function
    function onRunFractalAnalysis(~,~)
        if isempty(binaryImgT3)
            uialert(appWindow, "Please select a binary image first.", "No Image");
            return;
        end
        binImg = binaryImgT3;

        % ── boxcount ──────────────────────────────────────────────────────
        [n_box, r_box] = boxcount(binImg);
        valid_box      = n_box > 0;
        logR_box       = log(r_box(valid_box));
        logN_box       = log(n_box(valid_box));
        coeffs_box     = polyfit(logR_box, logN_box, 1);
        D_box          = -coeffs_box(1);
        fit_box        = polyval(coeffs_box, logR_box);

        cla(t3_axBoxcount);
        plot(t3_axBoxcount, logR_box, logN_box, 'bo', 'MarkerFaceColor', 'b', ...
            'DisplayName', 'Data');
        hold(t3_axBoxcount, 'on');
        plot(t3_axBoxcount, logR_box, fit_box, 'b-', 'LineWidth', 1.5, ...
            'DisplayName', sprintf('Fit  (D = %.4f)', D_box));
        hold(t3_axBoxcount, 'off');
        legend(t3_axBoxcount, 'Location', 'best');
        xlabel(t3_axBoxcount, 'log(box size)');
        ylabel(t3_axBoxcount, 'log(box count)');
        t3_boxcountResults.Text = sprintf('boxcount D:  %.4f', D_box);

        % ── hausDim ───────────────────────────────────────────────────────
        [D_haus, boxCounts, resolutions] = modHausDim(binImg);
        valid_haus  = boxCounts > 0;
        logR_haus   = log(1 ./ resolutions(valid_haus));
        logN_haus   = log(boxCounts(valid_haus));
        coeffs_haus = polyfit(logR_haus, logN_haus, 1);
        fit_haus    = polyval(coeffs_haus, logR_haus);

        cla(t3_axHausDim);
        plot(t3_axHausDim, logR_haus, logN_haus, 'rs', 'MarkerFaceColor', 'r', ...
            'DisplayName', 'Data');
        hold(t3_axHausDim, 'on');
        plot(t3_axHausDim, logR_haus, fit_haus, 'r-', 'LineWidth', 1.5, ...
            'DisplayName', sprintf('Fit  (D = %.4f)', D_haus));
        hold(t3_axHausDim, 'off');
        legend(t3_axHausDim, 'Location', 'best');
        xlabel(t3_axHausDim, 'log(box size)');
        ylabel(t3_axHausDim, 'log(box count)');
        t3_hausDimResults.Text = sprintf('hausDim D:  %.4f', D_haus);
    end
    
    % Load Binary Image For Tab 3
    function onLoadBinary(~,~)
        [file, path] = uigetfile( ...
            {'*.png;*.bmp;*.tif;*.tiff', 'Image Files'; ...
             '*.mat',                    'MATLAB Binary Array'}, ...
            'Select a Binary Image');
        if isequal(file, 0)
            return;
        end
        fullpath  = fullfile(path, file);
        [~,~,ext] = fileparts(file);
        if strcmpi(ext, '.mat')
            data          = load(fullpath);
            fields        = fieldnames(data);
            binaryImgT3   = logical(data.(fields{1}));
        else
            img = imread(fullpath);
            img = im2uint8(img);
            if size(img, 3) == 3
                img = rgb2gray(img);
            end
            binaryImgT3 = imbinarize(img);
        end
        [~, fname, fext]           = fileparts(file);
        t3_imageSource.Text      = ['Source: ' fname fext];
        t3_imageSource.FontColor = [0.15 0.15 0.15];
    end
    
    % Use Stored Image For Tab 3
    function onUseStoredT3(~,~)
        if isempty(storedImage)
            uialert(appWindow, "Please Store an Image.", "No Image");
            return;
        end
        binaryImgT3              = storedImage;
        t3_imageSource.Text      = 'Source: Stored Image';
        t3_imageSource.FontColor = [0.15 0.15 0.15];
    end

    % ~~~~~~~~~~~~~~~~
    % Helper Functions
    % ~~~~~~~~~~~~~~~~
    % In this case a helper function is a function which isn't a callback function
    
    function loadImage(filepath)
        t1_axOriginal.Visible  = 'on';
        t1_axBinarised.Visible = 'on';
        try
            img = imread(filepath);
        catch ME
            uialert(appWindow, ["Could Not Read File: " ME.message], "Load Error");
            return;
        end
        if size(img, 3) == 3
            imgGray = im2double(rgb2gray(img));
        elseif size(img, 3) == 1
            imgGray = im2double(img);
        else
            uialert(appWindow, 'Unsupported Image Format', "Load Error");
            return;
        end

        imshow(img, "Parent", t1_axOriginal);
        applyAxesStyle(t1_axOriginal);

        [~, fname, ext]        = fileparts(filepath);
        t1_fileNameText.Text      = [fname ext];
        t1_fileNameText.FontColor = [0.15 0.15 0.15];

        [h, w, ~]          = size(img);
        t1_resLabel.Text = sprintf('%d x %d px', w, h);

        level               = graythresh(imgGray);
        val                 = round(level * 255);
        t1_slider.Value   = val;
        t1_thresholdValue.Text = sprintf('%d / 255', val);
        updateBinary();
        updateHistogram()
        linkaxes([t1_axOriginal, t1_axBinarised], 'xy');
        axtoolbar(t1_axOriginal,  {});
        axtoolbar(t1_axBinarised, {});
    end

    function updateBinary()
        if isempty(img)
            return;
        end
        thresh      = t1_slider.Value / 255;
        imageCache = imgGray >= thresh;

        imshow(imageCache, 'Parent', t1_axBinarised);
        applyAxesStyle(t1_axBinarised);

        pctWhite        = 100 * sum(imageCache(:)) / numel(imageCache);
        t1_whiteLabel.Text = sprintf("White (foreground): %.1f%%", pctWhite);
        t1_blackLabel.Text = sprintf("Black (background): %.1f%%", 100 - pctWhite);
        updateHistogram()
    end

    function applyAxesStyle(ax)
        ax.XTick  = [];
        ax.YTick  = [];
        ax.Box    = "on";
        ax.XColor = [0.84 0.84 0.84];
        ax.YColor = [0.84 0.84 0.84];
        ax.Color  = [0.97 0.97 0.97];
    end

    function updateHistogram()
        if isempty(img)
            return;
        end

        cla(t1_axHist);
        histogram(t1_axHist, imgGray(:), 256, BinLimits = [0 1], FaceColor = [0.4 0.4 0.4], EdgeColor = "none", FaceAlpha = 0.7)
        
        thresh = t1_slider.Value / 255;
        hold(t1_axHist,"on");
        xline(t1_axHist, thresh, 'r-', 'LineWidth', 2, 'Label', sprintf('T = %d', t1_slider.Value), 'LabelVerticalAlignment', 'top');
        hold(t1_axHist, 'off');
        t1_axHist.Visible = 'on';
        t1_axHist.XLim    = [0 1];
        t1_axHist.XTick   = 0:0.25:1;
        t1_axHist.XTickLabel = {'0','64','128','192','255'};
        t1_axHist.Box     = 'on';
        t1_axHist.XColor  = [0.12 0.12 0.12];
        t1_axHist.YColor  = [0.12 0.12 0.12];
    end

    function updateProcessedViewT2()
        imshow(processedImgT2, 'Parent', t2_axProcessed);
        applyAxesStyle(t2_axProcessed);
    end
end