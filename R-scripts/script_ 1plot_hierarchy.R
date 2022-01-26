#####################################################################
# Plot gene ontology enrichment                                     #
# Add color to link GO_id to level 0 GO_id designed as "main GO_id" #
# or "parent GO_id"                                                 #
#####################################################################

# Packages installation (only if necessary)
if (!require(ggplot2)) { install.packages("ggplot2") }
if (!require(devtools)) { install.packages("devtools") }
if (!require(RColorBrewer)) { install.packages("RColorBrewer") }

# Load the ggplot2 package
library(ggplot2)
library(RColorBrewer)

# set the working directory where the tables to use are located
setwd("PATH/TO/data")

# Load GO data
GO <- read.table("out.tsv", header=T, stringsAsFactors = T, sep = "\t")

# Load hierarchy file
hierarchy <- read.table("hierarchy.tsv", header=F, stringsAsFactors = T, sep = "\t", quote = "")
colnames(hierarchy) <- c("parent", "child")

# If you only want to use the n first line of the data frame for the plot, execute this command
# If you want to keep all lines just skip this  
#Data in the input file are sorted in ascending FDR.

GO <- GO[1:20,]		#Replace the data frame by a new data frame that only contains the 20 first lines of GO 
# and all columns
# You can select any number of lines to be used by replacing 20 by the desired value

# List objects and their structure contained in the dataframe 'GO'
ls.str(GO)

# Transform the column 'Gene_number' into a numeric variable
GO$Gene_number <- as.numeric(GO$Gene_number)

# Replace all the "_" by a space in the column containing the GO terms
GO$GO_id <- chartr("_", " ", GO$GO_id)

# Transform FDR values by -log10('FDR values')
GO$'|log10(FDR)|' <- -(log10(GO$FDR))

# Add parent GO-ID to GO
parent <- hierarchy[hierarchy$child %in% GO$GO_id, ]

# In hierarchy file, GO_id that are already level 0 don't appear so the match might not be perfect
# Merge parent and GO with all = TRUE to keep all the line of GO even if there is no match in parent
GO <- merge(GO, parent, by.x=c("GO_id"), by.y=c("child"), all = TRUE)  

# Turn the GO$parent column in character to replace NA (if they existe) by the corresponding value in column GO_id
GO$parent <- as.character(GO$parent)
# Suppress the text between the ()
GO[is.na(GO)] <- gsub("\\s*\\([^\\)]+\\)","",as.character(GO$GO_id[is.na(GO$parent)]))
# Trun the column as factor
GO$parent <- factor(GO$parent)
# Order the data frame by main GO_id
GO <- GO[order(GO$parent),]

# Prepare color for parent GO_Id assignment
numColors <- length(levels(GO$parent))
getColors <- scales::brewer_pal('qual', palette = "Paired")
myPalette <- getColors(numColors)
names(myPalette) <- levels(GO$parent)

# Draw the plot with ggplot2 
#--------------------------------------
p <- ggplot(GO, aes(x = GO_id, y = Fold_enrichment)) +
  geom_hline(yintercept = 1, linetype="dashed", 
             color = "azure4", size=.5)+
  geom_point(data=GO, aes(x=GO_id, y=Fold_enrichment, 
                          size = Gene_number, colour = `|log10(FDR)|`), alpha=.7)+
  # scale_y_continuous(limits = c(0,15))+
  scale_x_discrete(limits= GO$GO_id)+
  scale_color_gradient(low="green", high="red", limits=c(0, NA))+
  coord_flip()+
  theme_bw()+
  theme(axis.ticks.length=unit(-0.1, "cm"),
        axis.text.x = element_text(margin=margin(5,5,0,5,"pt"), color = "black"),
        axis.text.y = element_text(margin=margin(5,5,5,5,"pt"), colour=myPalette[GO$parent]),
        panel.grid.minor = element_blank(),
        legend.title.align=0.5)+
  xlab("GO ID")+
  ylab("Fold enrichment")+
  ggtitle("")+
  # Replace by your variable names; \n allow a new line for text
  labs(color="-log10(FDR)", size="Number\nof genes")+ 
  guides(size = guide_legend(order=2),
         colour = guide_colourbar(order=1))

print(p)

# Draw a NULL plot and a legend to get legend for main GO_id

plot(NULL, xlim=c(0,length(myPalette)), ylim=c(0,1), xlab="", ylab="", xaxt="n", yaxt="n", frame.plot = FALSE)
legend("center", title = sprintf("Main GO-Id"), legend = names(myPalette), 
       col = as.data.frame(myPalette)$myPalette, pch = 15, cex=1, pt.cex = 1.5)

# R session
#--------------------------------------
InfoSession <- devtools::session_info()

# save session file
write.table(InfoSession, file = "InfoSession.txt", 
            quote = FALSE, row.names = FALSE, sep = '\t')