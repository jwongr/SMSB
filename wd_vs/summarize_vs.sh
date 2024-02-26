echo "ligand,score" > vs_results.csv
for dklog in docks/*log;
	do 
		echo "Procesando ligando $dklog";
		result=`grep '1    ' -m 1 $dklog | tr -s ' ' |  cut -d ' ' -f2`;
		name=`basename $dklog .log`;
		echo "$name, $result" >> vs_results.csv;
		echo $result;
	done
