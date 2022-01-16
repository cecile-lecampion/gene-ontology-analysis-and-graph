#!/usr/bin/env perl
use strict;
use utf8;
use IO::Handle;
use Getopt::Long qw(:config no_ignore_case bundling auto_version);
use Pod::Usage;

#================================================================================
# Constants
#================================================================================
our $VERSION = '1.1';
our $pantherUrl = 'http://go.pantherdb.org/webservices/go/overrep.jsp';
our $revigoUrl = 'http://revigo.irb.hr';

# Fichiers temporaires
my $tmpDir = $ENV{'TEMP'};
$tmpDir = '/tmp' unless $tmpDir ne '';
our $tmpGeneOntologyFileName = "$tmpDir/gene_ontology_analysis.txt";
our $tmpGoFdrFileName = "$tmpDir/gene_ontology_analysis_go_fdr.txt";
our $tmpRevigoFileName = "$tmpDir/gene_ontology_analysis_revigo.csv";
our %hMethods = ( 'biological_process' => 1, 'cellular_component' => 2, 'molecular_function' => 3 );

#================================================================================
# Globals
#================================================================================
our $optionMethod = 'biological_process';
our $optionCorrection = 'fdr';
our $man = 0;
our $help = 0;
our $optionVersion = 0;


#================================================================================
# Functions
#================================================================================

#--------------------------------------------------------------------------------
# Supprime les fichiers temporaires
#--------------------------------------------------------------------------------
sub cleanUp {
    unlink $tmpGeneOntologyFileName, $tmpGoFdrFileName, $tmpRevigoFileName;
}


#--------------------------------------------------------------------------------
# Get revigo namespace ID from method
#--------------------------------------------------------------------------------
sub getNamespaceId {
    my ($method) = @_;
    return $hMethods{$method};
}


#--------------------------------------------------------------------------------
# Vérifie que les modules nécessaires sont installés
# Affiche les instructions d'installation dans le cas contraire
#--------------------------------------------------------------------------------
sub checkModules {
    eval "use WWW::Mechanize; use JSON";

    if ($@) {
        print << 'END';
Au moins un des modules Perl nécessaires n'est pas installé.
Pour utiliser ce script vous devez d'abord exécuter les commandes suivantes:

cpan App::cpanminus
cpanm WWW::Mechanize
cpanm JSON
END
        exit 1;
    }

    use WWW::Mechanize;
}


#--------------------------------------------------------------------------------
# Extrait la liste de gènes du fichier input
# In: input_gene_list.tsv
# Out: return string: one gene ID per line
#--------------------------------------------------------------------------------
sub extractGeneIdsFormFile {
    my ($inFileName) = @_;
    
    # Hash des gene ID pour supprimer les doublons
    my %hGeneIdList;

    # Ouvre le fichier en lecture
    open my $inFile, '<', $inFileName
        or die "Unable to read $inFileName $!";

    # Lecture de chaque ligne
    while (<$inFile>) {
        # Place les gene IDs de la 1ère colonne, forcés en majuscule, dans le hash
        $hGeneIdList{uc $1}++ if /^(AT[^.\s]+)/i;
    }
    # Ferme le fichier
    close $inFile;

    # Retourne la liste de gene ID séparés par des saut de ligne
    return join "\n", keys %hGeneIdList;
}


#--------------------------------------------------------------------------------
# Analyse d'ontologie
# In: string containing the gene ID, one per line
#--------------------------------------------------------------------------------
sub panther {
    my ($inGeneIdList, $outGeneOntologyFileName) = @_;

    # initialisation du browser web
    my $browser = WWW::Mechanize->new();

    # Requête panther
    print "request...\n";
    my $response = $browser->post( $pantherUrl, [
                                        'input'  => $inGeneIdList,
                                        'species' => 'ARATH',
                                        'ontology' => $optionMethod,
                                        'correction' => $optionCorrection
                                    ],
                                 );
    die "Error: ", $response->status_line
        unless $response->is_success;

    # Export du résultat (bouton "Table")
    print "export result\n";
    my $response = $browser->follow_link( text => 'Table', n => 1 );
    die "Error: ", $response->status_line
        unless $response->is_success;

    # Sauvegarde du résultat (fichier analysis.txt)
    $browser->save_content($outGeneOntologyFileName);
}


#--------------------------------------------------------------------------------
# Extrait du fichier $inGeneOntologyFileName l'identifiants GO:xxxxxxx de la 1ère colonne et la 8ème colonne: FDR 
# Out: $outGoFdrFileName
#--------------------------------------------------------------------------------
sub extractGoAndFdr {
    my ($inGeneOntologyFileName, $outGoFdrFileName) = @_;

    # Ouvre les fichiers
    open my $inFile, '<', $inGeneOntologyFileName
        or die "Unable to read $inGeneOntologyFileName $!";
    open my $outFile, '>', $outGoFdrFileName
        or die "Unable to create $outGoFdrFileName $!";

    # Lecture de chaque ligne
    while (<$inFile>) {
        # Découpe les champs sur la tabulation
        my @F = split /[\t\r\n]/;
        # Extraction
        if ($F[0] =~/\((GO:\d+)\)$/) {
            my $G = $1;
            print $outFile "$G\t$F[7]\n";
        }
    }
    # Ferme les fichiers
    close $inFile;
    close $outFile;
}


#--------------------------------------------------------------------------------
# filter panther result with revigo result
#--------------------------------------------------------------------------------
sub filterPantherWithRevigo {
    my ($inGeneOntologyFileName, $inRevigoFileName, $outCuratedGeneOntology) = @_;

    # Ouvre le fichier inRevigoFileName
    open my $inFile, '<', $inRevigoFileName
        or die "Unable to read $inRevigoFileName $!";

    # hash de filtrage
    my %hRevigoGO;

    # Lecture de chaque ligne inRevigoFileName
    while (<$inFile>) {
        # Extrait les id GO:xxxxx
        if (/^"(GO:\d+)"/) {
            # Place les id GO dans le hash de filtrage
            $hRevigoGO{$1}++
        }
    }

    # Ferme le fichier
    close $inFile;


    # Ouvre le fichier inGeneOntologyFileName
    open $inFile, '<', $inGeneOntologyFileName
        or die "Unable to read $inGeneOntologyFileName $!";

    # Tableau de sotckage du résultat. La clef sera le FDR pour pouvoir trier facilement fichier de sortie sur le FDR
    my @aOut;

    # Lecture de chaque ligne de inGeneOntologyFileName
    while (<$inFile>) {
        # Découpe les champs sur la tabulation
        my @F = split /[\t\r\n]/;
        # Extraction des colonnes 1 (GO biological process complete), 3 (xxxx), 6 (fold Enrichment) et 8 (FDR)
        if ($F[0] =~/\((GO:\d+)\)$/) {
            my $G = $1;
            # Si le GO est présent dans le hash de filtrage
            if ( $hRevigoGO{$G} ) {
                
                my $cleanedCol1 = $F[0];
                # Remplace les espaces par des _ dans la colonne 1
                $cleanedCol1 =~ s/ /_/g;
                # Supprime les quotes simples et doubles dans la colonne 1
                $cleanedCol1 =~ s/['"]//g;

                # Clean des valeurs de type "< 0.01"i ou "> 100" dans le fold Enrichment
                my $foldEnrichment = ($F[5] =~ /^\s*[<>]\s*(.+)/) ? $1 : $F[5];

                # Stocke le résultat dans @aOut sous la forme d'une référence de tableau
                # contenant la colonne FDR spéparée des autres colonnes afin de pouvoir trier
                # sur la colonne FDR
                push @aOut, [$F[7], "$cleanedCol1\t$F[2]\t$foldEnrichment"]
            }
        }
    }

    # Ferme le fichier
    close $inFile;

    # Ouvre le fichier de sortie
    open my $outFile, '>', $outCuratedGeneOntology
        or die "Unable to create $outCuratedGeneOntology $!";

    # Affiche l'entête du fichier de sortie
    print $outFile "GO_id\tGene_number\tFold_enrichment\tFDR\n";

    # Trie le tableau de résultat sur la colonne FDR par ordre numérique croissant
    for (sort { $a->[0] <=> $b->[0] } @aOut) {
        # Ecrit la ligne dans le fichier de sortie
        print $outFile $_->[1], "\t", $_->[0], "\n";
    }

    close $outFile;
}


#--------------------------------------------------------------------------------
# REVIGO reduction
# in: $tmpGeneOntologyFileName
# out: $tmpGoFdrFileName
#--------------------------------------------------------------------------------
sub revigoReduction {
    my ($tmpGoFdrFileName, $tmpRevigoFileName) = @_;

    # Read input file content
    my $inFileContent = do {
            open my $fh, '<', $tmpGoFdrFileName
                or die "$tmpGoFdrFileName $!\n";
            local $/;
            <$fh>;
        };

    # initialisation du browser web
    my $browser = WWW::Mechanize->new();

    # Submit job to Revigo
    print "request";
    my $response = $browser->post( "$revigoUrl/StartJob.aspx", [
                                        'cutoff' => '0.7',
                                        'valueType' => 'pvalue',
                                        'speciesTaxon' => '0',
                                        'measure' => 'SIMREL',
                                        'goList' => $inFileContent
                                    ],
                                 );
    die "Error: ", $response->status_line
        unless $response->is_success;

    my $jobId = decode_json($response->decoded_content)->{'jobid'};

    # Disable stdout buffering
    STDOUT->autoflush(1);

    # Check job status
    my $isRunning = 1;
    while ($isRunning != 0) {
        my $response = $browser->post( "$revigoUrl/QueryJobStatus.aspx", [ 'jobid' => $jobId ]);
        die "Error: ", $response->status_line
            unless $response->is_success;

        $isRunning = decode_json($response->decoded_content)->{'running'};

        print '.';
        sleep(1);
    }
    print("\nexport result\n");

    STDOUT->autoflush(0);

    # Fetch results
    $response = $browser->post( "$revigoUrl/ExportJob.aspx",
                                [ 'jobid' => $jobId,
                                  'type' => 'csvtable',
                                  'namespace' => getNamespaceId($optionMethod)
                                ]
                              );
    die "Error: ", $response->status_line
        unless $response->is_success;

    # Write results to file
    $browser->save_content($tmpRevigoFileName);
}


#--------------------------------------------------------------------------------
#--------------------------------------------------------------------------------
sub printVersion {
    print "prepare_gene_onthology.pl version $VERSION\n";
    exit 0
}


#--------------------------------------------------------------------------------
#--------------------------------------------------------------------------------
sub checkParams {
    GetOptions('h|help' => \$help, man => \$man,
            'm|method=s' => \$optionMethod,
            'c|correction=s' => \$optionCorrection,
            'version' => \$optionVersion) or pod2usage(2);

    printVersion() if $optionVersion;
    pod2usage(1) if $help;
    pod2usage(-exitval => 0, -verbose => 2) if $man;

    pod2usage(2) unless @ARGV == 2;
    die "Unable to read file $ARGV[0]\n"
        unless -r $ARGV[0];
    die "Invalid method: $optionMethod\nAvailable methods are:\n\t" . join("\n\t", keys %hMethods) . "\n"
        unless defined getNamespaceId($optionMethod);
    die "Invalid correction $optionCorrection\nAvailable corrections are:\n\tfdr\n\tbonferroni\n"
        unless $optionCorrection =~ /^(fdr|bonferroni)$/;
}


#================================================================================
# Main
#================================================================================
checkModules();
checkParams();

# Extrait la liste de gènes du fichier input
print "Step 1/6 Extract gene ID list from $ARGV[0]\n";
my $geneIdList = extractGeneIdsFormFile($ARGV[0]);

# Analyse d'ontologie, résultat dans le fichier temporaire $tmpGeneOntologyFileName
print "Step 2/6 Panther ontology analysis => $tmpGeneOntologyFileName\n";
panther($geneIdList, $tmpGeneOntologyFileName);

# Récupération des identifiants GO:xxxxxxx et du FDR dans le fichier $tmpGeneOntologyFileName
print "Step 3/6 extract GO ids and FDR from $tmpGeneOntologyFileName\n";
extractGoAndFdr($tmpGeneOntologyFileName, $tmpGoFdrFileName);

print "Step 4/6 REVIGO reduction => $tmpRevigoFileName\n";
revigoReduction($tmpGoFdrFileName, $tmpRevigoFileName);

# Formatage du résultat
my $outResult = $ARGV[1];
print "Step 5/6 Formating $outResult: filter panther result with revigo result\n";
filterPantherWithRevigo($tmpGeneOntologyFileName, $tmpRevigoFileName, $outResult);

print "Step 6/6 cleanup: remove temporay files from $tmpDir\n";
cleanUp();

#================================================================================
# POD
#================================================================================
__END__

=head1 NAME

prepare_gene_onthology.pl

=head1 SYNOPSIS

syntax:

prepare_gene_onthology.pl [--help|--man|--version]

or

prepare_gene_onthology.pl [-m|--method] [-c|--correction] B<input_gene_list.tsv> B<output_curated_gene_ontology.tsv>

=head1 OPTIONS

=over 4

=item B<-m|--method>

If specified, use this method.

Available methods:

    biological_process (default)
    cellular_component
    molecular_function

=item B<-c|--correction>

If specified, use this correction.

Available corrections:

    fdr (default)
    bonferroni

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

Réalise l'analyse de gene ontology avec PANTHER et REVIGO à partir d'une liste de gene ID.
Mets en forme le résultat pour être utilisable par le script xxxxxxx.R

Seule la 1ère colonne du fichier input_gene_list.tsv est prise en compte.
Cette colonne peut contenir des noms de gene ou bien de transcrits (ATxxxxxx.1, ATxxxxxx.2, ...).
Les n° de transcrit sont ignorés.

=head1 EXAMPLES

=head2 Avec les paramètres par défaut: biological_process et FDR

    prepare_gene_onthology.pl mon_fichier.tsv fichier_resultat.tsv

=head2 En spécifiant le process et la correction

    prepare_gene_onthology.pl --method molecular_function --correction fdr mon_fichier.tsv fichier_resultat.tsv

