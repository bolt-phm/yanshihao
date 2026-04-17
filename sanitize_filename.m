%==========================================================================
% 文件名: sanitize_filename.m
% 描述: 将字符串转换为可安全落盘的文件名
%==========================================================================
function safe_name = sanitize_filename(raw_name)

if isstring(raw_name)
    raw_name = char(raw_name);
end

safe_name = regexprep(raw_name, "[^\w\-]", "_");
safe_name = regexprep(safe_name, "_+", "_");
safe_name = strip(safe_name, "_");

if isempty(safe_name)
    safe_name = "unnamed";
end

end

