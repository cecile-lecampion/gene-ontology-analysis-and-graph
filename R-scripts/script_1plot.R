#################################
# Plot gene ontology enrichment #
#################################

# Packages installation (only if necessary)
if (!require(ggplot2)) { install.packages("ggplot2") }
if (!require(devtools)) { install.packages("devtools") }

# Load the ggplot2 package
library(ggplot2)

# set the working directory where the tables to use are located
setwd("PATH/TO/data")

#############################################
# plot the representative enriched
# GO terms in the list of all DEGs (Figure 2)
#############################################

# Prepare dataframe
#------------------
# Import the table containing the enriched GO terms
GO_all <- read.table("out.tsv",header=T,stringsAsFactors = T)


# If you only want to use the n first line of the data frame for the plot, execute this command
# If you want to keep all lines just skip this  
#Data in the input file are sorted in ascending FDR.

GO_all <- GO_all[1:20,]		#Replace the data frame by a new data frame that only contains the 20 first lines of GO_all 
                            # and all columns
                            # You can select any number of lines to be used by replacing 20 by the desired value

# List objects and their structure contained in the dataframe 'GO_all'
ls.str(GO_all)

# Transform the column 'Gene_number' into a numeric variable
GO_all$Gene_number <- as.numeric(GO_all$Gene_number)

# Replace all the "_" by a space in the column containing the GO terms
GO_all$GO_id <- chartr("_", " ", GO_all$GO_id)

# Transform FDR values by -log10('FDR values')
GO_all$'|log10(FDR)|' <- -(log10(GO_all$FDR))

# Draw the plot with ggplot2 
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


# R session
#--------------------------------------
InfoSession <- devtools::session_info()

# save session file
write.table(InfoSession, file = "InfoSession.txt", 
            quote = FALSE, row.names = FALSE, sep = '\t')
