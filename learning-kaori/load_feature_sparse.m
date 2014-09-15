
function hists = load_feature_sparse(tarFile, feat_dim)
    tmpDir = '/net/per900a/raid0/plsang/tmp';
	try
    oFile = untar(tarFile, tmpDir);
	catch
		hists = [];
		return;
	end
    oFile = cell2mat(oFile);
    	
    fid = fopen(oFile, 'r');
    tline = fgets(fid);
    
	hists = struct;
	
    while ischar(tline)
        %skip comment lines, start with %
        if strfind(tline, '%') == 1, 
			tline = fgets(fid);
			continue; 
		end
		
        [szFea szAnn] = strread(tline, '%s %s', 'delimiter', '%');
        szFea = cell2mat(szFea);
        szAnn = cell2mat(szAnn);
		
        fea = sscanf(szFea, '%f');
		
		fea_idx = fea(2:2:end);
		fea_val = fea(3:2:end);
		
        % check if read corectly: numDim n1 n2 ... nDim
        if fea(1) ~= length(fea_idx) || fea(1) ~= length(fea_val),
            error('ERROR: Reading feature file [Feature Dim: %d / Index Dim: %d/ Value Dim: %d]\n', ...
                fea(1), length(fea_idx), length(fea_val)); 
        end
        
		splits = regexp(szAnn, ' ', 'split');
		if length(splits) ~= 3,
			error('ERROR: Unknown annotation format <%s>\n', szAnn);
		end
		
		shot_id = splits{3};
		new_shot_id = strrep(shot_id, '.', '_');
		
		hist_ = zeros(feat_dim, 1);
		hist_(fea_idx) = fea_val;
        hists.(new_shot_id) = hist_;
        
        % read next line
        tline = fgets(fid);
    end

    fclose(fid);
    delete(oFile);
end
