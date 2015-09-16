---
output:
  md_document:
    variant: markdown_github
---

<!-- README.md is generated from README.Rmd. Please edit that file -->



[![Build Status](https://travis-ci.org/ropensci/rentrez.png)](https://travis-ci.org/ropensci/rentrez)
[![Build status](https://ci.appveyor.com/api/projects/status/y8mq2v4mpgou8rhp/branch/master)](https://ci.appveyor.com/project/sckott/rentrez/branch/master)
[![Coverage Status](https://coveralls.io/repos/ropensci/rentrez/badge.svg?branch=master)](https://coveralls.io/r/ropensci/rentrez?branch=master)

#rentrez

`rentrez` provides functions that work with the [NCBI Eutils](http://www.ncbi.nlm.nih.gov/books/NBK25500/)
API to search, download data from, and otherwise interact with NCBI databases.


##Install

`rentrez` is on CRAN, so you can get the latest stable release with `install.packages("rentrez")`. This repository will sometimes be a little ahead of the CRAN version, if you want the latest (and possibly greatest) version you can install
the current github version using Hadley Wickham's [devtools](https://github.com/hadley/devtools).

```
library(devtools)
install_github("ropensci/rentrez")
```

##Get help
Hopefully this README, and the package's vignette and in-line documentation,
, provide you with enough information to get started with `rentrez`. If you need
more help, or if discover a bug in `rentrez` please let us know, either through
one of the [contact methods described here](http://ropensci.org/contact.html),
or [by filing an issue](https://github.com/ropensci/rentrez/issues)


##The EUtils API

Each of the functions exported by `rentrez` is documented, and this README and
the package vignette provide examples of how to use the functions together as part
of a workflow. The API itself is [well-documented](http://www.ncbi.nlm.nih.gov/books/NBK25500/).
Be sure to read the official documentation to get the most out of API. In particular, be aware of the NCBI's usage
policies and try to limit very large requests to off peak (USA) times (`rentrez`
takes care of limiting the number of requests per second, and setting the
appropriate entrez tool name in each request).

See [getting information about NCBI databases](#getting-information-about-ncbi-databases)


##Examples

In many cases, doing something interesting with `EUtils` will take multiple
calls. Here are a few examples of how the functions work together (check out the
package vignette for others).

###Getting data from that great paper you've just read

Let's say I've just read a paper on the evolution of Hox genes,
[Di-Poi _et al_. (2010)](dx.doi.org/10.1038/nature08789), and I want to get the
data required to replicate their results. First, I need the unique ID for this
paper in pubmed (the PMID). Annoyingly, many journals don't give PMIDS for their
papers, but we can use `entrez_search` to find the paper using the doi field:


```r
library(rentrez)
hox_paper <- entrez_search(db="pubmed", term="10.1038/nature08789[doi]")
(hox_pmid <- hox_paper$ids)
# [1] "20203609"
```

Now, what sorts of data are available from other NCBI database for this paper?


```r
hox_data <- entrez_link(db="all", id=hox_pmid, dbfrom="pubmed")
hox_data
# elink object with contents:
#  $links: IDs for linked records from NCBI
# 
```

Each of the character vectors in this object contain unique IDS for records in
the named databases. These functions try to make the most useful bits of the
returned files available to users, but they also return the original file in case
you want to dive into the XML yourself.

In this case we'll get the protein sequences as genbank files, using '
`entrez_fetch`:


```r
hox_proteins <- entrez_fetch(db="protein", id=hox_data$pubmed_protein, rettype="gb")
# Error: Must specify either (not both) 'id' or web history arguments 'WebEnv' and 'query_key'
```

###Retrieving datasets associated a particular organism.

I like spiders. So let's say I want to learn a little more about New Zealand's
endemic "black widow" the katipo. Specifically, in the past the katipo has
been split into two species, can we make a phylogeny to test this idea?

The first step here is to use the function `entrez_search` to find datasets
that include katipo sequences. The `popset` database has sequences arising from
phylogenetic or population-level studies, so let's start there.


```r
library(rentrez)
katipo_search <- entrez_search(db="popset", term="Latrodectus katipo[Organism]")
katipo_search$count
# [1] 6
```

In this search `count` is the total number of hits returned for the search term.
We can use `entrez_summary` to learn a little about these datasets. `rentrez`
will parse this xml into a list of `esummary` records, with each list entry
corresponding to one of the IDs it is passed. In this case we get six records,
and we see what each one contains like so:



```r
summaries <- entrez_summary(db="popset", id=katipo_search$ids)
summaries[[1]]
# esummary result with 17 items:
#  [1] uid        caption    title      extra      gi         settype   
#  [7] createdate updatedate flags      taxid      authors    article   
# [13] journal    strain     statistics properties oslt
sapply(summaries, "[[", "title")
#                                                                                                                                                                                                                  167843272 
# "Latrodectus katipo 18S ribosomal RNA gene, partial sequence; internal transcribed spacer 1, 5.8S ribosomal RNA gene, and internal transcribed spacer 2, complete sequence; and 28S ribosomal RNA gene, partial sequence." 
#                                                                                                                                                                                                                  167843256 
#                                                                                                                                  "Latrodectus katipo cytochrome oxidase subunit 1 (COI) gene, partial cds; mitochondrial." 
#                                                                                                                                                                                                                  145206810 
#        "Latrodectus 18S ribosomal RNA gene, partial sequence; internal transcribed spacer 1, 5.8S ribosomal RNA gene, and internal transcribed spacer 2, complete sequence; and 28S ribosomal RNA gene, partial sequence." 
#                                                                                                                                                                                                                  145206746 
#                                                                                                                                         "Latrodectus cytochrome oxidase subunit 1 (COI) gene, partial cds; mitochondrial." 
#                                                                                                                                                                                                                   41350664 
#                                                                                             "Latrodectus tRNA-Leu (trnL) gene, partial sequence; and NADH dehydrogenase subunit 1 (ND1) gene, partial cds; mitochondrial." 
#                                                                                                                                                                                                                   39980346 
#                                                                                                                                         "Theridiidae cytochrome oxidase subunit I (COI) gene, partial cds; mitochondrial."
```

Let's just get the two mitochondrial loci (COI and trnL), using `entrez_fetch`:


```r
COI_ids <- katipo_search$ids[c(2,6)]
trnL_ids <- katipo_search$ids[5]
COI <- entrez_fetch(db="popset", id=COI_ids, rettype="fasta")
trnL <- entrez_fetch(db="popset", id=trnL_ids, rettype="fasta")
```

The "fetched" results are fasta formatted characters, which can be written
to disk easily:

```r
write(COI, "Test/COI.fasta")
write(trnL, "Test/trnL.fasta")
```

Once you've got the sequences you can do what you want with them, but I wanted
a phylogeny so let's do that with ape:

```r
library(ape)
coi <- read.dna("Test/COI.fasta", "fasta")
coi_aligned <- clustal(coi)
tree <- nj(dist.dna(coi_aligned))
```

###Making use of `httr` configuration options


As of version 0.3, rentrez uses [httr](https://github.com/hadley/httr) to manage
calls to the Eutils API. This allows users to take advantage of some of `httr`'s
configuration options.

Any `rentrez` function that interacts with the Eutils api will
pass the value of the argument `config` along to `httr`'s  `GET` function. For
instance, if you access the internet through a proxy you use the `httr` function
`use_proxy()` to provide connection details to an entrez call:

```r
entrez_search(db="pubmed",
              term="10.1038/nature08789[doi]",
              config=use_proxy("0.0.0.0", port=80,username="user", password="****")
```

Other options include `verbose()` which prints a detailed account of what's
going on during a request, `timeout()` which sets the number of seconds to wait
for a response before giving up, and, in the development version of `httr`,
`progress()` which prints a progress bar to screen.

`rentrez` functions will also be effected by the global `httr` configuration set by
`httr::set_config()`. For example, it's possible to have all calls to Eutils
pass through a proxy and produce verbose output

```r
httr::set_config(use_proxy("0.0.0.0", port=80,username="user", password="****"),
                 verbose() )
entrez_search(db="pubmed",  term="10.1038/nature08789[doi]")
```



### WebEnv and big queries

The NCBI provides search history features, which can be useful for dealing with large lists of IDs (which will not fit in a single URL) or repeated searches. As an example, we will go searching for COI sequences from all the snail (Gastropod) species we can find in the nucleotide database:


```r
snail_search <- entrez_search(db="nuccore", "Gastropoda[Organism] AND COI[Gene]", retmax=200, usehistory="y")
```

Because we set usehistory to "y" the `snail_search` object contains a unique ID for the search (`WebEnv`) and the particular query in that search history (`QueryKey`). Instead of using the 200 ids we turned up to make a new URL and fetch the sequences we can use the webhistory features.


```r
cookie <- snail_search$WebEnv
qk <- snail_search$QueryKey
snail_coi <- entrez_fetch(db="nuccore", WebEnv=cookie, query_key=qk, rettype="fasta", retmax=10)
# Error: Must specify either (not both) 'id' or web history arguments 'WebEnv' and 'query_key'
```

###Getting information about NCBI databases

Most of the examples above required some background information about what
databases NCBI has to offer, and how they can be searched. `rentrez` provides
a set of functions with names starting `entrez_db` that help you to discover
this information in an interactive session.

First up, `entrez_dbs()` gives you a list of database names



```r
entrez_dbs()
#  [1] "pubmed"          "protein"         "nuccore"        
#  [4] "nucleotide"      "nucgss"          "nucest"         
#  [7] "structure"       "genome"          "gpipe"          
# [10] "annotinfo"       "assembly"        "bioproject"     
# [13] "biosample"       "blastdbinfo"     "books"          
# [16] "cdd"             "clinvar"         "clone"          
# [19] "gap"             "gapplus"         "grasp"          
# [22] "dbvar"           "epigenomics"     "gene"           
# [25] "gds"             "geoprofiles"     "homologene"     
# [28] "medgen"          "mesh"            "ncbisearch"     
# [31] "nlmcatalog"      "omim"            "orgtrack"       
# [34] "pmc"             "popset"          "probe"          
# [37] "proteinclusters" "pcassay"         "biosystems"     
# [40] "pccompound"      "pcsubstance"     "pubmedhealth"   
# [43] "seqannot"        "snp"             "sra"            
# [46] "taxonomy"        "unigene"         "gencoll"        
# [49] "gtr"
```

Some of the names are a little opaque, so you can get some more descriptive
information about each with `entrez_db_summary()`


```r
entrez_db_summary("cdd")
#  DbName: cdd
#  MenuName: Conserved Domains
#  Description: Conserved Domain Database
#  DbBuild: Build150814-1106.1
#  Count: 50648
#  LastUpdate: 2015/08/14 18:07
```

`entrez_db_searchable()` lets you discover the fields available for search terms
for a given database. You get back a named-list, with names are fields. Each
element has additional information about each named search field (you can also
use `as.data.frame` to create a dataframe, with one search-field per row):


```r
search_fields <- entrez_db_searchable("pmc")
search_fields$GRNT
#  Name: GRNT
#  FullName: Grant Number
#  Description: NIH Grant Numbers
#  TermCount: 2216578
#  IsDate: N
#  IsNumerical: N
#  SingleToken: Y
#  Hierarchy: N
#  IsHidden: N
```

Finally, `entrez_db_links` takes a database name, and returns a list of other
NCBI databases which might contain linked-records.


```r
entrez_db_links("omim")
# Databases with linked records for database 'omim'
#  [1] biosample   biosystems  books       clinvar     dbvar      
#  [6] gene        genetests   geoprofiles gtr         homologene 
# [11] mapview     medgen      medgen      nuccore     nucest     
# [16] nucgss      omim        pcassay     pccompound  pcsubstance
# [21] pmc         protein     pubmed      pubmed      snp        
# [26] snp         snp         sra         structure   unigene
```

###Trendy topics in genetics

This is one is a little more trivial, but you can also use entrez to search pubmed and
the EUtils API allows you to limit searches by the year in which the paper was published.
That gives is a chance to find the trendiest -omics going around (this has quite a lot
of repeated searching, so it you want to run your own version be sure to do it
in off peak times).

Let's start by making a function that finds the number of records matching a given
search term for each of several years (using the `mindate` and `maxdate` terms from
the Eutils API):

```r
library(rentrez)
papers_by_year <- function(years, search_term){
            return(sapply(years, function(y) entrez_search(db="pubmed",term=search_term, mindate=y, maxdate=y, retmax=0)$count))
        }
```

With that we can fetch the data for each term and, by searching with no term,
find the total number of papers published in each year:


```r
years <- 1990:2014
total_papers <- as.numeric(papers_by_year(years, ""))
omics <- c("genomic", "epigenomic", "metagenomic", "proteomic", "transcriptomic", "pharmacogenomic", "connectomic" )
trend_data <- sapply(omics, function(t) papers_by_year(years, t))
trend_props <- as.numeric(trend_data)/total_papers
```

That's the data, let's plot it:

```r
library(reshape)
library(ggplot2)
trend_df <- melt(data.frame(years, trend_props), id.vars="years")
p <- ggplot(trend_df, aes(years, value, colour=variable))
p + geom_line(size=1) + scale_y_log10("number of papers")
```


Giving us... well this:

![](http://i.imgur.com/oSYuWqz.png)



---

This package is part of a richer suite called [fulltext](https://github.com/ropensci/fulltext), along with several other packages, that provides the ability to search for and retrieve full text of open access scholarly articles.

---

[![](http://ropensci.org/public_images/github_footer.png)](http://ropensci.org)
