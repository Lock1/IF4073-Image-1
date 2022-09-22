classdef app_exported < matlab.ui.componentcontainer.ComponentContainer

    % Properties that correspond to underlying components
    properties (Access = private, Transient, NonCopyable)
        MainTab                        matlab.ui.container.TabGroup
        TampilanHistogramTab           matlab.ui.container.Tab
        TampilkanHistogramButton       matlab.ui.control.Button
        NamaFileCitraLabel1            matlab.ui.control.Label
        PilihFileCitraButton1          matlab.ui.control.Button
        PerbaikanKualitasTab           matlab.ui.container.Tab
        PerataanHistogramTab           matlab.ui.container.Tab
        JalankanPerataanHistogramButton  matlab.ui.control.Button
        NamaFileCitraLabel3            matlab.ui.control.Label
        PilihFileCitraButton3          matlab.ui.control.Button
        HistogramSpecificationTab      matlab.ui.container.Tab
        JalankanHistogramSpecificationButton  matlab.ui.control.Button
        NamaFileCitraReferensiLabel    matlab.ui.control.Label
        NamaFileCitraInputLabel        matlab.ui.control.Label
        PilihFileCitraReferensiButton  matlab.ui.control.Button
        PilihFileCitraInputButton      matlab.ui.control.Button
        ContraststretchingButton   matlab.ui.control.Button
        nthtransformButton         matlab.ui.control.Button
        LogtransformButton         matlab.ui.control.Button
        ImagebrighteningButton     matlab.ui.control.Button
        brgammaSpinner             matlab.ui.control.Spinner
        brgammaSpinnerLabel        matlab.ui.control.Label
        acSpinner                  matlab.ui.control.Spinner
        acSpinnerLabel             matlab.ui.control.Label
        ParameterLabel             matlab.ui.control.Label
        JudulCitraLabel2           matlab.ui.control.Label
        PilihFileCitraButton2      matlab.ui.control.Button
    end

    
    methods (Access = public)
        
        % Returns frequency array of intensity values in range [0, 256)
        function res = GetFrequency(~, image)
            [numRow, numColumn, numColor] = size(image);
            res = zeros([numColor, 256]);
            for c = 1:numColor
                for i = 1:numRow
                    for j = 1:numColumn
                        pixelValue = image(i, j, c) + 1; % +1 because arrays are one-indexed
                        res(c, pixelValue) = res(c, pixelValue) + 1;
                    end
                end
            end
        end
        
        % Shows color histogram of an image
        function ShowImageHistogram(comp, image)
            freq = comp.GetFrequency(image);
            [numColor, ~] = size(freq);

            if numColor == 1 % grayscale
                figure("Name", "Histogram")
                bar(0:1:255, freq);
            else % RGB
                figure("Name", "Histogram Red")
                bar(0:1:255, freq(1, :),"red");
                figure("Name", "Histogram Blue")
                bar(0:1:255, freq(2, :), "blue");
                figure("Name", "Histogram Green")
                bar(0:1:255, freq(3, :), "green");
            end
        end
        
        % Returns histogram equalization result, in float
        function res = GetHisteqMapping(comp, image)
            [numRow, numColumn, numColor] = size(image);
            freq = comp.GetFrequency(image);
            
            res = zeros([numColor, 256]);
            for c = 1:numColor
                for i = 1:256
                    res(c, i) = freq(c, i) ./ (numRow*numColumn) * 256;
                    if i > 1
                        res(c, i) = res(c, i) + res(c, i-1);
                    end
                end
            end
        end
        
        % Returns inverse histogram equalization result, in uint8
        % res(i) = an integer in (0, 256] s.t. |map(res(i)) - i| is minimum
        % if multiple possibility exists, minimum value is taken
        function res = GetInverseHisteqMapping(comp, image)
            map = comp.GetHisteqMapping(image);
            [numColor, ~] = size(map);

            res = zeros([numColor, 256]);
            for c = 1:numColor
                for i = 1:256
                    dist = 300;
                    for j = 1:256
                        if abs(map(c, j) - i) < dist
                            res(c, i) = j;
                            dist = abs(map(c, j) - i);
                        end
                    end
                end
            end
        end
        
        % Applies color mapping map to image
        function res = ApplyMapping(~, image, map)
            map = round(map); % Round map to integer before applying

            [numRow, numColumn, numColor] = size(image);
            res = zeros([numRow, numColumn, numColor]);            
            for i = 1:numRow
                for j = 1:numColumn
                    for c = 1:numColor
                        res(i, j, c) = map(c, image(i, j, c)+1) - 1; % -1 because map values are in (0, 256]
                    end
                end
            end

            res = uint8(res);
        end

        % Image Brightening
        function res = ImageBrightening(~, image, a, b)
            [numRow, numColumn, numColor] = size(image);
            res = zeros([numRow, numColumn, numColor]);
            for i = 1:numRow
                for j = 1:numColumn
                    for c = 1:numColor
                        % Clamp [0, 256)
                        res(i, j, c) = image(i, j, c) * a + b;
                        res(i, j, c) = max(0, min(255, res(i, j, c)));
                    end
                end
            end

            res = uint8(res);
        end

        % Log transform
        function res = ImageLogTransform(~, image, cr)
            [numRow, numColumn, numColor] = size(image);
            res = zeros([numRow, numColumn, numColor]);
            for i = 1:numRow
                for j = 1:numColumn
                    for c = 1:numColor
                        % Clamp [0, 256)
                        res(i, j, c) = round(cr * log10(1 + double(image(i, j, c))));
                        res(i, j, c) = max(0, min(255, res(i, j, c)));
                    end
                end
            end

            res = uint8(res);
        end

        % Nth transform
        function res = ImageNthTransform(~, image, cr, gamma)
            [numRow, numColumn, numColor] = size(image);
            res = zeros([numRow, numColumn, numColor]);
            for i = 1:numRow
                for j = 1:numColumn
                    for c = 1:numColor
                        % Clamp [0, 256), normed with 8-bit depth in mind
                        res(i, j, c) = cr * power(double(image(i, j, c))/255, gamma)*255;
                        res(i, j, c) = max(0, min(255, res(i, j, c)));
                    end
                end
            end

            res = uint8(res);
        end

        % Contrast stretching
        function res = ImageContrastStretching(~, image)
            [numRow, numColumn, numColor] = size(image);
            res = zeros([numRow, numColumn, numColor]);
            rmin = [255, 255, 255];
            rmax = [0, 0, 0];
  
            for i = 1:numRow
                for j = 1:numColumn
                    for c = 1:numColor
                        if (rmax(c) < image(i, j, c))
                            rmax(c) = image(i, j, c);
                        end

                        if (rmin(c) > image(i, j, c))
                            rmin(c) = image(i, j, c);
                        end
                    end
                end
            end

            for i = 1:numRow
                for j = 1:numColumn
                    for c = 1:numColor
                        % Clamp [0, 256)
                        res(i, j, c) = (image(i, j, c) - rmin(c))*(255/(rmax(c)-rmin(c)));
                        res(i, j, c) = max(0, min(255, res(i, j, c)));
                    end
                end
            end

            res = uint8(res);
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: PilihFileCitraButton1
        function PilihFileCitraButton1Pushed(comp, ~)
            % preventing main GUI from minimizing after uigetfile
            dummyWindow = figure('Renderer', 'painters', 'Position', [-100 -100 0 0]);

            [file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.tif;*.bmp'});
            if file ~= 0
                comp.NamaFileCitraLabel1.Text = strcat(path, file);
            end
            delete(dummyWindow);
        end

        % Button pushed function: PilihFileCitraButton2
        function PilihFileCitraButton2Pushed(comp, ~)
            % preventing main GUI from minimizing after uigetfile
            dummyWindow = figure('Renderer', 'painters', 'Position', [-100 -100 0 0]);

            [file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.tif;*.bmp'});
            if file ~= 0
                comp.JudulCitraLabel2.Text = strcat(path, file);
            end
            delete(dummyWindow);
        end

        % Button pushed function: PilihFileCitraButton3
        function PilihFileCitraButton3Pushed(comp, ~)
            % preventing main GUI from minimizing after uigetfile
            dummyWindow = figure('Renderer', 'painters', 'Position', [-100 -100 0 0]);

            [file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.tif;*.bmp'});
            if file ~= 0
                comp.NamaFileCitraLabel3.Text = strcat(path, file);
            end
            delete(dummyWindow);
        end

        % Button pushed function: PilihFileCitraInputButton
        function PilihFileCitraInputButtonPushed(comp, ~)
             % preventing main GUI from minimizing after uigetfile
            dummyWindow = figure('Renderer', 'painters', 'Position', [-100 -100 0 0]);

            [file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.tif;*.bmp'});
            if file ~= 0
                comp.NamaFileCitraInputLabel.Text = strcat(path, file);
            end
            delete(dummyWindow);
        end

        % Button pushed function: PilihFileCitraReferensiButton
        function PilihFileCitraReferensiButtonPushed(comp, ~)
             % preventing main GUI from minimizing after uigetfile
            dummyWindow = figure('Renderer', 'painters', 'Position', [-100 -100 0 0]);

            [file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.tif;*.bmp'});
            if file ~= 0
                comp.NamaFileCitraReferensiLabel.Text = strcat(path, file);
            end
            delete(dummyWindow);
        end

        % Button pushed function: TampilkanHistogramButton
        function TampilkanHistogramButtonPushed(comp, ~)
            try
                image = imread(comp.NamaFileCitraLabel1.Text);
                comp.ShowImageHistogram(image)
            catch e
                msgbox(e.message, "Error", "error");
            end
        end

        % Button pushed function: JalankanPerataanHistogramButton
        function JalankanPerataanHistogramButtonPushed(comp, ~)
            try
                image = imread(comp.NamaFileCitraLabel3.Text);

                % Show initial image
                figure("Name", "Citra Input")
                imshow(image);
                % Show initial histogram
                comp.ShowImageHistogram(image);
                % Show histogram equalization result image
                map = comp.GetHisteqMapping(image);
                res = comp.ApplyMapping(image, map);
                figure("Name", "Citra Hasil")
                imshow(res);
                % Show histogram equalization result histogram
                comp.ShowImageHistogram(res)
            catch e
                msgbox(e.message, "Error", "error");
            end
        end

        % Button pushed function: JalankanHistogramSpecificationButton
        function JalankanHistogramSpecificationButtonPushed(comp, ~)
            try
                image = imread(comp.NamaFileCitraInputLabel.Text);
                reference = imread(comp.NamaFileCitraReferensiLabel.Text);
                
                [~, ~, numColor1] = size(image);
                [~, ~, numColor2] = size(reference);
                if numColor1 ~= numColor2
                    throw(MException("histogramSpecification:inputError", ...
                        "Mode warna dua citra tidak sama"))
                end

                % Show initial image
                figure("Name", "Citra Input")
                imshow(image);
                % Show initial histogram
                comp.ShowImageHistogram(image);

                % Show reference image
                figure("Name", "Citra Referensi")
                imshow(reference);
                % Show reference histogram
                comp.ShowImageHistogram(reference);

                % Apply histogram specification
                map1 = comp.GetHisteqMapping(image);
                map2 = comp.GetInverseHisteqMapping(reference);
                res = comp.ApplyMapping(image, map1);
                res = comp.ApplyMapping(res, map2);

                % Show histogram specification result image
                figure("Name", "Citra Hasil")
                imshow(res);
                % Show histogram specification result histogram
                comp.ShowImageHistogram(res)
            catch e
                msgbox(e.message, "Error", "error");
            end
        end

        % Button pushed function: ImagebrighteningButton
        function JalankanImageBrightening(comp, ~)
            try
                image = imread(comp.JudulCitraLabel2.Text);

                % Initial image
                figure("Name", "Citra Input")
                imshow(image);

                % Image brightening
                res = comp.ImageBrightening(image, comp.acSpinner.Value, comp.brgammaSpinner.Value);
                figure("Name", "Citra Hasil")
                imshow(res);
            catch e
                msgbox(e.message, "Error", "error");
            end
        end

        % Button pushed function: LogtransformButton
        function JalankanLogTransform(comp, ~)
            try
                image = imread(comp.JudulCitraLabel2.Text);

                % Initial image
                figure("Name", "Citra Input")
                imshow(image);

                % Image brightening
                res = comp.ImageLogTransform(image, comp.acSpinner.Value);
                figure("Name", "Citra Hasil")
                imshow(res);
            catch e
                msgbox(e.message, "Error", "error");
            end
        end

        % Button pushed function: nthtransformButton
        function JalankanNthtransform(comp, ~)
            try
                image = imread(comp.JudulCitraLabel2.Text);

                % Initial image
                figure("Name", "Citra Input")
                imshow(image);

                % Image brightening
                res = comp.ImageNthTransform(image, comp.acSpinner.Value, comp.brgammaSpinner.Value);
                figure("Name", "Citra Hasil")
                imshow(res);
            catch e
                msgbox(e.message, "Error", "error");
            end
        end

        % Button pushed function: ContraststretchingButton
        function JalankanContrastStrecthing(comp, ~)
            try
                image = imread(comp.JudulCitraLabel2.Text);

                % Initial image
                figure("Name", "Citra Input")
                imshow(image);

                % Image brightening
                res = comp.ImageContrastStretching(image);
                figure("Name", "Citra Hasil")
                imshow(res);
            catch e
                msgbox(e.message, "Error", "error");
            end
        end
    end

    methods (Access = protected)
        
        % Code that executes when the value of a public property is changed
        function update(comp)
            % Use this function to update the underlying components
            
        end

        % Create the underlying components
        function setup(comp)

            comp.Position = [1 1 657 461];
            comp.BackgroundColor = [0.94 0.94 0.94];

            % Create MainTab
            comp.MainTab = uitabgroup(comp);
            comp.MainTab.Position = [1 0 657 462];

            % Create TampilanHistogramTab
            comp.TampilanHistogramTab = uitab(comp.MainTab);
            comp.TampilanHistogramTab.Title = 'Tampilan Histogram';

            % Create PilihFileCitraButton1
            comp.PilihFileCitraButton1 = uibutton(comp.TampilanHistogramTab, 'push');
            comp.PilihFileCitraButton1.ButtonPushedFcn = matlab.apps.createCallbackFcn(comp, @PilihFileCitraButton1Pushed, true);
            comp.PilihFileCitraButton1.Position = [281 295 100 22];
            comp.PilihFileCitraButton1.Text = 'Pilih File Citra';

            % Create NamaFileCitraLabel1
            comp.NamaFileCitraLabel1 = uilabel(comp.TampilanHistogramTab);
            comp.NamaFileCitraLabel1.HorizontalAlignment = 'center';
            comp.NamaFileCitraLabel1.Position = [189 263 281 22];
            comp.NamaFileCitraLabel1.Text = 'Nama File Citra';

            % Create TampilkanHistogramButton
            comp.TampilkanHistogramButton = uibutton(comp.TampilanHistogramTab, 'push');
            comp.TampilkanHistogramButton.ButtonPushedFcn = matlab.apps.createCallbackFcn(comp, @TampilkanHistogramButtonPushed, true);
            comp.TampilkanHistogramButton.Position = [266 174 128 22];
            comp.TampilkanHistogramButton.Text = 'Tampilkan Histogram';

            % Create PerbaikanKualitasTab
            comp.PerbaikanKualitasTab = uitab(comp.MainTab);
            comp.PerbaikanKualitasTab.Title = 'Perbaikan Kualitas';

            % Create PerataanHistogramTab
            comp.PerataanHistogramTab = uitab(comp.MainTab);
            comp.PerataanHistogramTab.Title = 'Perataan Histogram';

            % Create PilihFileCitraButton3
            comp.PilihFileCitraButton3 = uibutton(comp.PerataanHistogramTab, 'push');
            comp.PilihFileCitraButton3.ButtonPushedFcn = matlab.apps.createCallbackFcn(comp, @PilihFileCitraButton3Pushed, true);
            comp.PilihFileCitraButton3.Position = [281 295 100 22];
            comp.PilihFileCitraButton3.Text = 'Pilih File Citra';

            % Create NamaFileCitraLabel3
            comp.NamaFileCitraLabel3 = uilabel(comp.PerataanHistogramTab);
            comp.NamaFileCitraLabel3.HorizontalAlignment = 'center';
            comp.NamaFileCitraLabel3.Position = [183 263 293 22];
            comp.NamaFileCitraLabel3.Text = 'Nama File Citra';

            % Create JalankanPerataanHistogramButton
            comp.JalankanPerataanHistogramButton = uibutton(comp.PerataanHistogramTab, 'push');
            comp.JalankanPerataanHistogramButton.ButtonPushedFcn = matlab.apps.createCallbackFcn(comp, @JalankanPerataanHistogramButtonPushed, true);
            comp.JalankanPerataanHistogramButton.Position = [243 174 174 22];
            comp.JalankanPerataanHistogramButton.Text = 'Jalankan Perataan Histogram';

            % Create HistogramSpecificationTab
            comp.HistogramSpecificationTab = uitab(comp.MainTab);
            comp.HistogramSpecificationTab.Title = 'Histogram Specification';

            % Create PilihFileCitraInputButton
            comp.PilihFileCitraInputButton = uibutton(comp.HistogramSpecificationTab, 'push');
            comp.PilihFileCitraInputButton.ButtonPushedFcn = matlab.apps.createCallbackFcn(comp, @PilihFileCitraInputButtonPushed, true);
            comp.PilihFileCitraInputButton.Position = [125 295 120 22];
            comp.PilihFileCitraInputButton.Text = 'Pilih File Citra Input';

            % Create PilihFileCitraReferensiButton
            comp.PilihFileCitraReferensiButton = uibutton(comp.HistogramSpecificationTab, 'push');
            comp.PilihFileCitraReferensiButton.ButtonPushedFcn = matlab.apps.createCallbackFcn(comp, @PilihFileCitraReferensiButtonPushed, true);
            comp.PilihFileCitraReferensiButton.Position = [405 295 144 22];
            comp.PilihFileCitraReferensiButton.Text = 'Pilih File Citra Referensi';

            % Create NamaFileCitraInputLabel
            comp.NamaFileCitraInputLabel = uilabel(comp.HistogramSpecificationTab);
            comp.NamaFileCitraInputLabel.HorizontalAlignment = 'center';
            comp.NamaFileCitraInputLabel.Position = [90 263 192 22];
            comp.NamaFileCitraInputLabel.Text = 'Nama File Citra Input';

            % Create NamaFileCitraReferensiLabel
            comp.NamaFileCitraReferensiLabel = uilabel(comp.HistogramSpecificationTab);
            comp.NamaFileCitraReferensiLabel.HorizontalAlignment = 'center';
            comp.NamaFileCitraReferensiLabel.Position = [380 263 196 22];
            comp.NamaFileCitraReferensiLabel.Text = 'Nama File Citra Referensi';

            % Create JalankanHistogramSpecificationButton
            comp.JalankanHistogramSpecificationButton = uibutton(comp.HistogramSpecificationTab, 'push');
            comp.JalankanHistogramSpecificationButton.ButtonPushedFcn = matlab.apps.createCallbackFcn(comp, @JalankanHistogramSpecificationButtonPushed, true);
            comp.JalankanHistogramSpecificationButton.Position = [231 174 203 22];
            comp.JalankanHistogramSpecificationButton.Text = 'Jalankan Histogram Specification';

            % Create PilihFileCitraButton2
            comp.PilihFileCitraButton2 = uibutton(comp.PerbaikanKualitasTab, 'push');
            comp.PilihFileCitraButton2.ButtonPushedFcn = matlab.apps.createCallbackFcn(comp, @PilihFileCitraButton2Pushed, true);
            comp.PilihFileCitraButton2.Position = [56 337 100 23];
            comp.PilihFileCitraButton2.Text = 'Pilih File Citra';

            % Create JudulCitraLabel2
            comp.JudulCitraLabel2 = uilabel(comp.PerbaikanKualitasTab);
            comp.JudulCitraLabel2.Position = [60 367 422 22];
            comp.JudulCitraLabel2.Text = 'Judul Citra';

            % Create ParameterLabel
            comp.ParameterLabel = uilabel(comp.PerbaikanKualitasTab);
            comp.ParameterLabel.Position = [60 295 61 22];
            comp.ParameterLabel.Text = 'Parameter';

            % Create acSpinnerLabel
            comp.acSpinnerLabel = uilabel(comp.PerbaikanKualitasTab);
            comp.acSpinnerLabel.HorizontalAlignment = 'right';
            comp.acSpinnerLabel.Position = [81 263 25 22];
            comp.acSpinnerLabel.Text = 'a, c';

            % Create acSpinner
            comp.acSpinner = uispinner(comp.PerbaikanKualitasTab);
            comp.acSpinner.Position = [121 263 100 22];

            % Create brgammaSpinnerLabel
            comp.brgammaSpinnerLabel = uilabel(comp.PerbaikanKualitasTab);
            comp.brgammaSpinnerLabel.HorizontalAlignment = 'right';
            comp.brgammaSpinnerLabel.Position = [37 232 68 22];
            comp.brgammaSpinnerLabel.Text = 'b, r, gamma';

            % Create brgammaSpinner
            comp.brgammaSpinner = uispinner(comp.PerbaikanKualitasTab);
            comp.brgammaSpinner.Position = [121 232 100 22];

            % Create ImagebrighteningButton
            comp.ImagebrighteningButton = uibutton(comp.PerbaikanKualitasTab, 'push');
            comp.ImagebrighteningButton.ButtonPushedFcn = matlab.apps.createCallbackFcn(comp, @JalankanImageBrightening, true);
            comp.ImagebrighteningButton.Position = [83 177 111 23];
            comp.ImagebrighteningButton.Text = 'Image brightening';

            % Create LogtransformButton
            comp.LogtransformButton = uibutton(comp.PerbaikanKualitasTab, 'push');
            comp.LogtransformButton.ButtonPushedFcn = matlab.apps.createCallbackFcn(comp, @JalankanLogTransform, true);
            comp.LogtransformButton.Position = [89 147 100 23];
            comp.LogtransformButton.Text = 'Log transform';

            % Create nthtransformButton
            comp.nthtransformButton = uibutton(comp.PerbaikanKualitasTab, 'push');
            comp.nthtransformButton.ButtonPushedFcn = matlab.apps.createCallbackFcn(comp, @JalankanNthtransform, true);
            comp.nthtransformButton.Position = [89 114 100 23];
            comp.nthtransformButton.Text = 'n-th transform';

            % Create ContraststretchingButton
            comp.ContraststretchingButton = uibutton(comp.PerbaikanKualitasTab, 'push');
            comp.ContraststretchingButton.ButtonPushedFcn = matlab.apps.createCallbackFcn(comp, @JalankanContrastStrecthing, true);
            comp.ContraststretchingButton.Position = [81 83 116 23];
            comp.ContraststretchingButton.Text = 'Contrast stretching';
        end
    end
end