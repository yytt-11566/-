clc; clear; close all;

%% ========== 1. 读取并预处理输入图像 ==========
img = imread('roku1.png'); % 输入图片路径
if size(img, 3) == 3
    img = rgb2gray(img);
end

% 统一预处理：灰度→二值化→反转→去噪→裁切→缩放
level = graythresh(img);
img_bw = ~imbinarize(img, level); % 确保黑底白字
img_clean = bwareaopen(img_bw, 50); % 去噪

% 找到数字主体并裁切
stats = regionprops(img_clean, 'BoundingBox');
if isempty(stats)
    error('没找到数字！检查图片');
end
max_area_idx = 1;
max_area = 0;
for i = 1:length(stats)
    area = stats(i).BoundingBox(3) * stats(i).BoundingBox(4);
    if area > max_area
        max_area = area;
        max_area_idx = i;
    end
end
bbox = stats(max_area_idx).BoundingBox;
img_crop = imcrop(img_clean, bbox);
img_norm = imresize(img_crop, [28 28]); % 统一缩放到28x28
 
templates = cell(10, 1);
% 按顺序对应0-9的模板文件
template_files = {
    'zero1.png', ...   % 索引1 → 数字0
    'ichi1.png', ...   % 索引2 → 数字1
    'ni2.png', ...     % 索引3 → 数字2
    'san1.png', ...    % 索引4 → 数字3
    'yon1.png', ...    % 索引5 → 数字4
    'go1.png', ...     % 索引6 → 数字5
    'roku1.png', ...   % 索引7 → 数字6
    'nana1.png', ...   % 索引8 → 数字7
    'hachi1.png', ...  % 索引9 → 数字8
    'kilyuu1.png'        % 索引10 → 数字9
};

for i = 1:10
    temp_img = imread(template_files{i});
    if size(temp_img, 3) == 3
        temp_img = rgb2gray(temp_img);
    end
    temp_level = graythresh(temp_img);
    temp_bw = ~imbinarize(temp_img, temp_level);
    temp_clean = bwareaopen(temp_bw, 50);
    temp_stats = regionprops(temp_clean, 'BoundingBox');
    temp_bbox = temp_stats(1).BoundingBox;
    temp_crop = imcrop(temp_clean, temp_bbox);
    templates{i} = imresize(temp_crop, [28 28]);
end

%% ========== 3.用归一化相关系数，代替像素差异 ==========
scores = zeros(10, 1);
input_norm = double(img_norm);
input_norm = (input_norm - mean(input_norm(:))) / std(input_norm(:)); % 归一化

for i = 1:10
    temp_norm = double(templates{i});
    temp_norm = (temp_norm - mean(temp_norm(:))) / std(temp_norm(:));
    % 相关系数越接近1，匹配度越高
    scores(i) = corr2(input_norm, temp_norm);
end

% 找到匹配度最高的模板
[~, pred_idx] = max(scores);
pred_num = pred_idx - 1;

%% ========== 4. 显示结果 ==========
figure('Name','数字识别结果');
subplot(2,3,1); imshow(img); title('原始灰度图');
subplot(2,3,2); imshow(img_bw); title('二值化图像');
subplot(2,3,3); imshow(img_clean); title('去噪后图像');
subplot(2,3,4); imshow(img_crop); title('裁切后数字');
subplot(2,3,5); imshow(img_norm); title('归一化数字');

subplot(2,3,6);
bar(0:9, scores);
hold on;
bar(pred_num, scores(pred_idx), 'r');
hold off;
xlabel('数字'); ylabel('匹配分数（越高越匹配）');
title(['识别结果：数字 ', num2str(pred_num)]);
grid on;

disp('各数字模板的相关系数：');
disp(scores);
disp(['匹配度最高的模板索引：', num2str(pred_idx), ' → 对应数字：', num2str(pred_num)]);