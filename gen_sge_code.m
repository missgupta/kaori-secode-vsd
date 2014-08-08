function gen_sge_code(shot_ann, szPat, num_job)
	
	script_dir = '/net/per900a/raid0/plsang/tools/kaori-secode-vsd2013';
	
	script_name = 'vsd_mbh_fv_encode_sge';
	
	sge_sh_file = sprintf('%s/%s.sh', script_dir, script_name);
	
	shots = vsd_load_shots(shot_ann, szPat);
	start_num = 1;
	end_num = length(shots);
	pattern = sprintf('mbh %s %s %%d %%d', shot_ann, szPat);
	
	[file_dir, file_name] = fileparts(sge_sh_file);
	output_dir = ['/net/per900a/raid0/plsang/tools/kaori-secode-vsd2013/', script_name, '-', shot_ann];
	
	if ~exist(output_dir, 'file'),
		mkdir(output_dir);
	end
	

	output_file = sprintf('%s/%s.%s.qsub.sh', output_dir, szPat, file_name);
	fh = fopen(output_file, 'w');
	
	num_per_job = ceil((end_num - start_num + 1)/num_job);	
	
	for ii = 1:num_job,
		start_idx = start_num + (ii-1)*num_per_job;
		end_idx = start_num + ii*num_per_job - 1;
		
		if(end_idx > end_num)
			end_idx = end_num;
		end
		
		params = sprintf(pattern, start_idx, end_idx);
		fprintf(fh, 'qsub -e /dev/null -o /dev/null %s %s\n', sge_sh_file, params);
		
		if end_idx == end_num, break; end;
	end
	
	cmd = sprintf('chmod +x %s', output_file);
	system(cmd);
	
	fclose(fh);
end