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
        % res(i) = biggest integer in (0, 256] s.t. map(res(i)) <= i
        % if no such integer exists, res(i) = 1
        function res = GetInverseHisteqMapping(comp, image)
            map = comp.GetHisteqMapping(image);
            [numColor, ~] = size(map);

            res = zeros([numColor, 256]);
            j = 2;
            for c = 1:numColor
                for i = 1:256
                    while j < 256 && map(c, j) <= i
                        j = j+1;
                    end
                    res(c, i) = j-1;
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
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: PilihFileCitraButton1
        function PilihFileCitraButton1Pushed(comp, event)
            % preventing main GUI from minimizing after uigetfile
            dummyWindow = figure('Renderer', 'painters', 'Position', [-100 -100 0 0]);

            [file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.tif;*.bmp'});
            if file ~= 0
                comp.NamaFileCitraLabel1.Text = strcat(path, file);
            end
            delete(dummyWindow);
        end

        % Button pushed function: PilihFileCitraButton3
        function PilihFileCitraButton3Pushed(comp, event)
            % preventing main GUI from minimizing after uigetfile
            dummyWindow = figure('Renderer', 'painters', 'Position', [-100 -100 0 0]);

            [file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.tif;*.bmp'});
            if file ~= 0
                comp.NamaFileCitraLabel3.Text = strcat(path, file);
            end
            delete(dummyWindow);
        end

        % Button pushed function: PilihFileCitraInputButton
        function PilihFileCitraInputButtonPushed(comp, event)
             % preventing main GUI from minimizing after uigetfile
            dummyWindow = figure('Renderer', 'painters', 'Position', [-100 -100 0 0]);

            [file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.tif;*.bmp'});
            if file ~= 0
                comp.NamaFileCitraInputLabel.Text = strcat(path, file);
            end
            delete(dummyWindow);
        end

        % Button pushed function: PilihFileCitraReferensiButton
        function PilihFileCitraReferensiButtonPushed(comp, event)
             % preventing main GUI from minimizing after uigetfile
            dummyWindow = figure('Renderer', 'painters', 'Position', [-100 -100 0 0]);

            [file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.tif;*.bmp'});
            if file ~= 0
                comp.NamaFileCitraReferensiLabel.Text = strcat(path, file);
            end
            delete(dummyWindow);
        end

        % Button pushed function: TampilkanHistogramButton
        function TampilkanHistogramButtonPushed(comp, event)
            try
                image = imread(comp.NamaFileCitraLabel1.Text);
                comp.ShowImageHistogram(image)
            catch e
                msgbox(e.message, "Error", "error");
            end
        end

        % Button pushed function: JalankanPerataanHistogramButton
        function JalankanPerataanHistogramButtonPushed(comp, event)
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
        function JalankanHistogramSpecificationButtonPushed(comp, event)
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
        end
    end
end