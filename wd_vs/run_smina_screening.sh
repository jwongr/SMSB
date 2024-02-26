for lig in ligs_pdbqt/*.pdbqt;
	do 
		name=`basename $lig .pdbqt`;
		echo "Ejecutando para $name";
		smina --config dockings_smina.conf --ligand $lig \
			--log docks/$name.log --out docks/"$name"_dk.pdbqt;
	done
