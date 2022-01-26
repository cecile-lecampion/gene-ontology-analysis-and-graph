# Automatically format Gene ontology data for graphical representation with R

# Prerequisites for MacOS

Install Xcode from the App Store (it is quite long)

<img src=".images/gene-ontology/image-20210607125457492.png" alt="image-20210607125457492" style="zoom: 33%;" />

Start Xcode to allow complete installation. The computer pass word will be required.

Quit.

# Prerequisites for Windows

## Install UNIX terminal

- Download on your PC the file [TerminalUnixSetup.exe](https://github.com/cecile-lecampion/gene-ontology-analysis-and-graph/releases/download/1.0.0/TerminalUnixSetup.exe)

    This is an executable that will install a UNIX terminal in your `HOME` directory

- Execute `TerminalUnixSetup.exe` 

    The UNIX terminal comes with all necessary tools. A `tools` directory is created in your  `HOME`. It contains the script `prepare_gene_onthology.pl`

    

## Lancement du terminal

Select `Git Bash` in the Windows menu or click the icon on your desk.

![image-20210405175008398](.images/gene-ontology/image-20210405175008398.png)

# Script for data preparation

## Install file on MacOS

### Preparation

- Save the file `prepare_gene_onthology.pl` in `Downloads`

- Open a UNIX terminal : `Terminal` 

    <img src=".images/gene-ontology/image-20210422085133689.png" alt="image-20210422085133689" style="zoom:33%;" />

### Create a  `tools` directory that will contain the script

- Execute the following command

    ```bash
    mkdir -p $HOME/tools
    ```

### Install the `prepare_gene_onthology.pl`  file in the  `tools` directory

- Execute the following commandsto move the file and make it executable

    ```bash
    mv $HOME/Downloads/prepare_gene_onthology.pl $HOME/tools
    chmod +x $HOME/tools/prepare_gene_onthology.pl
    ```

- Close the terminal.

## Install file on Windows

The file was already install by the executable `TerminalUnixSetup.exe` :smile:

## First execution

### Open a UNIX terminal in the directory that contains the file to analyse



### Start the script `prepare_gene_onthology.pl`

```bash
$HOME/tools/prepare_gene_onthology.pl
```

If the terminal shows the message below you can jump to the "Next executions" part.

```bash
prepare_gene_onthology.pl [--help|--man|--version]

or

prepare_gene_onthology.pl [-m|--method] [-c|--correction] input_gene_list.tsv output_curated_gene_ontology.tsv
```

On the contrary, if you get the message below, that means that some Perl modules need to be installed :

```
Au moins un des modules Perl nécessaires n'est pas installé.
Pour utiliser ce script vous devez d'abord exécuter les commandes suivantes:

cpan App::cpanminus
cpanm WWW::Mechanize
cpanm JSON
```

Create or update`.zshrc` file

```bash
touch .zshrc .bashrc
```

Execute command:

```bash
cpan App::cpanminus
```

> This command may ask questions.
>
> Accept all default answer with  `Enter` 

:warning: ​**==Open a new tab in the terminal with==** `cmd+t`

Then execute:

```bash
cpanm WWW::Mechanize
```

This step can take some times, be patient

Finally, execute :

```bash
cpanm JSON
```

## Next executions

The script `prepare_gene_onthology.pl` perform gene ontology analysis using PANTHER and REVIGO from a gene ID list according to the protocole descibed by Bonnot et al, 2019 . It formats the result so that it can be used by the scripts `script_1plot.R` and `script_2plot.R` which perform graphical representation of the ontology analysis.

PANTHER now, sort the results in a graphical order, so that each GO_id is link to the so called parent or main GO_id that characterize a class of ontology. This information is kept in the file `output_go_ids_hierarchy.tsv` and is used by the script  `script_1plot_hierarchy.R`. 

:warning: The main GO_id whne alone don’t show up in the list but are took into account by de R script

The command is :

```bash
$HOME/tools/prepare_gene_onthology.pl [-m|--method] [-c|--correction] input_gene_list.tsv output_curated_gene_ontology.tsv output_go_ids_hierarchy.tsv
```

The script has 2 option : `[-m|--method]` and ` [-c|--correction]` . 

The value for the  `[-m|--method]`are : 	biological_process 
            	  														cellular_component
            	  														molecular_function

Default value is `biological_process`.

The value for  ` [-c|--correction]`  are :	fdr

​																	  		bonferroni

Default value is `fdr`.



`input_gene_list.tsv` is the file that contains your data, let's call it `myfile.tsv` for the exemple. 

The extention`.tsv` means "Tab-separated values". Any file with the data in tab separated columns is suitable to use with the script, no matter of the extention (a `.txt` file can be used).

`output_curated_gene_ontology.tsv` is the default name for the output file, you can change it..

Command can be :

```bash
$HOME/tools/prepare_gene_onthology.pl --method biological_process --correction fdr myfile.tsv my_output_file.tsv my_hierarchy_file.tsv
```

Or :

```bash
$HOME/tools/prepare_gene_onthology.pl -m biological_process -c fdr myfile.tsv my_output_file.tsv my_hierarchy_file.tsv
```

Get syntax information with :

```bash
prepare_gene_onthology.pl --man
```

You get the manual. To close it press  `q`.

If you execute the command:

```bash
$HOME/tools/prepare_gene_onthology.pl --method biological_process --correction fdr myfile.tsv my_output_file.tsv my_hierarchy_file.tsv
```

Terminal shows the below message :

```bash
Step 1/7 Extract gene ID list from /Volumes/Disk_4To/Donnees_ARA2/Clusters/2w_5clusters/cluster1.txt
Step 2/7 Panther ontology analysis => /tmp/gene_ontology_analysis.txt, /tmp/gene_ontology_analysis.json
request...
export result to /tmp/gene_ontology_analysis.txt
export result to /tmp/gene_ontology_analysis.json
Step 3/7 extract GO ids and FDR from /tmp/gene_ontology_analysis.txt
Step 4/7 REVIGO reduction => /tmp/gene_ontology_analysis_revigo.csv
request...
export result
Step 5/7 Formating /Users/cecile/Downloads/output_curated_gene_ontology.tsv: filter panther result with revigo result
Step 6/7 keep track of GO ids hierarchy from /tmp/gene_ontology_analysis.json into /Users/cecile/Downloads/output_go_ids_hierarchy.tsv
Step 7/7 cleanup: remove temporay files from /tmp
```

:warning: Access to REVIGO (step 4/7) can be long, even too long. If the script exit with an error of type: "request.Error POSTing http://revigo.irb.hr/QueryJobStatus.aspx: read timeout...", re-start the same command as often as necessary.  

# Graphical representation of the results

The 2 scripts `script_1plot.R` and `script_2plot.R` allows to plot respectively one graph or 2 graph in the same figure.

The third script  `script_1plot_hierarchy.R` take into account the hierarchical informations.

The scripts can be executed in R-studio. All scripts check package requirement and install only the missing ones.

Comments in the scripts explain each step.

At the end of the scripts, the command :

```R
InfoSession <- devtools::session_info()

# Save session file
 write.table(InfoSession, file = "InfoSession.txt", 
                quote = FALSE, row.names = FALSE, sep = '\t')
```

Allows you to keep information about R session (version of R, R-studio, packages...) to comply with FAIR analysis guide line.

## Citations

PANTHER

>  PANTHER version 16: a revised family classification, tree-based classification tool, enhancer regions and extensive API
>  Huaiyu Mi, Dustin Ebert, Anushya Muruganujan, Caitlin Mills, Laurent-Philippe Albou, Tremayne Mushayamaha and Paul D Thomas . *Nucl. Acids Res. (2020) doi: 10.1093/nar/gkaa1106s.*

REVIGO

> Supek F, Bošnjak M, Škunca N, Šmuc T. "*REVIGO summarizes and visualizes long lists of Gene Ontology terms"* 
> PLoS ONE 2011. [doi:10.1371/journal.pone.0021800](http://dx.doi.org/10.1371/journal.pone.0021800)

Script R

> A Simple Protocol for Informative Visualization of Enriched Gene Ontology Terms. T. Bonnot, MB. Gillard and DH. Nagel. Bio-101: e3429. DOI:10.21769/BioProtoc.3429

R Packages

> R Core Team. 2020. *R: A Language and Environment for Statistical Computing*. Vienna, Austria: R Foundation for Statistical Computing. https://www.R-project.org/.

> Wickham, Hadley. 2016. *Ggplot2: Elegant Graphics for Data Analysis*. Springer-Verlag New York. https://ggplot2.tidyverse.org.

> Wickham, Hadley, Jim Hester, and Winston Chang. 2021. *Devtools: Tools to Make Developing r Packages Easier*. https://CRAN.R-project.org/package=devtools.

> Wilke, Claus O. 2020. *Cowplot: Streamlined Plot Theme and Plot Annotations for ’Ggplot2’*. https://CRAN.R-project.org/package=cowplot.

Script `prepare_gene_onthology.pl`

> Terese M. et Lecampion C. https://github.com/cecile-lecampion/gene-ontology-analysis-and-graph

 

​    