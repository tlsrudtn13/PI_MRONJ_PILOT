% =========================================================================
% PI-MRONJ DICOM crop tool (ver 1.8 - fixes the lost-object-handle bug)
% =========================================================================
clear; clc; close all;

% --- 1. Rectangular crop size ---
PATCH_W = 112; % width
PATCH_H = 224; % height
half_w = round(PATCH_W / 2);
half_h = round(PATCH_H / 2);

% --- 2. File selection ---
[file, path] = uigetfile('*.dcm', 'Select a DICOM file');
if isequal(file, 0), return; end
img_raw = dicomread(fullfile(path, file));
info    = dicominfo(fullfile(path, file));
raw_date = info.StudyDate;
[img_h, img_w] = size(img_raw);

% for display (contrast enhanced)
img_disp = imadjust(mat2gray(img_raw));

% --- 3. Build the main window ---
fig_main = figure('Name', [raw_date ' - click the crop location'], ...
                  'NumberTitle', 'off', 'WindowState', 'maximized', ...
                  'MenuBar', 'none', 'ToolBar', 'none', 'Pointer', 'cross');

% Key fix: create an explicit axes instead of using gca, and lock its handle.
ax_main = axes('Parent', fig_main);
imshow(img_disp, 'Parent', ax_main); 
hold(ax_main, 'on');

title(ax_main, {['Study date: ' raw_date]; 'Click the implant center to crop a 112x224 patch.'}, ...
      'FontSize', 14);

% create the red preview rectangle (forced to belong to ax_main)
h_rect = rectangle(ax_main, 'Position', [-1000, -1000, PATCH_W, PATCH_H], ...
                   'EdgeColor', 'r', 'LineWidth', 1.5, 'PickableParts', 'none');

% store all data safely on fig_main only.
setappdata(fig_main, 'ax_main', ax_main);
setappdata(fig_main, 'h_rect', h_rect);
setappdata(fig_main, 'half_w', half_w);
setappdata(fig_main, 'half_h', half_h);
setappdata(fig_main, 'patch_w', PATCH_W);
setappdata(fig_main, 'patch_h', PATCH_H);
setappdata(fig_main, 'img_w', img_w);
setappdata(fig_main, 'img_h', img_h);
setappdata(fig_main, 'img_raw', img_raw);
setappdata(fig_main, 'raw_date', raw_date);
setappdata(fig_main, 'path', path);

% attach mouse-event listeners
set(fig_main, 'WindowButtonMotionFcn', @hover_callback);
set(fig_main, 'WindowButtonDownFcn', @click_callback);

% wait
uiwait(fig_main);


% --- Callback 1: mouse motion (update the preview rectangle) ---
function hover_callback(src, ~)
    % never use gca; retrieve the safely-stored ax_main.
    ax = getappdata(src, 'ax_main');
    if isempty(ax) || ~isvalid(ax), return; end
    
    cp = get(ax, 'CurrentPoint');
    x = cp(1,1); y = cp(1,2);
    
    h_rect = getappdata(src, 'h_rect');
    hw     = getappdata(src, 'half_w');
    hh     = getappdata(src, 'half_h');
    pw     = getappdata(src, 'patch_w');
    ph     = getappdata(src, 'patch_h');
    w      = getappdata(src, 'img_w');
    h      = getappdata(src, 'img_h');

    % compute the top-left corner from the center point
    x_min = round(x) - hw;
    y_min = round(y) - hh;

    % clamp so the box stays within the image bounds
    if x_min < 1, x_min = 1; end
    if y_min < 1, y_min = 1; end
    if x_min + pw - 1 > w, x_min = w - pw + 1; end
    if y_min + ph - 1 > h, y_min = h - ph + 1; end

    % update the rectangle with a -0.5 offset to fix the visual pixel error
    if isvalid(h_rect)
        set(h_rect, 'Position', [x_min - 0.5, y_min - 0.5, pw, ph]);
    end
    
    % cache the actual pixel coordinates for the click
    setappdata(src, 'curr_rect', [x_min, y_min]);
end

% --- Callback 2: mouse click (perform the crop and save) ---
function click_callback(src, ~)
    curr_rect = getappdata(src, 'curr_rect');
    if isempty(curr_rect), return; end
    
    x_min = curr_rect(1);
    y_min = curr_rect(2);
    pw = getappdata(src, 'patch_w');
    ph = getappdata(src, 'patch_h');

    x_max = x_min + pw - 1;
    y_max = y_min + ph - 1;

    img_raw  = getappdata(src, 'img_raw');
    raw_date = getappdata(src, 'raw_date');
    path     = getappdata(src, 'path');

    % crop the image data
    cropped_raw = img_raw(y_min:y_max, x_min:x_max);

    % preview the result in a new window
    fig_preview = figure('Name', 'Crop preview', 'NumberTitle', 'off', 'Position', [500, 300, 300, 500]);
    imshow(imadjust(mat2gray(cropped_raw)));
    title('Cropped image', 'FontSize', 14);

    btn_choice = questdlg('Save the cropped image?', 'Confirm save', 'Save', 'Reselect', 'Save');
    
    % --- 'Reselect' or window close ---
    if isempty(btn_choice) || strcmp(btn_choice, 'Reselect')
        if ishandle(fig_preview), close(fig_preview); end
        
        % safeguard: force focus back to the main window and flush the event queue
        if ishandle(src)
            figure(src);
            drawnow; 
        end
        return;
    end

    % --- 'Save' ---
    if strcmp(btn_choice, 'Save')
        answer = inputdlg(['Filename suffix (after the date ' raw_date '):'], ...
                          'Enter info', [1 50], {'_i46'});
        if ~isempty(answer)
            final_name = [raw_date answer{1}];
            save_path  = fullfile(path, [final_name '.png']);

            % save as 16-bit PNG
            imwrite(uint16(cropped_raw), save_path);
            fprintf('[Done] Saved: %s.png\n', final_name);

            if ishandle(fig_preview), close(fig_preview); end

            % ask whether to continue
            cont = questdlg('Crop another patch from the same DICOM?', ...
                            'Continue', 'Yes', 'No (quit)', 'Yes');
                            
            if strcmp(cont, 'No (quit)') || isempty(cont)
                if ishandle(src), close(src); end 
            else
                % on 'Yes', re-activate the main window
                if ishandle(src)
                    figure(src);
                    drawnow;
                end
            end
        else
            % if the filename entry was cancelled
            if ishandle(fig_preview), close(fig_preview); end
            if ishandle(src)
                figure(src);
                drawnow;
            end
        end
    end
end