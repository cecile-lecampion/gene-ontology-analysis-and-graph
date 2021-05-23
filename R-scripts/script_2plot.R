#################################
# Plot gene ontology enrichment #
#################################
# Script permettant de grouper 2 graphs de gene ontology enrichment en forçant les zones de traçages à avoir la même largeur

# Installation des package si nécessaire
if (!requireNamespace("ggplot2", quietly = TRUE))
  install.packages("ggplot2")
if (!requireNamespace("cowplot", quietly = TRUE))
  install.packages("cowplot")

# Requires the package 'ggplot2' (needs to be installed first)
# Load the ggplot2 package
library(ggplot2)
library(cowplot)

# set the working directory where the tables to use are located
setwd("PATH/TO/data")

# Charger les données pour les up et le down
GO_up <- read.table("output_curated_gene_ontology_up.tsv",header=T,stringsAsFactors = T)		
GO_down <- read.table("output_curated_gene_ontology_down.tsv",header=T,stringsAsFactors = T)		


# Commande à exécuter si on ne veut utiliser que les premieres lignes de données, les plus 
#significatives avec tri par FDR croissant.
GO_up <- GO_up[1:20,]		#crée un nouveau tableau de données avec les lignes 1 à 20 de GO_up et toutes les colonnes
GO_down <- GO_down[1:20,]		#crée un nouveau tableau de données avec les lignes 1 à 20 de GO_down et toutes les colonnes
# On peut modifier le nombre de lignes en remplaçant 20 par la valeur souhaité

#Préparation des données up
# List objects and their structure contained in the dataframe 'GO_all'
ls.str(GO_up)

# Transform the column 'Gene_number' into a numeric variable
GO_up$Gene_number <- as.numeric(GO_up$Gene_number)

# Replace all the "_" by a space in the column containing the GO terms
GO_up$GO_id <- chartr("_", " ", GO_up$GO_id)

# Transform FDR values by -log10('FDR values')
GO_up$'|log10(FDR)|' <- -(log10(GO_up$FDR))

# Créer un graph sans l'afficher
#--------------------------------------
up <- ggplot(GO_up, aes(x = GO_id, y = Fold_enrichment)) +
  geom_hline(yintercept = 1, linetype="dashed", 
             color = "azure4", size=.5)+
  geom_point(data=GO_up, aes(x=GO_id, y=Fold_enrichment, 
                             size = Gene_number, colour = `|log10(FDR)|`), alpha=.7)+
  scale_y_continuous(limits = c(0,15))+
  scale_x_discrete(limits= GO_up$GO_id)+
  scale_color_gradient(low="green", high="red", limits=c(0, NA))+
  coord_flip()+
  theme_bw()+
  theme(axis.ticks.length=unit(-0.1, "cm"),
        axis.text.x = element_text(margin=margin(5,5,0,5,"pt")),
        axis.text.y = element_text(margin=margin(5,5,5,0,"pt")),
        axis.text = element_text(color = "black"),
        panel.grid.minor = element_blank(),
        legend.title.align=0.5)+
  xlab("")+
  ylab("Fold enrichment")+
  ggtitle("UP")+
  labs(color="-log10(FDR)", size="Number\nof genes")+ #Replace by your variable names; \n allow a new line for text
  guides(size = guide_legend(order=2),
         colour = guide_colourbar(order=1))

#Préparation des données down
# List objects and their structure contained in the dataframe 'GO_all'
ls.str(GO_down)

# Transform the column 'Gene_number' into a numeric variable
GO_down$Gene_number <- as.numeric(GO_down$Gene_number)

# Replace all the "_" by a space in the column containing the GO terms
GO_down$GO_id <- chartr("_", " ", GO_down$GO_id)

# Transform FDR values by -log10('FDR values')
GO_down$'|log10(FDR)|' <- -(log10(GO_down$FDR))

# Créer un graph sans l'afficher
#--------------------------------------
down <- ggplot(GO_down, aes(x = GO_id, y = Fold_enrichment)) +
  geom_hline(yintercept = 1, linetype="dashed", 
             color = "azure4", size=.5)+
  geom_point(data=GO_down, aes(x=GO_id, y=Fold_enrichment, 
                               size = Gene_number, colour = `|log10(FDR)|`), alpha=.7)+
  scale_y_continuous(limits = c(0,15))+
  scale_x_discrete(limits= GO_down$GO_id)+
  scale_color_gradient(low="green", high="red", limits=c(0, NA))+
  coord_flip()+
  theme_bw()+
  theme(axis.ticks.length=unit(-0.1, "cm"),
        axis.text.x = element_text(margin=margin(5,5,0,5,"pt")),
        axis.text.y = element_text(margin=margin(5,5,5,0,"pt")),
        axis.text = element_text(color = "black"),
        panel.grid.minor = element_blank(),
        legend.title.align=0.5)+
  xlab("")+
  ylab("Fold enrichment")+
  ggtitle("DOWN")+
  labs(color="-log10(FDR)", size="Number\nof genes")+ #Replace by your variable names; \n allow a new line for text
  guides(size = guide_legend(order=2),
         colour = guide_colourbar(order=1))

# Combiner les deux graph en une seule figure de manière à avoir la même taille pour la zone de traçage,
#indépendement des etiquettes de données

cowplot::plot_grid(up, down, ncol = 1, align = "v")
