propka3 $1_unprep.pdb
sed '1,/       Group      pKa  model-pKa   ligand atom-type/d' $1_unprep.pka | sed '/^-----/,$d' | sed 's/ \+/ /g' > temp_pka_changes.txt
sed -i 's/^[[:space:]]*//' temp_pka_changes.txt
sed -i '1i Resname Resid Chain pka model_pka' temp_pka_changes.txt
python patching_info.py
rm temp_pka_changes.txt


