# Acomplamiento molecular con Autodock 4.2
![enter image description here](https://jriccil.github.io/Taller_Simulacion_Molecular/images/ad4_wflow.png) 

> Créditos: Dr. Joel Ricci

## Fase 1: Obtención y preparación de las moléculas
### Carpeta de trabajo

Desde el directorio $HOME en la terminal de Linux, nos cambiamos al escritorio y creamos una nueva carpeta de trabajo

    cd Desktop
    mkdir wd_dk
    cd wd_dk

### Obtención de la proteína con UCSF Chimera

 1. De la base de datos de PDB, descargamos el PDB de la proteína [CDK2](https://www.uniprot.org/uniprotkb/P24941/entry): **5IF1**
 2. Movemos el archivo *.pdb* a nuestro directorio de trabajo *wd_dk*
 3. En la terminal activamos el ambiente *mds* que tiene VMD
  ```
 conda activate mds
 vmd -dispdev text 5if1.pdb
 ``` 
  
 4. Con esto, estaremos dentro de una terminal de VMD, vamos a escribir los siguientes comandos para generar un archivo *.pdb* con solamente los átomos de la proteína CDK2
  ```
 set cdk2 [atomselect top "protein and chain A"]`
 $cdk2 writepdb prot_unprep.pdb`
 exit
 ``` 

### Preparación del archivo de entrada de la proteína
Dentro del ambiente *dock* vamos a utilizar el software PDB2PQR, que servirá para tener el archivo *pdb* con la nomenclatura de AMBER y para agregar los hidrógenos al archivo. En este caso se protona a pH 7. Este archivo llevará el nombre ==prot.pdb==

    pdb2pqr30 --ff='AMBER' --ffout='AMBER' --with-ph=7.0 \
    --drop-water --keep-chain --pdb-output prot.pdb \
    prot_unprep.pdb pqr_file.pqr

> Investiga que es un archivo .pqr y los flags del comando pdb2pqr30
### Obtención y preparación de la molécula ligante
De las distintas bases de datos que existen para descargar moléculas pequeñas, utilizaremos [PubChem](https://pubchem.ncbi.nlm.nih.gov/compound/Adenosine-5_-triphosphate). Con esto vamos a generar una molécula de ATP a partir de su formato [SMILES](https://es.wikipedia.org/wiki/SMILES).

    C1=NC(=C2C(=N1)N(C=N2)C3C(C(C(O3)COP(=O)(O)OP(=O)(O)OP(=O)(O)O)O)O)N
Vamos a guardar este texto en un archivo de texto con el nombre ==smiles_atp.smi==.

Desde la terminal, utilizaremos ==obabel== para transformar el archivo *SMILES* a *mol2* con cargas parciales. Así, podremos utilizar la molécula de ATP con el docking y habremos generado un archivo 3D.

    obabel -ismi smiles_atp.smi -omol2 -O ATP.mol2 --gen3d -p 7 \
    --partialcharge gasteiger
Explora el archivo resultante y visualiza la estructura en Chimera UCSF o VMD

> Investiga sobre el archivo .mol2 y las cargas parciales de Gasteiger

## Fase 2: Preparación de Docking

Vamos a añadir los scripts de MGLTools al PATH de la máquina virtual

```
echo \
    'export PATH="/home/ssb/miniconda3/envs/ad4/MGLToolsPckgs/AutoDockTools/Utilities24/:"$PATH' \
    >> ~/.zshrc
```
### Preparación de ligando y receptor
Ahora vamos a trabajar con el ==ambiente *ad4*== y vamos a preparar los archivos *.pdb* de receptor y ligando en un formato *.pdbqt*

> Investiga que es un archivo .pdbqt

Para preparar el ligando, vamos a usar el comando *[prepare_ligand4.py](https://dasher.wustl.edu/chem430/software/autodock/tutorial-hiv-protease.pdf)* . Si lo ejecutamos sin ninguna entrada, la terminal nos desplegará información sobre este comando. 

    prepare_ligand4.py -l ATP.mol2 -v -o ATP.pdbqt -d ligand_dict.py \
    -U 'nphs_lps' -C

> Analiza el archivo ligand_dict.py

Para la preparación del archivo de receptor, se utiliza un comando parecido

    prepare_receptor4.py -r prot.pdb -o prot.pdbqt -U 'nphs' -v
### Preparativos con Autogrid

Llegamos a la parte más tediosa del procedimiento, vamos a ejecutar Autogrid, que es la fase de entrenamiento del algoritmo que utiliza Autodock. Para esto necesitamos crear un archivo de configuración ==*.gpf*== el cuál contendrá la siguiente información.

 - Centro y tamaño de la caja de búsqueda del docking
 - Resolución de la rejilla
 - Tipos de átomos entre ligando y receptor

Para generar este archivo, será importante identificar el sitio activo de la enzima o el sitio de interés para nuestro ligando.  Algunos servidores que nos pueden ayudar para esto son: [CASTp](http://sts.bioe.uic.edu/castp/index.html?201l) y [fpocket](https://bioserv.rpbs.univ-paris-diderot.fr/services/fpocket/). 

Ahora vamos a obtener manualmente las dimensiones de la caja y la resolución, para eso, abriremos el archivo del receptor en Autodock usando:

    adt prot.pdbqt
Nos vamos a la opción *Grid > Grid Box* y manualmente, movemos el tamaño y centro de la caja de tal forma que se cubra el sitio de interés. De ==**forma manual, vamos a guardar las coordenadas y dimensiones**==.

Para crear el archivo de entrada de Autogrid, usaremos el siguiente comando en la terminal:
```
prepare_gpf4.py \
    -r prot.pdbqt \
    -l ATP.pdbqt \
    -d ligand_dict.py \
    -p npts='x,y,z' \
    -p ligand_types='A,C,HD,N,NA,OA,P' \
    -p gridcenter='xc,yc,zc' \
    -o GPF.gpf
```
Reemplazando x,y,z y xc,yc,zc por las dimensiones y centro de la caja que guardamos y en ligand_types usando la información del archivo *ligand_dict.py* 

    No olvides inspeccionar el archivo GPF.gpf

## Fase 3: Ejecución de Docking

Ejecutar Autogrid usando (puede tomar unos minutos):

    autogrid4 -p GPF.gpf -l GLG.glg
Durante esta fase un **átomo de “prueba”** (_probe atom_), para cada tipo de átomo del ligando, es colocado en cada punto de la caja, y se calcula la energía (para cada término del campo de fuerza) de interacción de este átomo con cada átomo de la proteína. Dicha energía es asignada a cada punto de la caja según la función de scoring de Autodock. De la misma manera se calculan los maps para los potenciales electrostáticos y de solvatación.

Seguido de esto, se genera el archivo de configuración para Autodock4. En donde se específica la molécula receptora y ligando y los parámetros del algoritmo genético. 
```
prepare_dpf42.py \
    -l ATP.pdbqt \
    -r prot.pdbqt \
    -o DPF.dpf \
    -p ga_num_evals='1000000' \
    -p ga_run='3' \
    -p ga_num_generations='27000' \
    -p ga_pop_size='150' \
    -p unbound_model='bound' \
    -p rmstol='2.0' \
    -p outlev='adt' \
    -v \
    -s
```

> Observa el archivo resultante para obtener más información sobre los parámetros y para más detalle, el manual de [Autodock](https://autodocksuite.scripps.edu/wp-content/uploads/sites/31/2019/03/AutoDock4.2.6_UserGuide.pdf)

### Por fin: Ejecución de Autodock

    autodock4 -p DPF.dpf -l DLG.dlg

> Puede tomar unos minutos. Recuerda que los parámetros del algoritmo genético utilizados en este ejemplo no son suficientes para un estudio válido.

## Fase 4: Resultados de Docking
Desde el archivo resultante DLG.dlg, es posible encontrar la información sobre los resultados del docking. Te recomiendo leer el manual de [Autodock](https://autodocksuite.scripps.edu/wp-content/uploads/sites/31/2019/03/AutoDock4.2.6_UserGuide.pdf) para más información.
Gracias a MGLTools, tenemos acceso también al siguiente comando que nos servirá para extraer un resumen de los resultados.
```
summarize_results4.py \
    -d .\
    -r prot.pdbqt \
    -b -e -k \
    -o ATP_dock_results.txt
```

> Corre el comando summarize_results4.py sin argumentos para más información sobre las flags

Además, podemos obtener las mejor pose del ligando en un archivo *.pdbqt* para observarla en Autodock
```
write_lowest_energy_ligand.py -f DLG.dlg \
    -o best_pose_ATP.pdbqt -N
```

Para transformarlo en *pdb* para observarlo en Chimera o VMD usamos:
```
pdbqt_to_pdb.py \
    -f best_pose_ATP.pdbqt \
    -o best_pose_ATP.pdb
```
Ahora ya tienes la información cuantitativa en el archivo *.dlg* y para generar imágenes con los dos últimos archivos que creamos.
## Recursos extra

 - [Tutorial](https://www.youtube.com/watch?v=0bj7tImWXSc) para explorar resultados con [Autodock](https://www.moodle.is.ed.ac.uk/pluginfile.php/87431/mod_resource/content/1/2012_ADTtut.pdf)
 - [Tutorial](https://www.cgl.ucsf.edu/chimera/docs/ContributedSoftware/viewdock/framevd.html) para explorar resultados con Chimera

> Written with [StackEdit](https://stackedit.io/). by Javier Wong


