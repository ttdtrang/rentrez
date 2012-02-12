#' Search the NCBI's entrez database
#'
#'
#'
#'
#'
#'
#'
#'name

entrez_search <- function(db, term, ... ){
    args <- c(db=db, term=term, email=entrez_email, tool=entrez_tool, ...)
    url_args <- paste(paste(names(args), args, sep="="), collapse="&")
    base_url <- "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?"
    search <- paste(base_url, url_args, sep="&")
    xml_result <- xmlParse(getURL(search))
    ids <- unlist(getNodeSet(xml_result, "//Id", fun=xmlValue))
    count <- unlist(getNodeSet(xml_result, "/eSearchResult/Count", fun=xmlValue))
    retmax <- unlist(getNodeSet(xml_result, "/eSearchResult/RetMax", fun=xmlValue))
    return(list(file=xml_result, ids=as.integer(ids), 
                count=as.integer(count), 
                retmax=as.integer(retmax)
            ))
}