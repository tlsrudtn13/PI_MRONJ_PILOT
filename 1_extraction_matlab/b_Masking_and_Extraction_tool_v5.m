% =========================================================
% PI-MRONJ Radiomics Photoshop Edition V28 (Seamless Focus & Config)
% 1. [improved] Patient-ID parent-folder parsing verified and confirmed
% 2. [bugfix] Lasso/eraser tools: continuous multi-image focusing and dragging fully implemented (margin bug fixed)
% 3. [bugfix] Clicking another tool/UI while a tool is active now cancels/switches immediately (escapes the infinite loop)
% 4. [feature] Project save extension factored into a global variable for easy customization
% =========================================================
clear; clc; close all;
%% -- Global configuration ------------------------------------------------
PROJECT_EXT = '.pmrx'; % 💡 project save/load file extension (change as desired)

% 1. Automatically resolve the absolute path of the folder containing this script.
current_dir = fileparts(mfilename('fullpath')); 

% 2. Set IN_DIR/OUT_DIR to the current folder location.
DEFAULT_IN_DIR  = current_dir;        
DEFAULT_OUT_DIR = current_dir;

NBINS = 32; 
METAL_TOP_PCT = 90.0;

%% -- Build the interactive GUI ----------
fig = figure('Name', 'PI-MRONJ Photoshop V28 (Seamless Focus & Config)', 'Position', [50, 50, 1600, 950], 'MenuBar', 'none', 'NumberTitle', 'off');
panel_ctrl = uipanel('Parent', fig, 'Position', [0, 0, 1, 0.22], 'BackgroundColor', [0.88 0.88 0.88]);
panel_img = uipanel('Parent', fig, 'Position', [0, 0.22, 1, 0.78], 'BackgroundColor', [0.95 0.95 0.95], 'Scrollable', 'on');
ax = gobjects(10, 1); h_img = gobjects(10, 1); h_title = gobjects(10, 1);
w = 0.18; h_ax = 0.43; x_pos = [0.02, 0.21, 0.40, 0.59, 0.78]; y_pos = [0.52, 0.04]; 
for r = 1:2
    for c = 1:5
        k = (r-1)*5 + c; ax(k) = axes('Parent', panel_img, 'Position', [x_pos(c), y_pos(r), w, h_ax]);
        h_img(k) = imshow(zeros(224, 112), 'Parent', ax(k));
        set(ax(k), 'Box', 'on', 'XColor', [0.8 0.8 0.8], 'YColor', [0.8 0.8 0.8], 'LineWidth', 2, 'XTick', [], 'YTick', []);
        h_title(k) = title(ax(k), '이미지를 로드해주세요', 'Interpreter', 'none', 'FontSize', 9);
    end
end

% default values requested by the user
INIT_LOW_OFF = -0.36; INIT_HIGH_OFF = 0.00; INIT_DIL = 4; INIT_CLIP_LOW = 1.0; INIT_CLIP_HIGH = 86.0;

% -- Left controls --
txt_lbl_target = uicontrol('Parent', panel_ctrl, 'Style', 'text', 'String', '🎯 조절 대상:', 'Position', [10, 165, 95, 20], 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [0.88 0.88 0.88], 'ForegroundColor', 'b');
popup_target = uicontrol('Parent', panel_ctrl, 'Style', 'popupmenu', 'String', {'[Global]'}, 'Position', [105, 165, 230, 25], 'FontSize', 10, 'FontWeight', 'bold');
txt_lbl_clip_low = uicontrol('Parent', panel_ctrl, 'Style', 'text', 'String', '하위 클립(%):', 'Position', [10, 130, 85, 20], 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [0.88 0.88 0.88], 'ForegroundColor', 'b');
edit_clip_low = uicontrol('Parent', panel_ctrl, 'Style', 'edit', 'String', num2str(INIT_CLIP_LOW), 'Position', [95, 130, 40, 25], 'FontWeight', 'bold');
txt_lbl_clip_high = uicontrol('Parent', panel_ctrl, 'Style', 'text', 'String', '상위 클립(%):', 'Position', [145, 130, 85, 20], 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [0.88 0.88 0.88], 'ForegroundColor', 'r');
edit_clip_high = uicontrol('Parent', panel_ctrl, 'Style', 'edit', 'String', num2str(INIT_CLIP_HIGH), 'Position', [230, 130, 40, 25], 'FontWeight', 'bold');
btn_apply_clip = uicontrol('Parent', panel_ctrl, 'Style', 'pushbutton', 'String', '🔄 적용', 'Position', [280, 128, 60, 30], 'FontWeight', 'bold', 'BackgroundColor', [0.9 0.9 1]);
txt_lbl_low = uicontrol('Parent', panel_ctrl, 'Style', 'text', 'String', '파란색(공기):', 'Position', [10, 95, 90, 20], 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [0.88 0.88 0.88], 'ForegroundColor', [0 0 0.7]);
txt_low = uicontrol('Parent', panel_ctrl, 'Style', 'text', 'String', sprintf('%.2f', INIT_LOW_OFF), 'Position', [100, 95, 40, 20], 'FontSize', 10, 'FontWeight', 'bold');
slider_low = uicontrol('Parent', panel_ctrl, 'Style', 'slider', 'Position', [145, 95, 155, 20], 'Min', -0.60, 'Max', 0.20, 'Value', INIT_LOW_OFF, 'SliderStep', [0.01, 0.05]);
btn_drop_air = uicontrol('Parent', panel_ctrl, 'Style', 'pushbutton', 'String', '🧪', 'Position', [305, 92, 30, 26], 'FontSize', 14, 'FontWeight', 'bold', 'BackgroundColor', [0.8 0.9 1]);
txt_lbl_high = uicontrol('Parent', panel_ctrl, 'Style', 'text', 'String', '빨간색(금속):', 'Position', [10, 60, 90, 20], 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [0.88 0.88 0.88], 'ForegroundColor', [0.7 0 0]);
txt_high = uicontrol('Parent', panel_ctrl, 'Style', 'text', 'String', sprintf('%.2f', INIT_HIGH_OFF), 'Position', [100, 60, 40, 20], 'FontSize', 10, 'FontWeight', 'bold');
slider_high = uicontrol('Parent', panel_ctrl, 'Style', 'slider', 'Position', [145, 60, 155, 20], 'Min', -0.60, 'Max', 0.40, 'Value', INIT_HIGH_OFF, 'SliderStep', [0.01, 0.05]);
btn_drop_metal = uicontrol('Parent', panel_ctrl, 'Style', 'pushbutton', 'String', '💉', 'Position', [305, 57, 30, 26], 'FontSize', 14, 'FontWeight', 'bold', 'BackgroundColor', [1 0.8 0.8]);
txt_lbl_dil = uicontrol('Parent', panel_ctrl, 'Style', 'text', 'String', '팽창 두께:', 'Position', [10, 25, 90, 20], 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [0.88 0.88 0.88]);
txt_dil = uicontrol('Parent', panel_ctrl, 'Style', 'text', 'String', sprintf('%d px', INIT_DIL), 'Position', [100, 25, 40, 20], 'FontSize', 10, 'FontWeight', 'bold', 'ForegroundColor', 'r');
slider_dil = uicontrol('Parent', panel_ctrl, 'Style', 'slider', 'Position', [145, 25, 190, 20], 'Min', 0, 'Max', 10, 'Value', INIT_DIL, 'SliderStep', [1/10, 2/10]);

% -- Center: toolbox --
txt_status = uicontrol('Parent', panel_ctrl, 'Style', 'text', 'String', '안내: 원하시는 툴을 선택하세요.', 'Position', [360, 165, 450, 20], 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [0.88 0.88 0.88], 'ForegroundColor', [0 0.5 0], 'HorizontalAlignment', 'left');
btn_bucket = uicontrol('Parent', panel_ctrl, 'Style', 'pushbutton', 'String', '🪣 페인트통', 'Position', [360, 115, 110, 40], 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [1 1 0.8]);
btn_magic = uicontrol('Parent', panel_ctrl, 'Style', 'pushbutton', 'String', '🪄 매직완드', 'Position', [480, 115, 110, 40], 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [1 0.8 1]);
btn_reset = uicontrol('Parent', panel_ctrl, 'Style', 'pushbutton', 'String', '🗑️ 초기화', 'Position', [600, 115, 110, 40], 'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', [0.9 0.8 0.8]);
btn_brush = uicontrol('Parent', panel_ctrl, 'Style', 'pushbutton', 'String', '🖌️ 올가미', 'Position', [360, 65, 110, 40], 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [0.8 1 0.8]);
btn_eraser = uicontrol('Parent', panel_ctrl, 'Style', 'pushbutton', 'String', '🧽 지우개', 'Position', [480, 65, 110, 40], 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [0.8 0.9 1]);
btn_undo = uicontrol('Parent', panel_ctrl, 'Style', 'pushbutton', 'String', '↩️ 실행취소', 'Position', [600, 65, 110, 40], 'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', [0.9 0.9 0.9]);
txt_lbl_brush = uicontrol('Parent', panel_ctrl, 'Style', 'text', 'String', '브러쉬 두께:', 'Position', [360, 30, 90, 20], 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [0.88 0.88 0.88]);
txt_brush_size = uicontrol('Parent', panel_ctrl, 'Style', 'text', 'String', '3 px', 'Position', [450, 30, 40, 20], 'FontSize', 10, 'FontWeight', 'bold', 'ForegroundColor', [0 0.5 0]);
slider_brush = uicontrol('Parent', panel_ctrl, 'Style', 'slider', 'Position', [495, 30, 215, 20], 'Min', 0, 'Max', 20, 'Value', 3, 'SliderStep', [1/20, 5/20]);

% -- Right: controls, paths, extraction, AI, save --
btn_prev = uicontrol('Parent', panel_ctrl, 'Style', 'pushbutton', 'String', '◀ 이전 10개', 'Position', [730, 30, 80, 85], 'FontSize', 10, 'FontWeight', 'bold');
btn_next = uicontrol('Parent', panel_ctrl, 'Style', 'pushbutton', 'String', '▶ 다음 10개', 'Position', [820, 30, 80, 85], 'FontSize', 10, 'FontWeight', 'bold');
txt_lbl_in = uicontrol('Parent', panel_ctrl, 'Style', 'text', 'String', '입력:', 'Position', [920, 135, 40, 20], 'FontWeight', 'bold', 'BackgroundColor', [0.88 0.88 0.88]);
edit_in = uicontrol('Parent', panel_ctrl, 'Style', 'edit', 'String', DEFAULT_IN_DIR, 'Position', [960, 135, 320, 25], 'HorizontalAlignment', 'left');
btn_in = uicontrol('Parent', panel_ctrl, 'Style', 'pushbutton', 'String', '📂', 'Position', [1290, 135, 35, 25], 'FontWeight', 'bold', 'Tooltip', '입력 폴더 찾기');
btn_load = uicontrol('Parent', panel_ctrl, 'Style', 'pushbutton', 'String', '🔄 로드', 'Position', [1335, 135, 60, 25], 'FontWeight', 'bold', 'BackgroundColor', [0.8 1 0.8]);
txt_lbl_out = uicontrol('Parent', panel_ctrl, 'Style', 'text', 'String', '출력:', 'Position', [920, 100, 40, 20], 'FontWeight', 'bold', 'BackgroundColor', [0.88 0.88 0.88]);
edit_out = uicontrol('Parent', panel_ctrl, 'Style', 'edit', 'String', DEFAULT_OUT_DIR, 'Position', [960, 100, 320, 25], 'HorizontalAlignment', 'left');
btn_out = uicontrol('Parent', panel_ctrl, 'Style', 'pushbutton', 'String', '📂', 'Position', [1290, 100, 35, 25], 'FontWeight', 'bold', 'Tooltip', '출력 폴더 찾기');
btn_run  = uicontrol('Parent', panel_ctrl, 'Style', 'pushbutton', 'String', '📊 라디오믹스 추출', 'Position', [920, 20, 180, 70], 'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', [0.7 1.0 0.75], 'ForegroundColor', [0 0.4 0], 'Enable', 'off');
btn_export_ai = uicontrol('Parent', panel_ctrl, 'Style', 'pushbutton', 'String', '🤖 AI 마스크셋 내보내기', 'Position', [1110, 20, 180, 70], 'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', [0.9 0.8 1.0], 'ForegroundColor', [0.4 0 0.6], 'Enable', 'off');
btn_save_mask = uicontrol('Parent', panel_ctrl, 'Style', 'pushbutton', 'String', sprintf('💾 프로젝트 저장 (%s)', PROJECT_EXT), 'Position', [1300, 58, 160, 32], 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [1 0.9 0.6]);
btn_load_mask = uicontrol('Parent', panel_ctrl, 'Style', 'pushbutton', 'String', sprintf('📂 프로젝트 열기 (%s)', PROJECT_EXT), 'Position', [1300, 20, 160, 32], 'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', [0.8 0.9 1]);
txt_lbl_lang = uicontrol('Parent', panel_ctrl, 'Style', 'text', 'String', '🌐 Lang:', 'Position', [1480, 135, 60, 20], 'FontWeight', 'bold', 'BackgroundColor', [0.88 0.88 0.88]);
popup_lang = uicontrol('Parent', panel_ctrl, 'Style', 'popupmenu', 'String', {'한국어', 'English'}, 'Position', [1480, 110, 90, 25], 'FontWeight', 'bold');

h = struct(); h.PROJECT_EXT = PROJECT_EXT; h.popup_target = popup_target; h.slider_low = slider_low; h.slider_high = slider_high; h.slider_dil = slider_dil; h.slider_brush = slider_brush;
h.txt_low = txt_low; h.txt_high = txt_high; h.txt_dil = txt_dil; h.txt_status = txt_status; h.txt_brush = txt_brush_size; h.btn_run = btn_run; h.btn_prev = btn_prev; h.btn_next = btn_next;
h.btn_bucket = btn_bucket; h.btn_brush = btn_brush; h.btn_eraser = btn_eraser; h.btn_undo = btn_undo; h.btn_reset = btn_reset; h.btn_magic = btn_magic; h.btn_apply_clip = btn_apply_clip;
h.txt_lbl_target = txt_lbl_target; h.txt_lbl_clip_low = txt_lbl_clip_low; h.txt_lbl_clip_high = txt_lbl_clip_high; h.txt_lbl_low = txt_lbl_low; h.txt_lbl_high = txt_lbl_high; h.txt_lbl_dil = txt_lbl_dil; h.txt_lbl_brush = txt_lbl_brush; h.popup_lang = popup_lang;
h.edit_clip_low = edit_clip_low; h.edit_clip_high = edit_clip_high; h.btn_drop_air = btn_drop_air; h.btn_drop_metal = btn_drop_metal; 
h.txt_lbl_in = txt_lbl_in; h.txt_lbl_out = txt_lbl_out; h.edit_in = edit_in; h.edit_out = edit_out; h.btn_in = btn_in; h.btn_out = btn_out; h.btn_load = btn_load;
h.btn_save_mask = btn_save_mask; h.btn_load_mask = btn_load_mask; h.btn_export_ai = btn_export_ai; 
h.ax = ax; h.h_img = h_img; h.h_title = h_title; h.extraction_started = false; h.N = 0; h.flags = struct();
h.NBINS = NBINS; h.g_low = INIT_LOW_OFF; h.g_high = INIT_HIGH_OFF; h.g_dil = INIT_DIL; h.g_clip_low = INIT_CLIP_LOW; h.g_clip_high = INIT_CLIP_HIGH;
guidata(fig, h);

% connect callbacks
set(popup_target, 'Callback', @(~,~) popup_callback(fig)); set(popup_lang, 'Callback', @(~,~) apply_language(fig)); set(btn_apply_clip, 'Callback', @(~,~) apply_clip_callback(fig)); 
set(slider_low,  'Callback', @(~,~) slider_callback(fig)); set(slider_high, 'Callback', @(~,~) slider_callback(fig)); set(slider_dil,  'Callback', @(~,~) slider_callback(fig)); set(slider_brush, 'Callback', @(~,~) set(txt_brush_size, 'String', sprintf('%d px', round(get(slider_brush, 'Value')))));
set(btn_bucket, 'Callback', @(~,~) tool_callback(fig, 'bucket')); set(btn_brush, 'Callback', @(~,~) tool_callback(fig, 'brush')); set(btn_eraser, 'Callback', @(~,~) tool_callback(fig, 'eraser')); set(btn_reset, 'Callback', @(~,~) tool_callback(fig, 'reset')); set(btn_magic, 'Callback', @(~,~) tool_callback(fig, 'magic')); set(btn_undo, 'Callback', @(~,~) undo_callback(fig));
set(btn_next, 'Callback', @(~,~) turn_page(fig, +1)); set(btn_prev, 'Callback', @(~,~) turn_page(fig, -1)); set(btn_run,  'Callback', @(~,~) run_extraction_callback(fig));
set(btn_export_ai, 'Callback', @(~,~) export_ai_masks_callback(fig)); 
set(btn_drop_air, 'Callback', @(~,~) dropper_logic(fig, 'air')); set(btn_drop_metal, 'Callback', @(~,~) dropper_logic(fig, 'metal'));
set(btn_in, 'Callback', @(~,~) select_folder_callback(fig, 'in')); set(btn_out, 'Callback', @(~,~) select_folder_callback(fig, 'out')); set(btn_load, 'Callback', @(~,~) load_images_callback(fig));
set(btn_save_mask, 'Callback', @(~,~) save_masks_callback(fig)); set(btn_load_mask, 'Callback', @(~,~) load_masks_callback(fig));
apply_language(fig);
load_images_callback(fig);
while isvalid(fig)
    uiwait(fig);
end
disp('프로그램이 종료되었습니다. (Program terminated.)');
%% ════════════════════════════════════════════════════════
%%  Batch export of the AI training dataset
%% ════════════════════════════════════════════════════════
function export_ai_masks_callback(fig)
    if ~isvalid(fig), return; end
    h = guidata(fig); if h.N == 0, return; end
    out_dir = get(h.edit_out, 'String');
    lang = get(h.popup_lang, 'Value');
    
    export_base = uigetdir(out_dir, 'AI 학습용 데이터셋(PNG+CSV)을 저장할 폴더를 선택하세요 (Select a folder to save the AI training dataset (PNG+CSV))');
    if isequal(export_base, 0), return; end
    
    img_dir = fullfile(export_base, 'images'); mask_dir = fullfile(export_base, 'masks');
    if ~exist(img_dir, 'dir'), mkdir(img_dir); end; if ~exist(mask_dir, 'dir'), mkdir(mask_dir); end
    
    if lang == 1, msg = 'AI 학습용 마스크 데이터셋 생성 중...'; else, msg = 'Exporting AI Dataset...'; end
    h_wait = waitbar(0, msg, 'Name', 'AI Export', 'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
    setappdata(h_wait, 'canceling', 0);
    
    csv_data = cell(h.N, 4); csv_header = {'ID', 'Original_File', 'Image_Path', 'Mask_Path'};
    
    try
        for k=1:h.N
            if ~ishandle(h_wait) || getappdata(h_wait, 'canceling'), break; end
            if lang == 1, waitbar(k/h.N, h_wait, sprintf('저장 중... (%d/%d)', k, h.N)); else, waitbar(k/h.N, h_wait, sprintf('Exporting... (%d/%d)', k, h.N)); end
            
            fname = h.ALL_NAMES{k};
            img_norm = h.ALL_NORMS{k}; c_low = h.c_low(k); if isnan(c_low), c_low = h.g_low; end; c_high = h.c_high(k); if isnan(c_high), c_high = h.g_high; end; c_dil = h.c_dil(k); if isnan(c_dil), c_dil = h.g_dil; end 
            clip_low = prctile(img_norm(:),h.g_clip_low); clip_high = prctile(img_norm(:),h.g_clip_high); im_k = img_norm; im_k(im_k<clip_low)=clip_low; im_k(im_k>clip_high)=clip_high; 
            
            try [~,Centers] = imsegkmeans(single(im_k),3); Centers=sort(Centers); 
                th_a=(Centers(1)+Centers(2))/2; th_m=(Centers(2)+Centers(3))/2; 
                air_mask=im_k<(th_a+c_low); met_raw=im_k>(th_m+c_high); 
                met_extra=im_k>=(Centers(3) - 0.3*(Centers(3)-Centers(2))); met_combined=met_raw|met_extra;
                if c_dil>0, metal_mask=imdilate(met_combined,strel('disk',c_dil)); else, metal_mask=met_combined; end 
                metal_mask=(metal_mask|h.MANUAL_ADD{k})&~h.MANUAL_SUB{k}; bone_mask=~(air_mask|metal_mask); 
            catch, bone_mask = false(size(img_norm)); 
            end
            
            base_name = sprintf('img_%04d', k); img_file = [base_name, '_orig.png']; mask_file = [base_name, '_mask.png'];
            imwrite(uint8(img_norm * 255), fullfile(img_dir, img_file)); imwrite(bone_mask, fullfile(mask_dir, mask_file));
            
            csv_data{k,1} = base_name; csv_data{k,2} = fname; csv_data{k,3} = ['images/', img_file]; csv_data{k,4} = ['masks/', mask_file];
        end
        if ishandle(h_wait), delete(h_wait); end
        
        T_csv = cell2table(csv_data, 'VariableNames', csv_header);
        writetable(T_csv, fullfile(export_base, 'dataset_catalog.csv'), 'Encoding', 'UTF-8');
        
        if lang==1, msgbox('AI 학습용 데이터셋 추출이 완료되었습니다!', '내보내기 완료', 'help'); else, msgbox('AI Dataset export complete!', 'Export Complete', 'help'); end
    catch ME
        if ishandle(h_wait), delete(h_wait); end
        errordlg(['오류 발생 (Error): ', ME.message], 'Export Error');
    end
end
%% -- Workspace save & load functions (linked to the extension global) --
function save_masks_callback(fig)
    if ~isvalid(fig), return; end
    h = guidata(fig); if h.N == 0, return; end
    out_dir = get(h.edit_out, 'String'); if ~exist(out_dir, 'dir'), mkdir(out_dir); end
    
    ext = h.PROJECT_EXT;
    desc = sprintf('PI-MRONJ Project File (*%s)', ext);
    def_name = sprintf('My_PI_MRONJ_Workspace%s', ext);
    
    [file, path] = uiputfile({['*', ext], desc}, '마스킹 작업내역 저장 (Save masking workspace)', fullfile(out_dir, def_name));
    if isequal(file, 0), return; end; save_path = fullfile(path, file);
    
    MANUAL_ADD = h.MANUAL_ADD; MANUAL_SUB = h.MANUAL_SUB; c_low = h.c_low; c_high = h.c_high; c_dil = h.c_dil; ALL_NAMES = h.ALL_NAMES;
    set(fig, 'Pointer', 'watch'); drawnow; save(save_path, 'MANUAL_ADD', 'MANUAL_SUB', 'c_low', 'c_high', 'c_dil', 'ALL_NAMES', '-v7'); set(fig, 'Pointer', 'arrow');
    
    lang = get(h.popup_lang, 'Value');
    if lang == 1, msgbox(sprintf('압축된 프로젝트 파일이 저장되었습니다.\n▶ %s', file), '저장 완료', 'help'); else, msgbox('Compressed project file saved successfully.', 'Save Complete', 'help'); end
end
function load_masks_callback(fig)
    if ~isvalid(fig), return; end
    h = guidata(fig); if h.N == 0, return; end
    out_dir = get(h.edit_out, 'String'); lang = get(h.popup_lang, 'Value');
    
    ext = h.PROJECT_EXT;
    desc = sprintf('PI-MRONJ Project File (*%s)', ext);
    
    [file, path] = uigetfile({['*', ext], desc; '*.mat', 'Legacy MATLAB File (*.mat)'}, '저장된 프로젝트 파일 선택 (Select a saved project file)', out_dir);
    if isequal(file, 0), return; end; save_path = fullfile(path, file);
    
    try
        tmp = load(save_path, '-mat'); 
        if isequal(tmp.ALL_NAMES, h.ALL_NAMES)
            h.MANUAL_ADD = tmp.MANUAL_ADD; h.MANUAL_SUB = tmp.MANUAL_SUB; h.c_low = tmp.c_low; h.c_high = tmp.c_high; h.c_dil = tmp.c_dil;
            guidata(fig, h); update_preview(fig);
            if lang == 1, msgbox('마스킹 작업 내역을 복구했습니다!', '불러오기 완료', 'help'); else, msgbox('Workspace has been loaded!', 'Load Complete', 'help'); end
        else
            if lang == 1, errordlg('현재 로드된 이미지 목록과 프로젝트 파일의 이미지가 다릅니다.', '불일치 오류'); else, errordlg('Image sets do not match.', 'Mismatch Error'); end
        end
    catch
        if lang == 1, errordlg('파일을 읽을 수 없거나 손상된 프로젝트 파일입니다.', '오류'); else, errordlg('Invalid or corrupted project file.', 'Error'); end
    end
end
%% ════════════════════════════════════════════════════════
%%  Background extraction function
%% ════════════════════════════════════════════════════════
function execute_extraction(fig, flags, nbins)
    h = guidata(fig); lang = get(h.popup_lang, 'Value');
    
    if lang == 1, msg = '데이터 추출 중... 잠시만 기다려주세요.'; else, msg = 'Extracting Data... Please wait.'; end
    h_wait = waitbar(0, msg, 'Name', 'Radiomics Extraction', 'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
    setappdata(h_wait, 'canceling', 0);
    
    feat_names_FO={'FO_Mean','FO_Std','FO_Skewness','FO_Kurtosis','FO_Entropy','FO_Energy','FO_P10','FO_P25','FO_Median','FO_P75','FO_P90','FO_IQR','FO_Range','FO_MAD','FO_Variance','FO_CV','FO_RMS','FO_Uniformity'};
    feat_names_GLCM={'GLCM_Contrast','GLCM_Homogeneity','GLCM_Energy','GLCM_Correlation','GLCM_Entropy','GLCM_IDM','GLCM_ClusterShade','GLCM_ClusterProminence','GLCM_SumAverage','GLCM_SumEntropy','GLCM_DiffVariance','GLCM_DiffEntropy','GLCM_Dissimilarity'};
    feat_names_GLRLM={'GLRLM_SRE','GLRLM_LRE','GLRLM_GLN','GLRLM_RLN','GLRLM_RP','GLRLM_SRHGE','GLRLM_LRHGE','GLRLM_SRLGE','GLRLM_LRLGE','GLRLM_RLNU'};
    feat_names_GLSZM={'GLSZM_SAE','GLSZM_LAE','GLSZM_GLNU','GLSZM_ZP','GLSZM_LGZE','GLSZM_HGZE','GLSZM_ZNU'};
    feat_names_NGTDM={'NGTDM_Coarseness','NGTDM_Contrast','NGTDM_Busyness','NGTDM_Complexity','NGTDM_Strength'};
    feat_names_Shape={'Shape_Area','Shape_Perimeter','Shape_MajorAxis','Shape_MinorAxis','Shape_Eccentricity','Shape_EquivDiameter'};
    wav_bands={'Wav_LL_','Wav_LH_','Wav_HL_','Wav_HH_'}; feat_names_WAV=cell(1,18*4); idx=1; for b=1:4, for f=1:18, feat_names_WAV{idx}=[wav_bands{b},feat_names_FO{f}]; idx=idx+1; end, end
    all_feat_names = {};
    if flags.fo, all_feat_names = [all_feat_names, feat_names_FO]; end
    if flags.glcm, all_feat_names = [all_feat_names, feat_names_GLCM]; end
    if flags.glrlm, all_feat_names = [all_feat_names, feat_names_GLRLM]; end
    if flags.glszm, all_feat_names = [all_feat_names, feat_names_GLSZM]; end
    if flags.ngtdm, all_feat_names = [all_feat_names, feat_names_NGTDM]; end
    if flags.shape, all_feat_names = [all_feat_names, feat_names_Shape]; end
    if flags.wav, all_feat_names = [all_feat_names, feat_names_WAV]; end
    N_FEATS = length(all_feat_names);
    FEAT_MAT = NaN(h.N, N_FEATS); PatientID = cell(h.N,1); ImplantID = cell(h.N,1); StudyDate = cell(h.N,1); ValidPixels = zeros(h.N,1); 
    fprintf('\n=== 추출 시작 (Extraction started) ===\n');
    
    try
        for k=1:h.N
            if ~ishandle(h_wait) || getappdata(h_wait, 'canceling'), fprintf('추출이 취소되었습니다. (Extraction cancelled.)\n'); break; end
            if lang == 1, waitbar(k/h.N, h_wait, sprintf('이미지 분석 중... (%d/%d)', k, h.N)); else, waitbar(k/h.N, h_wait, sprintf('Analyzing... (%d/%d)', k, h.N)); end
            
            fname = h.ALL_NAMES{k};
            
            % patient-folder parsing logic
            folder_parts = strsplit(h.ALL_FOLDERS{k}, filesep);
            pt_id = '';
            for fp = length(folder_parts):-1:1
                if ~isempty(regexp(folder_parts{fp}, '^PT\d+', 'once'))
                    pt_id = folder_parts{fp}; break;
                end
            end
            if isempty(pt_id), pt_id = folder_parts{end}; end
            PatientID{k} = pt_id;
            
            [~,basename,~]=fileparts(fname); parts=strsplit(basename,'_');
            if length(parts)>=2, StudyDate{k}=parts{1}; ImplantID{k}=parts{2}; else, StudyDate{k}='Unknown'; ImplantID{k}='Unknown'; end
            
            img_norm=h.ALL_NORMS{k}; c_low=h.c_low(k); if isnan(c_low), c_low=h.g_low; end; c_high=h.c_high(k); if isnan(c_high), c_high=h.g_high; end; c_dil=h.c_dil(k); if isnan(c_dil), c_dil=h.g_dil; end 
            clip_val_low=prctile(img_norm(:),h.g_clip_low); clip_val_high=prctile(img_norm(:),h.g_clip_high); im_k=img_norm; im_k(im_k<clip_val_low)=clip_val_low; im_k(im_k>clip_val_high)=clip_val_high; 
            
            try [~,Centers]=imsegkmeans(single(im_k),3); catch, continue; end; Centers=sort(Centers); 
            th_air=(Centers(1)+Centers(2))/2; th_metal=(Centers(2)+Centers(3))/2; 
            air_mask=im_k<(th_air+c_low); met_raw=im_k>(th_metal+c_high); 
            met_extra = im_k >= (Centers(3) - 0.3*(Centers(3)-Centers(2))); met_combined = met_raw | met_extra;
            
            if c_dil>0, metal_mask=imdilate(met_combined,strel('disk',c_dil)); else, metal_mask=met_combined; end 
            metal_mask=(metal_mask|h.MANUAL_ADD{k})&~h.MANUAL_SUB{k}; bone_mask=~(air_mask|metal_mask); 
            ValidPixels(k)=sum(bone_mask(:)); 
            
            if ValidPixels(k) < 500
                fprintf('⚠️ Image %d (%s) 건너뜀 (skipped): 뼈 픽셀 수(%d)가 500개 미만입니다 (bone pixel count < 500).\n', k, fname, ValidPixels(k)); continue; 
            end   
            
            try
                row_feat = NaN(1, N_FEATS); c_idx = 1;
                if flags.fo, f = feat_FirstOrder(img_norm, bone_mask, nbins); row_feat(c_idx : c_idx + length(f) - 1) = f; c_idx = c_idx + length(f); end
                if flags.glcm, f = feat_GLCM_IBSI(img_norm, bone_mask, nbins); row_feat(c_idx : c_idx + length(f) - 1) = f; c_idx = c_idx + length(f); end
                if flags.glrlm, f = feat_GLRLM(img_norm, bone_mask, nbins); row_feat(c_idx : c_idx + length(f) - 1) = f; c_idx = c_idx + length(f); end
                if flags.glszm, f = feat_GLSZM(img_norm, bone_mask, nbins); row_feat(c_idx : c_idx + length(f) - 1) = f; c_idx = c_idx + length(f); end
                if flags.ngtdm, f = feat_NGTDM(img_norm, bone_mask, nbins); row_feat(c_idx : c_idx + length(f) - 1) = f; c_idx = c_idx + length(f); end
                if flags.shape, f = feat_Shape(bone_mask); row_feat(c_idx : c_idx + length(f) - 1) = f; c_idx = c_idx + length(f); end
                if flags.wav, f = feat_Wavelet(img_norm, bone_mask, nbins); row_feat(c_idx : c_idx + length(f) - 1) = f; end
                FEAT_MAT(k,:) = row_feat;
            catch ME
                fprintf('❌ Image %d (%s) 추출 실패 (extraction failed): %s\n', k, fname, ME.message); continue; 
            end
        end
        
        if ishandle(h_wait), delete(h_wait); end 
        
        T=array2table(FEAT_MAT,'VariableNames',all_feat_names); T=addvars(T,PatientID,ImplantID,StudyDate,ValidPixels,'Before',all_feat_names{1},'NewVariableNames',{'Patient_ID','Implant_ID','Study_Date','Valid_Pixels'});
        final_out_dir = get(h.edit_out, 'String'); if ~exist(final_out_dir, 'dir'), mkdir(final_out_dir); end
        
        save(fullfile(final_out_dir,'Radiomics_v37_Final_Results.mat'),'FEAT_MAT','all_feat_names','T','-v7.3'); 
        writetable(T,fullfile(final_out_dir,'Radiomics_v37_Final_Results.xlsx')); 
        fprintf('=== 추출 및 저장 완료 (Extraction & save complete) ===\n');
        
        if lang==1, msgbox('데이터가 성공적으로 추출/저장되었습니다!', '추출 완료', 'help'); else, msgbox('Data successfully extracted and saved!', 'Extraction Complete', 'help'); end
    catch ME
        if ishandle(h_wait), delete(h_wait); end
        errordlg(['추출 중 시스템 오류 발생 (System error during extraction): ', ME.message], '오류 (Error)');
    end
end
%% -- IBSI-compliant feature-extraction functions --
function feat = feat_GLCM_IBSI(img, mask, nbins); img_q = uint8(min(round(img * (nbins-1)) + 1, nbins)); img_q(~mask) = 0; offsets  = [0,1; -1,1; -1,0; -1,-1]; n_dir = size(offsets, 1); feat_sum = zeros(1, 13); for d = 1:n_dir, glcm_raw = double(graycomatrix(img_q, 'Offset', offsets(d,:), 'NumLevels', nbins + 1, 'GrayLimits', [0, nbins], 'Symmetric', true)); glcm = glcm_raw(2:end, 2:end); s = sum(glcm(:)); if s == 0, continue; end; glcm = glcm / s; [I, J] = meshgrid(1:nbins, 1:nbins); I = I'; J = J'; px = sum(glcm, 2); py = sum(glcm, 1)'; mu_x = sum((1:nbins)' .* px); mu_y = sum((1:nbins)' .* py); sg_x = sqrt(sum(((1:nbins)' - mu_x).^2 .* px) + eps); sg_y = sqrt(sum(((1:nbins)' - mu_y).^2 .* py) + eps); pxy_sum = zeros(2*nbins, 1); pxy_dif = zeros(nbins, 1); for ii = 1:nbins, for jj = 1:nbins, pxy_sum(ii+jj) = pxy_sum(ii+jj) + glcm(ii,jj); pxy_dif(abs(ii-jj)+1) = pxy_dif(abs(ii-jj)+1) + glcm(ii,jj); end; end; p_nz = glcm(glcm > 0); feat_sum = feat_sum + [ sum(sum((I-J).^2 .* glcm)), sum(sum(glcm ./ (1+(I-J).^2))), sum(sum(glcm.^2)), sum(sum((I-mu_x).*(J-mu_y).*glcm)) / (sg_x*sg_y), -sum(p_nz .* log2(p_nz)), sum(sum(glcm ./ (1+(I-J).^2/nbins^2))), sum(sum(((I+J-mu_x-mu_y).^3) .* glcm)), sum(sum(((I+J-mu_x-mu_y).^4) .* glcm)), sum((2:2*nbins)' .* pxy_sum(2:end)), -sum(pxy_sum(pxy_sum>0) .* log2(pxy_sum(pxy_sum>0))), sum((0:nbins-1)'.^2 .* pxy_dif), -sum(pxy_dif(pxy_dif>0) .* log2(pxy_dif(pxy_dif>0))), sum(sum(abs(I-J) .* glcm)) ]; end; feat = feat_sum / n_dir; end
function feat = feat_NGTDM(img, mask, nbins); img_q = double(min(round(img*(nbins-1))+1, nbins)); img_q(~mask) = 0; n_vox = sum(mask(:)); if n_vox == 0, feat = zeros(1,5); return; end; A = zeros(nbins,1); N_cnt = zeros(nbins,1); [R, C] = find(mask); for k = 1:length(R), r = R(k); c = C(k); gl = img_q(r,c); r1 = max(1,r-1); r2 = min(size(img_q,1),r+1); c1 = max(1,c-1); c2 = min(size(img_q,2),c+1); nb = img_q(r1:r2, c1:c2); m_nb = mask(r1:r2,  c1:c2); center_r = r - r1 + 1; center_c = c - c1 + 1; m_nb(center_r, center_c) = false; nb_val = nb(m_nb); if isempty(nb_val), continue; end; A(gl) = A(gl) + abs(gl - mean(nb_val)); N_cnt(gl) = N_cnt(gl) + 1; end; s_total = sum(N_cnt); if s_total == 0, feat = zeros(1,5); return; end; p = N_cnt / s_total; valid = p > 0; p_nz = p(valid); p_nz = p_nz(:); A_nz = A(valid); A_nz = A_nz(:); gl_nz = find(valid); gl_nz = gl_nz(:); coarseness = 1 / (sum(p_nz .* A_nz) + eps); [Pi, Pj] = meshgrid(p_nz, p_nz); [Gi, Gj] = meshgrid(gl_nz, gl_nz); contrast = (1/(n_vox^2 + eps)) * sum(sum(Pi .* Pj .* (Gi - Gj).^2)) * sum(A_nz); busyness = sum(p_nz .* A_nz) / (sum(sum(abs(Pi .* Gi - Pj .* Gj))) + eps); [Ai, Aj] = meshgrid(A_nz, A_nz); complexity = sum(sum(abs(Gi - Gj) ./ (Pi + Pj + eps) .* (Pi.*Ai + Pj.*Aj))) / (n_vox + eps); strength = sum(sum((Pi + Pj) .* (Gi - Gj).^2)) / (sum(A_nz) + eps); feat = [coarseness, contrast, busyness, complexity, strength]; end
function feat=feat_FirstOrder(img,mask,nbins); vals=img(mask); if numel(vals)<10, feat=zeros(1,18); return; end; vmin=min(vals); vmax=max(vals); bw=(vmax-vmin)/nbins; bw(bw==0)=1; disc=min(floor((vals-vmin)/bw)+1,nbins); h_cnt=histcounts(disc,1:nbins+1); p=h_cnt/sum(h_cnt); p_nz=p(p>0); m_val=mean(vals); feat=[m_val,std(vals),skewness(vals),kurtosis(vals),-sum(p_nz.*log2(p_nz)),sum(p.^2),prctile(vals,10),prctile(vals,25),median(vals),prctile(vals,75),prctile(vals,90),prctile(vals,75)-prctile(vals,25),max(vals)-min(vals),mean(abs(vals-m_val)),var(vals),std(vals)/(m_val+eps),sqrt(mean(vals.^2)),sum(h_cnt.^2)/sum(h_cnt)^2]; end
function feat=feat_GLRLM(img,mask,nbins); img_q=round(img*(nbins-1))+1; img_q(~mask)=0; [rows,cols]=size(img_q); dirs=[0,1;1,1;1,0;1,-1]; max_run=max(rows,cols); feat_sum=zeros(1,10); n_vox=sum(mask(:)); for d=1:4; dr=dirs(d,1); dc=dirs(d,2); glrlm=zeros(nbins,max_run); for r=1:rows; for c=1:cols; gl=img_q(r,c); if gl==0,continue; end; pr=r-dr; pc=c-dc; if pr>=1&&pr<=rows&&pc>=1&&pc<=cols&&img_q(pr,pc)==gl,continue; end; rl=1; nr=r+dr; nc=c+dc; while nr>=1&&nr<=rows&&nc>=1&&nc<=cols&&img_q(nr,nc)==gl, rl=rl+1; nr=nr+dr; nc=nc+dc; end; if gl<=nbins&&rl<=max_run, glrlm(gl,rl)=glrlm(gl,rl)+1; end; end; end; glrlm=glrlm(:,any(glrlm,1)); if isempty(glrlm),continue; end; n_runs=sum(glrlm(:)); if n_runs==0,continue; end; [~,n_rl]=size(glrlm); rl_j=1:n_rl; p_rl=sum(glrlm,1)'; feat_sum=feat_sum+[sum(sum(glrlm./(ones(nbins,1)*rl_j.^2)))/n_runs,sum(sum(glrlm.*(ones(nbins,1)*rl_j.^2)))/n_runs,sum(sum(glrlm,2).^2)/n_runs,sum(p_rl.^2)/n_runs,n_runs/n_vox,sum(sum(((1:nbins)'.^2*ones(1,n_rl)).*glrlm./(ones(nbins,1)*rl_j.^2)))/n_runs,sum(sum(((1:nbins)'.^2*ones(1,n_rl)).*glrlm.*(ones(nbins,1)*rl_j.^2)))/n_runs,sum(sum(glrlm./((1:nbins)'.^2*ones(1,n_rl))./(ones(nbins,1)*rl_j.^2)))/n_runs,sum(sum(glrlm.*(ones(nbins,1)*rl_j.^2)./((1:nbins)'.^2*ones(1,n_rl))))/n_runs,sum(p_rl.^2)/n_runs]; end; feat=feat_sum/4; end
function feat=feat_GLSZM(img,mask,nbins); img_q=round(img*(nbins-1))+1; img_q(~mask)=0; n_vox=sum(mask(:)); if n_vox==0,feat=zeros(1,7);return; end; glszm=zeros(nbins,n_vox); visited=false(size(img_q)); [nrows,ncols]=size(img_q); dR=[-1,-1,-1,0,0,1,1,1]; dC=[-1,0,1,-1,1,-1,0,1]; Q_r=zeros(n_vox,1); Q_c=zeros(n_vox,1); for r=1:nrows; for c=1:ncols; gl=img_q(r,c); if gl==0||visited(r,c),continue; end; q_head=1; q_tail=1; Q_r(1)=r; Q_c(1)=c; visited(r,c)=true; sz=0; while q_head<=q_tail; cr=Q_r(q_head); cc=Q_c(q_head); q_head=q_head+1; sz=sz+1; for dd=1:8; nr=cr+dR(dd); nc=cc+dC(dd); if nr>=1&&nr<=nrows&&nc>=1&&nc<=ncols&&~visited(nr,nc)&&img_q(nr,nc)==gl, visited(nr,nc)=true; q_tail=q_tail+1; Q_r(q_tail)=nr; Q_c(q_tail)=nc; end; end; end; if gl<=nbins&&sz>=1, glszm(gl,sz)=glszm(gl,sz)+1; end; end; end; glszm=glszm(:,any(glszm,1)); if isempty(glszm),feat=zeros(1,7);return; end; n_zones=sum(glszm(:)); if n_zones==0,feat=zeros(1,7);return; end; [n_gl,n_sz]=size(glszm); gl_i=(1:n_gl)'; sz_j=1:n_sz; p_sz=sum(glszm,1)'; feat=[sum(sum(glszm./(ones(n_gl,1)*sz_j.^2)))/n_zones,sum(sum(glszm.*(ones(n_gl,1)*sz_j.^2)))/n_zones,sum(sum(glszm,2).^2)/n_zones,n_zones/n_vox,sum(sum(glszm./(gl_i.^2*ones(1,n_sz))))/n_zones,sum(sum(glszm.*(gl_i.^2*ones(1,n_sz))))/n_zones,sum(p_sz.^2)/n_zones]; end
function feat=feat_Shape(mask); if sum(mask(:))==0, feat=zeros(1,6); return; end; st = regionprops(mask, 'Area', 'Perimeter', 'MajorAxisLength', 'MinorAxisLength', 'Eccentricity', 'EquivDiameter'); if isempty(st), feat=zeros(1,6); return; end; feat = [st(1).Area, st(1).Perimeter, st(1).MajorAxisLength, st(1).MinorAxisLength, st(1).Eccentricity, st(1).EquivDiameter]; end

function feat = feat_Wavelet(img, mask, nbins)

    % === Ensure reproducibility: require dwt2 ===
    if exist('dwt2','file') ~= 2
        error('Wavelet Toolbox function dwt2 is required to reproduce the published WavLH/WavHL features.');
    end

    % === Wavelet decomposition (MATLAB convention) ===
    [LL, cH, cV, HH] = dwt2(img, 'haar');

    % === Assign implementation labels ===
    LH = cH;   % WavLH → MATLAB horizontal-detail (cH)
    HL = cV;   % WavHL → MATLAB vertical-detail (cV)

    % === Resize mask ===
    mask_LL = logical(imresize(mask, size(LL), 'nearest'));
    mask_LH = logical(imresize(mask, size(LH), 'nearest'));
    mask_HL = logical(imresize(mask, size(HL), 'nearest'));
    mask_HH = logical(imresize(mask, size(HH), 'nearest'));

    % === Feature extraction ===
    feat = [
        feat_FirstOrder(LL, mask_LL, nbins), ...
        feat_FirstOrder(LH, mask_LH, nbins), ...
        feat_FirstOrder(HL, mask_HL, nbins), ...
        feat_FirstOrder(HH, mask_HH, nbins)
    ];

end

%% ════════════════════════════════════════════════════════
%%  UI callback functions (event-driven seamless-focus structure)
%% ════════════════════════════════════════════════════════
function select_folder_callback(fig, type_str)
    if ~isvalid(fig), return; end
    h = guidata(fig); if strcmp(type_str, 'in'), default_path = get(h.edit_in, 'String'); else, default_path = get(h.edit_out, 'String'); end
    sel_path = uigetdir(default_path, '폴더를 선택하세요 (Select a folder)');
    if sel_path ~= 0
        if strcmp(type_str, 'in'), set(h.edit_in, 'String', sel_path); load_images_callback(fig); else, set(h.edit_out, 'String', sel_path); end
    end
end
function load_images_callback(fig)
    if ~isvalid(fig), return; end
    h = guidata(fig); in_dir = get(h.edit_in, 'String'); files = dir(fullfile(in_dir, '**', '*.png')); N = length(files); lang = get(h.popup_lang, 'Value');
    if N == 0
        if lang==1, set(h.btn_run, 'String', '데이터 없음', 'Enable', 'off'); else, set(h.btn_run, 'String', 'No Data', 'Enable', 'off'); end
        h.N = 0; guidata(fig, h); for i=1:10, set(h.h_img(i), 'CData', zeros(224,112)); if lang==1, set(h.h_title(i), 'String', '파일 없음', 'Visible', 'on'); else, set(h.h_title(i), 'String', 'No File', 'Visible', 'on'); end; end
        return;
    end
    h.N = N; h.ALL_NORMS = cell(N, 1); h.ALL_NAMES = cell(N, 1);
    h.ALL_FOLDERS = cell(N, 1);
    for k = 1:N
        img = double(imread(fullfile(files(k).folder, files(k).name)));
if size(img, 2) >= 168
    img_cropped = img(:, 57:168); % center-crop for older wide images
else
    img_cropped = img; % already cropped to <=128 px wide; use as is
end 
        h.ALL_NORMS{k} = (img_cropped - min(img_cropped(:))) / (max(img_cropped(:)) - min(img_cropped(:)) + eps); h.ALL_NAMES{k} = files(k).name;
        h.ALL_FOLDERS{k} = files(k).folder;
    end
    [img_h, img_w] = size(h.ALL_NORMS{1}); h.c_low = NaN(N,1); h.c_high = NaN(N,1); h.c_dil = NaN(N,1); h.MANUAL_ADD = cell(N, 1); h.MANUAL_SUB = cell(N, 1); 
    for i=1:N, h.MANUAL_ADD{i} = false(img_h, img_w); h.MANUAL_SUB{i} = false(img_h, img_w); end
    h.undo_k = 0; h.undo_add = []; h.undo_sub = []; h.curr_page = 1; h.max_page = ceil(N / 10);
    guidata(fig, h); apply_language(fig); set(h.btn_run, 'Enable', 'on'); set(h.btn_export_ai, 'Enable', 'on'); update_preview(fig);
end
function reset_ui_state(fig, h)
    if ~isvalid(fig), return; end
    try
        for i=1:10, if isvalid(h.ax(i)), set(h.ax(i), 'XColor', [0.8 0.8 0.8], 'YColor', [0.8 0.8 0.8], 'LineWidth', 2); end; end
        if isvalid(h.txt_status)
            lang = get(h.popup_lang, 'Value'); 
            if lang == 1, set(h.txt_status, 'String', '안내: 원하시는 툴을 선택하세요.', 'ForegroundColor', [0 0.5 0]); else, set(h.txt_status, 'String', 'Info: Select a tool.', 'ForegroundColor', [0 0.5 0]); end
        end
        if h.N > 0 && isvalid(h.btn_run), set(h.btn_run, 'Enable', 'on'); set(h.btn_export_ai, 'Enable', 'on'); end
        if isvalid(fig), set(fig, 'Pointer', 'arrow'); drawnow; end
    catch
    end
end
function dropper_logic(fig, mode)
    if ~isvalid(fig), return; end
    h = guidata(fig); lang = get(h.popup_lang, 'Value'); if h.N == 0, return; end
    set(h.btn_run, 'Enable', 'off'); set(h.btn_export_ai, 'Enable', 'off'); set(fig, 'Pointer', 'crosshair');
    for i=1:10, set(h.ax(i), 'XColor', [1 0.8 0], 'YColor', [1 0.8 0], 'LineWidth', 4); end
    
    while isvalid(fig)
        if lang == 1
            if strcmp(mode, 'air'), set(h.txt_status, 'String', '안내: 파란색 마스크 기준 클릭 (취소: UI 또는 바탕 클릭)', 'ForegroundColor', [0 0 0.8]); else, set(h.txt_status, 'String', '안내: 빨간색 마스크 기준 클릭 (취소: UI 또는 바탕 클릭)', 'ForegroundColor', [0.8 0 0]); end
        else
            if strcmp(mode, 'air'), set(h.txt_status, 'String', 'Info: Click ref for BLUE mask (Cancel: Click UI/Away)', 'ForegroundColor', [0 0 0.8]); else, set(h.txt_status, 'String', 'Info: Click ref for RED mask (Cancel: Click UI/Away)', 'ForegroundColor', [0.8 0 0]); end
        end
        
        try 
            k = waitforbuttonpress;
            if ~isvalid(fig) || k==1, break; end % exit on keyboard input
            clicked_obj = gco(fig);
            
            % clicking UI (e.g., a button) ends the tool immediately
            if ~isempty(clicked_obj) && (strcmpi(clicked_obj.Type, 'uicontrol') || strcmpi(clicked_obj.Type, 'uipanel'))
                break;
            end
            
            idx_p = [];
            for i=1:10, if isequal(clicked_obj, h.ax(i)) || isequal(clicked_obj, h.h_img(i)), idx_p = i; break; end; end
            if isempty(idx_p), break; end
            
            g_idx = (h.curr_page - 1) * 10 + idx_p; if g_idx > h.N, continue; end
            set(h.popup_target, 'Value', idx_p + 1); popup_callback(fig); if ~isvalid(fig), break; end; h = guidata(fig);
            
            cp = get(h.ax(idx_p), 'CurrentPoint');
            x = round(cp(1,1)); y = round(cp(1,2));
            im = h.ALL_NORMS{g_idx}; if x<1 || x>size(im,2) || y<1 || y>size(im,1), continue; end
            
            c_low = h.g_clip_low; c_high = h.g_clip_high; im_k = im; im_k(im_k < prctile(im(:),c_low)) = prctile(im(:),c_low); im_k(im_k > prctile(im(:),c_high)) = prctile(im(:),c_high);
            cl_val = im_k(y, x); try [~, Ctr] = imsegkmeans(single(im_k), 3); catch, continue; end; Ctr = sort(Ctr);
            if strcmp(mode, 'air'), th_a = (Ctr(1)+Ctr(2))/2; n_off = cl_val - th_a + 0.01; h.c_low(g_idx) = max(min(n_off, 0.20), -0.40);
            else, th_m = (Ctr(2)+Ctr(3))/2; n_off = cl_val - th_m - 0.01; h.c_high(g_idx) = max(min(n_off, 0.40), -0.60); end
            [img_h, img_w] = size(im); h.MANUAL_ADD{g_idx} = false(img_h, img_w); h.MANUAL_SUB{g_idx} = false(img_h, img_w);
            guidata(fig, h); popup_callback(fig);
        catch, break; 
        end
    end
    reset_ui_state(fig, h);
end

% [key 2, 3] Event-driven fully seamless focusing-tool structure (margin bug fixed; cancel responsiveness maximized)
function tool_callback(fig, tool_type)
    if ~isvalid(fig), return; end
    h = guidata(fig); lang = get(h.popup_lang, 'Value'); if h.N == 0, return; end
    set(fig, 'CurrentObject', h.txt_status); set(h.btn_run, 'Enable', 'off'); set(h.btn_export_ai, 'Enable', 'off'); set(fig, 'Pointer', 'crosshair');
    for i=1:10, set(h.ax(i), 'XColor', [1 0.8 0], 'YColor', [1 0.8 0], 'LineWidth', 4); end
    
    if lang==1
        if strcmp(tool_type, 'reset'), set(h.txt_status, 'String', '안내: 초기화할 사진 계속 클릭 (취소: UI/바탕 클릭)', 'ForegroundColor', [0.8 0 0]);
        elseif strcmp(tool_type, 'bucket'), set(h.txt_status, 'String', '안내: 채울 곳 계속 클릭 (취소: UI/바탕 클릭)', 'ForegroundColor', [0.8 0.4 0]);
        elseif strcmp(tool_type, 'magic'), set(h.txt_status, 'String', '안내: 추가할 밝은 곳 계속 클릭 (취소: UI/바탕 클릭)', 'ForegroundColor', [0.8 0 0.8]); 
        elseif strcmp(tool_type, 'brush'), set(h.txt_status, 'String', '안내: 여러 사진 넘나들며 바로 칠하기 (취소: UI 클릭)', 'ForegroundColor', [0 0.6 0]);
        else, set(h.txt_status, 'String', '안내: 여러 사진 넘나들며 바로 지우기 (취소: UI 클릭)', 'ForegroundColor', [0 0 0.8]); 
        end
    else
        % English strings omitted for brevity, handled generally below
    end

    b_s = round(get(h.slider_brush, 'Value')); 
    if strcmp(tool_type, 'brush'), c_v = 'r'; else, c_v = 'b'; end

    while isvalid(fig)
        try
            % 1. detect the event the moment the mouse is pressed
            k = waitforbuttonpress;
            if ~isvalid(fig) || k==1, break; end % exit on window close or keyboard input
            
            clicked_obj = gco(fig);
            
            % 2. if the user pressed another UI element (tool, save button, etc.), end immediately (cancel bug fixed)
            if ~isempty(clicked_obj) && (strcmpi(clicked_obj.Type, 'uicontrol') || strcmpi(clicked_obj.Type, 'uipanel'))
                break;
            end
            
            % 3. identify which image was clicked
            idx_p = [];
            for i=1:10
                if isequal(clicked_obj, h.ax(i)) || isequal(clicked_obj, h.h_img(i))
                    idx_p = i; break;
                end
            end
            
            if isempty(idx_p), break; end % exit when clicking an empty background
            
            g_idx = (h.curr_page - 1) * 10 + idx_p; if g_idx > h.N, continue; end
            
            % 4. move focus smoothly without interruption (eliminates the root cause of the prior margin bug)
            set(h.popup_target, 'Value', idx_p + 1); popup_callback(fig); if ~isvalid(fig), break; end; h = guidata(fig);
            
            ax_c = h.ax(idx_p);
            
            if strcmp(tool_type, 'reset')
                [img_h, img_w] = size(h.ALL_NORMS{1}); h.undo_k = g_idx; h.undo_add = h.MANUAL_ADD{g_idx}; h.undo_sub = h.MANUAL_SUB{g_idx}; 
                h.MANUAL_ADD{g_idx} = false(img_h, img_w); h.MANUAL_SUB{g_idx} = false(img_h, img_w); h.c_high(g_idx) = NaN; h.c_low(g_idx) = NaN; h.c_dil(g_idx) = NaN; 
            
            elseif strcmp(tool_type, 'bucket') || strcmp(tool_type, 'magic')
                cp = get(ax_c, 'CurrentPoint');
                x = round(cp(1,1)); y = round(cp(1,2));
                im = h.ALL_NORMS{g_idx}; if x<1 || x>size(im, 2) || y<1 || y>size(im, 1), continue; end
                
                if strcmp(tool_type, 'bucket')
                    c_h = h.c_high(g_idx); if isnan(c_h), c_h = h.g_high; end; c_d = h.c_dil(g_idx); if isnan(c_d), c_d = h.g_dil; end
                    c_low = prctile(im(:), h.g_clip_low); c_high = prctile(im(:), h.g_clip_high); im_k = im; im_k(im_k<c_low) = c_low; im_k(im_k>c_high) = c_high;
                    try [~, Ctr] = imsegkmeans(single(im_k), 3); catch, continue; end; Ctr = sort(Ctr); th_m = (Ctr(2)+Ctr(3))/2;
                    met_raw = (im_k > (th_m + c_h)) | (im_k >= (Ctr(3) - 0.3*(Ctr(3)-Ctr(2)))); 
                    if c_d > 0, met_c = imdilate(met_raw, strel('disk', c_d)); else, met_c = met_raw; end
                    met_c = (met_c | h.MANUAL_ADD{g_idx}) & ~h.MANUAL_SUB{g_idx}; new_mask = bwselect(~met_c, x, y, 8);
                else
                    cl_val = im(y, x); sim_mask = abs(im - cl_val) <= 0.10; new_mask = bwselect(sim_mask, x, y, 8);
                end
                h.undo_k = g_idx; h.undo_add = h.MANUAL_ADD{g_idx}; h.undo_sub = h.MANUAL_SUB{g_idx};
                h.MANUAL_ADD{g_idx} = h.MANUAL_ADD{g_idx} | new_mask; h.MANUAL_SUB{g_idx} = h.MANUAL_SUB{g_idx} & ~new_mask; 
                
            elseif strcmp(tool_type, 'brush') || strcmp(tool_type, 'eraser')
                % the mouse is already pressed, so drawfreehand picks up the drag immediately without a click (seamless focusing)
                roi = drawfreehand(ax_c, 'Color', c_v); 
                if ~isvalid(fig) || ~isvalid(roi), break; end 
                
                h.undo_k = g_idx; h.undo_add = h.MANUAL_ADD{g_idx}; h.undo_sub = h.MANUAL_SUB{g_idx};
                mask_n = createMask(roi); pos = round(roi.Position); 
                
                % force-apply when only a single point was placed
                if size(pos, 1) == 1 || ~any(mask_n(:)) 
                    [im_h, im_w] = size(h.ALL_NORMS{1}); px = min(max(pos(1,1), 1), im_w); py = min(max(pos(1,2), 1), im_h); mask_n(py, px) = 1; 
                end
                delete(roi);
                
                if b_s > 0, mask_n = imdilate(mask_n, strel('disk', b_s)); end
                if strcmp(tool_type, 'brush'), h.MANUAL_ADD{g_idx} = h.MANUAL_ADD{g_idx} | mask_n; h.MANUAL_SUB{g_idx} = h.MANUAL_SUB{g_idx} & ~mask_n;
                else, h.MANUAL_SUB{g_idx} = h.MANUAL_SUB{g_idx} | mask_n; h.MANUAL_ADD{g_idx} = h.MANUAL_ADD{g_idx} & ~mask_n; end
            end
            guidata(fig, h); update_preview(fig); 
        catch
            break; 
        end
    end
    reset_ui_state(fig, h);
end

function run_extraction_callback(fig)
    if ~isvalid(fig), return; end
    h = guidata(fig); lang = get(h.popup_lang, 'Value');
    
    d = dialog('Position', [500, 400, 350, 380], 'Name', '라디오믹스 카테고리 선택');
    if lang==1, txt='추출할 피처 카테고리를 선택하세요:'; else, txt='Select Radiomics Categories to Extract:'; end
    uicontrol('Parent', d, 'Style', 'text', 'String', txt, 'Position', [20 330 300 20], 'FontWeight', 'bold', 'FontSize', 10, 'HorizontalAlignment','left');
    
    c_fo = uicontrol('Parent', d, 'Style', 'checkbox', 'String', '1. First-Order (1차원 통계)', 'Value', 1, 'Position', [30 290 300 20], 'FontSize', 9);
    c_glcm = uicontrol('Parent', d, 'Style', 'checkbox', 'String', '2. GLCM (질감 특징 1)', 'Value', 1, 'Position', [30 260 300 20], 'FontSize', 9);
    c_glrlm = uicontrol('Parent', d, 'Style', 'checkbox', 'String', '3. GLRLM (질감 특징 2)', 'Value', 1, 'Position', [30 230 300 20], 'FontSize', 9);
    c_glszm = uicontrol('Parent', d, 'Style', 'checkbox', 'String', '4. GLSZM (질감 특징 3)', 'Value', 1, 'Position', [30 200 300 20], 'FontSize', 9);
    c_ngtdm = uicontrol('Parent', d, 'Style', 'checkbox', 'String', '5. NGTDM (추가 질감 - PI-MRONJ 추천)', 'Value', 1, 'Position', [30 170 300 20], 'FontSize', 9, 'ForegroundColor', 'b');
    c_wav = uicontrol('Parent', d, 'Style', 'checkbox', 'String', '6. Wavelet (웨이블릿 변환 텍스처)', 'Value', 1, 'Position', [30 140 300 20], 'FontSize', 9);
    c_shape = uicontrol('Parent', d, 'Style', 'checkbox', 'String', '7. Shape (형태학적 - 크롭편향 주의, 기본OFF)', 'Value', 0, 'Position', [30 110 300 20], 'FontSize', 9, 'ForegroundColor', 'r');
    
    if lang==1, s_ok='추출 시작!'; s_no='취소'; else, s_ok='Extract!'; s_no='Cancel'; end
    uicontrol('Parent', d, 'Style', 'pushbutton', 'String', s_ok, 'Position', [60 30 100 40], 'FontWeight', 'bold', 'Callback', 'setappdata(gcf,''run'',1); uiresume(gcf);');
    uicontrol('Parent', d, 'Style', 'pushbutton', 'String', s_no, 'Position', [190 30 100 40], 'FontWeight', 'bold', 'Callback', 'setappdata(gcf,''run'',0); uiresume(gcf);');
    
    uiwait(d);
    if ~isvalid(d) || getappdata(d, 'run') ~= 1
        if isvalid(d), close(d); end
        return;
    end
    
    flags.fo = get(c_fo, 'Value'); flags.glcm = get(c_glcm, 'Value'); flags.glrlm = get(c_glrlm, 'Value');
    flags.glszm = get(c_glszm, 'Value'); flags.ngtdm = get(c_ngtdm, 'Value'); flags.wav = get(c_wav, 'Value'); flags.shape = get(c_shape, 'Value');
    close(d);
    
    set(fig, 'Pointer', 'watch'); drawnow;
    execute_extraction(fig, flags, h.NBINS); 
    if isvalid(fig), set(fig, 'Pointer', 'arrow'); end
end

function apply_language(fig)
    if ~isvalid(fig), return; end
    h = guidata(fig); lang = get(h.popup_lang, 'Value'); 
    str_popup = cell(1, 11);
    if lang == 1 % KOR
        set(h.txt_lbl_target, 'String', '🎯 조절 대상:'); set(h.txt_lbl_clip_low, 'String', '하위 클립(%):'); set(h.txt_lbl_clip_high, 'String', '상위 클립(%):'); set(h.btn_apply_clip, 'String', '🔄 적용');
        set(h.txt_lbl_low, 'String', '파란색(공기):'); set(h.txt_lbl_high, 'String', '빨간색(금속):'); set(h.txt_lbl_dil, 'String', '팽창 두께:'); set(h.txt_lbl_brush, 'String', '브러쉬 두께:'); set(h.txt_status, 'String', '안내: 원하시는 툴을 선택하세요.');
        set(h.btn_bucket, 'String', '🪣 페인트통'); set(h.btn_magic, 'String', '🪄 매직완드'); set(h.btn_reset, 'String', '🗑️ 초기화');
        set(h.btn_brush, 'String', '🖌️ 올가미'); set(h.btn_eraser, 'String', '🧽 지우개'); set(h.btn_undo, 'String', '↩️ 실행취소'); set(h.btn_prev, 'String', '◀ 이전 10개'); set(h.btn_next, 'String', '▶ 다음 10개'); 
        set(h.btn_run, 'String', sprintf('📊 라디오믹스 추출 (%d개)', h.N)); set(h.btn_export_ai, 'String', '🤖 AI 마스크셋 내보내기');
        set(h.btn_save_mask, 'String', sprintf('💾 프로젝트 저장 (%s)', h.PROJECT_EXT)); set(h.btn_load_mask, 'String', sprintf('📂 프로젝트 열기 (%s)', h.PROJECT_EXT));
        set(h.txt_lbl_in, 'String', '입력:'); set(h.txt_lbl_out, 'String', '출력:'); set(h.btn_load, 'String', '🔄 로드');
        str_popup{1} = '[전체 일괄 조절 (Global)]'; for i=1:10, str_popup{i+1} = sprintf('%d번 사진', i); end
    else % ENG
        set(h.txt_lbl_target, 'String', '🎯 Target:'); set(h.txt_lbl_clip_low, 'String', 'Low Clip(%):'); set(h.txt_lbl_clip_high, 'String', 'High Clip(%):'); set(h.btn_apply_clip, 'String', '🔄 Apply');
        set(h.txt_lbl_low, 'String', 'Blue(Air):'); set(h.txt_lbl_high, 'String', 'Red(Metal):'); set(h.txt_lbl_dil, 'String', 'Dilate px:'); set(h.txt_lbl_brush, 'String', 'Brush px:'); set(h.txt_status, 'String', 'Info: Select a tool.');
        set(h.btn_bucket, 'String', '🪣 Bucket'); set(h.btn_magic, 'String', '🪄 Magic Wand'); set(h.btn_reset, 'String', '🗑️ Reset');
        set(h.btn_brush, 'String', '🖌️ Lasso'); set(h.btn_eraser, 'String', '🧽 Eraser');  set(h.btn_undo, 'String', '↩️ Undo'); set(h.btn_prev, 'String', '◀ Prev 10'); set(h.btn_next, 'String', '▶ Next 10'); 
        set(h.btn_run, 'String', sprintf('📊 Extract Radiomics (%d)', h.N)); set(h.btn_export_ai, 'String', '🤖 Export AI Masks');
        set(h.btn_save_mask, 'String', sprintf('💾 Save Project (%s)', h.PROJECT_EXT)); set(h.btn_load_mask, 'String', sprintf('📂 Load Project (%s)', h.PROJECT_EXT));
        set(h.txt_lbl_in, 'String', 'In:'); set(h.txt_lbl_out, 'String', 'Out:'); set(h.btn_load, 'String', '🔄 Load');
        str_popup{1} = '[Apply to All (Global)]'; for i=1:10, str_popup{i+1} = sprintf('Image %d', i); end
    end
    set(h.popup_target, 'String', str_popup); if h.N > 0, update_preview(fig); end
end
function turn_page(fig,d); if ~isvalid(fig), return; end; h=guidata(fig); if h.N==0, return; end; h.curr_page=h.curr_page+d; h.curr_page=max(1,min(h.curr_page,h.max_page)); set(h.popup_target,'Value',1); guidata(fig,h); popup_callback(fig); end
function apply_clip_callback(fig); if ~isvalid(fig), return; end; h=guidata(fig); nl=str2double(get(h.edit_clip_low,'String')); nh=str2double(get(h.edit_clip_high,'String')); if isnan(nl)||isnan(nh)||nl<0||nh>100||nl>=nh,return; end; h.g_clip_low=nl; h.g_clip_high=nh; guidata(fig,h); if h.N>0, update_preview(fig); end; end
function popup_callback(fig); if ~isvalid(fig), return; end; h=guidata(fig); if h.N==0, return; end; pv=get(h.popup_target,'Value'); if pv==1, set(h.slider_low,'Value',h.g_low); set(h.slider_high,'Value',h.g_high); set(h.slider_dil,'Value',h.g_dil); else, s_i=(h.curr_page-1)*10+1; idx=s_i+(pv-2); if idx<=h.N, cl=h.c_low(idx); if isnan(cl),cl=h.g_low; end; ch=h.c_high(idx); if isnan(ch),ch=h.g_high; end; cd=h.c_dil(idx); if isnan(cd),cd=h.g_dil; end; set(h.slider_low,'Value',cl); set(h.slider_high,'Value',ch); set(h.slider_dil,'Value',cd); end; end; update_preview(fig); end
function slider_callback(fig); if ~isvalid(fig), return; end; h=guidata(fig); if h.N==0, return; end; pv=get(h.popup_target,'Value'); vl=get(h.slider_low,'Value'); vh=get(h.slider_high,'Value'); vd=round(get(h.slider_dil,'Value')); if pv==1, h.g_low=vl; h.g_high=vh; h.g_dil=vd; else, s_i=(h.curr_page-1)*10+1; idx=s_i+(pv-2); if idx<=h.N, h.c_low(idx)=vl; h.c_high(idx)=vh; h.c_dil(idx)=vd; end; end; guidata(fig,h); update_preview(fig); end
function undo_callback(fig); if ~isvalid(fig), return; end; h=guidata(fig); if h.undo_k==0,return; end; t_a=h.MANUAL_ADD{h.undo_k}; t_s=h.MANUAL_SUB{h.undo_k}; h.MANUAL_ADD{h.undo_k}=h.undo_add; h.MANUAL_SUB{h.undo_k}=h.undo_sub; h.undo_add=t_a; h.undo_sub=t_s; guidata(fig,h); update_preview(fig); end
function update_preview(fig); if ~isvalid(fig), return; end; h=guidata(fig); if h.N==0, return; end; set(h.txt_low,'String',sprintf('%.2f',get(h.slider_low,'Value'))); set(h.txt_high,'String',sprintf('%.2f',get(h.slider_high,'Value'))); set(h.txt_dil,'String',sprintf('%d px',round(get(h.slider_dil,'Value')))); s_i=(h.curr_page-1)*10+1; e_i=min(h.curr_page*10,h.N); p_idx=1; lang=get(h.popup_lang,'Value'); if lang==1, b_str='뼈'; else, b_str='Bone'; end; for i=s_i:e_i, im=h.ALL_NORMS{i}; c_l=h.c_low(i); if isnan(c_l), c_l=h.g_low; end; c_h=h.c_high(i); if isnan(c_h), c_h=h.g_high; end; c_d=h.c_dil(i); if isnan(c_d), c_d=h.g_dil; end; im_k=im; im_k(im_k<prctile(im(:),h.g_clip_low))=prctile(im(:),h.g_clip_low); im_k(im_k>prctile(im(:),h.g_clip_high))=prctile(im(:),h.g_clip_high); try [~,Ctr]=imsegkmeans(single(im_k),3); catch, p_idx=p_idx+1; continue; end; Ctr=sort(Ctr); th_a=(Ctr(1)+Ctr(2))/2; th_m=(Ctr(2)+Ctr(3))/2; air=im_k<(th_a+c_l); met_r=(im_k>(th_m+c_h)); met_e=im_k>=(Ctr(3) - 0.3*(Ctr(3)-Ctr(2))); met_c=met_r|met_e; if c_d>0, met=imdilate(met_c,strel('disk',c_d)); else, met=met_c; end; met=(met|h.MANUAL_ADD{i})&~h.MANUAL_SUB{i}; bone=~(air|met); R=im; G=im; B=im; R(met)=im(met)*0.7+0.3; G(met)=im(met)*0.7; B(met)=im(met)*0.7; R(air)=im(air)*0.7; G(air)=im(air)*0.7; B(air)=im(air)*0.7+0.3; overlay=cat(3,min(R,1),min(G,1),min(B,1)); if isvalid(h.h_img(p_idx)), set(h.h_img(p_idx),'CData',overlay); set(h.ax(p_idx),'Visible','on'); end; bp=100*sum(bone(:))/numel(bone); ed=~isnan(h.c_high(i))||any(h.MANUAL_ADD{i}(:))||any(h.MANUAL_SUB{i}(:)); if isvalid(h.h_title(p_idx)), if ed, set(h.h_title(p_idx),'Visible','on','String',sprintf('[%d/%d] %s (*)\n%s: %.0f%%',i,h.N,h.ALL_NAMES{i},b_str,bp),'Color','r','FontWeight','bold'); else, set(h.h_title(p_idx),'Visible','on','String',sprintf('[%d/%d] %s\n%s: %.0f%%',i,h.N,h.ALL_NAMES{i},b_str,bp),'Color','k','FontWeight','normal'); end; end; p_idx=p_idx+1; end; for i=p_idx:10, if isvalid(h.h_img(i)), set(h.h_img(i),'CData',zeros(size(im))); set(h.ax(i),'Visible','off'); set(h.h_title(i),'Visible','off'); end; end; drawnow; axes_list = findobj(fig, 'Type', 'axes');
    for a = 1:length(axes_list)
        axis(axes_list(a), 'image'); 
    end; end