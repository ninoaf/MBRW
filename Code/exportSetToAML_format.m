function [ out ] = exportSetToAML_format( clickstream_set, name_str )
%EXPORTTESTSETTOAML_FORMAT Summary of this function goes here
%   Detailed explanation goes here

fid = fopen(name_str,'w');

for i = 1 : length( clickstream_set )
    user_id = i;
    tmp_cs = clickstream_set{i};
    for j = 1 : length(tmp_cs)
        fprintf(fid, '%d %d\n', user_id, tmp_cs(j) );
    end
end
fclose(fid);

out = 1;
end