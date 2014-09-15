function concepts = vsd_load_concept_list(concept_file)
	
	% format: 0 #$# objviolentscenes #$# objviolentscenes
	fh = fopen(concept_file, 'r');
	
	infos = textscan(fh, '%s %*q %s %*q %s', 'delimiter', ' #$# ', 'MultipleDelimsAsOne', 1 );
	
	concepts = infos{2};
	
	fclose(fh);

end
