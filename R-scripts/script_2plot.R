#################################
# Plot gene ontology enrichment #
# Plot 2 set of data in the same figure
# As an exemple the script is written to use over (up) and under (down) expressed genes from a RNAseq analysis
#################################

# Packages installation (only if necessary)
if (!requireNamespace("ggplot2", quietly = TRUE))
  install.packages("ggplot2")
if (!requireNamespace("cowplot", quietly = TRUE))
  install.packages("cowplot")
if (!require(devtools)) { install.packages("devtools") }

# Load the ggplot2 and cowplot packages
library(ggplot2)
library(cowplot)

# set the working directory where the tables to use are located
setwd("PATH/TO/data")

# Load up and down data
GO_up <- read.table("output_curated_gene_ontology_up.tsv",header=T,stringsAsFactors = T)		
GO_down <- read.table("output_curated_gene_ontology_down.tsv",header=T,stringsAsFactors = T)		


# If you only want to use the n first line of the data frame for the plot, execute this command
# If you want to keep all lines just skip this  
#Data in the input file are sorted in ascending FDR.
GO_up <- GO_up[1:20,]		#Replace the data frame by a new data frame that only contains the 20 first lines of GO_all 
                        # and all columns
                        # You can select any number of lines to be used by replacing 20 by the desired value

GO_down <- GO_down[1:20,]		#Replace the data frame by a new data frame that only contains the 20 first lines of GO_all 
                            # and all columns
                            # You can select any number of lines to be used by replacing 20 by the desired value


#Preparation of the up data
# List objects and their structure contained in the dataframe 'GO_all'
ls.str(GO_up)

# Transform the column 'Gene_number' into a numeric variable
GO_up$Gene_number <- as.numeric(GO_up$Gene_number)

# Replace all the "_" by a space in the column containing the GO terms
GO_up$GO_id <- chartr("_", " ", GO_up$GO_id)

# Transform FDR values by -log10('FDR values')
GO_up$'|log10(FDR)|' <- -(log10(GO_up$FDR))

# Create the graph into a variable
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

#Preparation of the down data
# List objects and their structure contained in the dataframe 'GO_all'
ls.str(GO_down)

# Transform the column 'Gene_number' into a numeric variable
GO_down$Gene_number <- as.numeric(GO_down$Gene_number)

# Replace all the "_" by a space in the column containing the GO terms
GO_down$GO_id <- chartr("_", " ", GO_down$GO_id)

# Transform FDR values by -log10('FDR values')
GO_down$'|log10(FDR)|' <- -(log10(GO_down$FDR))

# Create the graph into a variable
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

# Combine the 2 graphs

cowplot::plot_grid(up, down, ncol = 1, align = "v")



# R session
#--------------------------------------
InfoSession <- devtools::session_info()

# save session file
write.table(InfoSession, file = "InfoSession.txt", 
            quote = FALSE, row.names = FALSE, sep = '\t')