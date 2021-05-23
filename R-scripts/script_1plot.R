#################################
# Plot gene ontology enrichment #
#################################

# Requires the package 'ggplot2' (needs to be installed first)
if (!requireNamespace("ggplot2", quietly = TRUE))
    install.packages("ggplot2")

# Load the ggplot2 package
library(ggplot2)

# set the working directory where the tables to use are located
setwd("PATH/TO/data")

#############################################
# PART 1: plot the representative enriched
# GO terms in the list of all DEGs (Figure 2)
#############################################

# Prepare dataframe
#------------------
# Import the table containing the enriched GO terms
GO_all <- read.table("out.tsv",header=T,stringsAsFactors = T)


# Commande à exécuter si on ne veut utiliser que le spremieres lignes de données, les plus 
#significatives avec tri par FDR croissant.

GO_all <- GO_all[1:20,]		#crée un nouveau tableau de données avec les lignes 1 à 20 de GO_all et toutes les colonnes
# On peut modifier le nombre de lignes en remplaçant 20 par la valeur souhaité

# List objects and their structure contained in the dataframe 'GO_all'
ls.str(GO_all)

# Transform the column 'Gene_number' into a numeric variable
GO_all$Gene_number <- as.numeric(GO_all$Gene_number)

# Replace all the "_" by a space in the column containing the GO terms
GO_all$GO_id <- chartr("_", " ", GO_all$GO_id)

# Transform FDR values by -log10('FDR values')
GO_all$'|log10(FDR)|' <- -(log10(GO_all$FDR))

# Draw the plot with ggplot2 (Figure 2)
#--------------------------------------
ggplot(GO_all, aes(x = GO_id, y = Fold_enrichment)) +
    geom_hline(yintercept = 1, linetype="dashed", 
               color = "azure4", size=.5)+
    geom_point(data=GO_all, aes(x=GO_id, y=Fold_enrichment, 
                                size = Gene_number, colour = `|log10(FDR)|`), alpha=.7)+
    #scale_y_continuous(limits = c(0,15))+
    scale_x_discrete(limits= GO_all$GO_id)+
    scale_color_gradient(low="green", high="red", limits=c(0, NA))+
    coord_flip()+
    theme_bw()+
    theme(axis.ticks.length=unit(-0.1, "cm"),
          axis.text.x = element_text(margin=margin(5,5,0,5,"pt")),
          axis.text.y = element_text(margin=margin(5,5,5,5,"pt")),
          axis.text = element_text(color = "black"),
          panel.grid.minor = element_blank(),
          legend.title.align=0.5)+
    xlab("GO ID")+
    ylab("Fold enrichment")+
    labs(color="-log10(FDR)", size="Number\nof genes")+ #Replace by your variable names; \n allow a new line for text
    guides(size = guide_legend(order=2),
           colour = guide_colourbar(order=1))

