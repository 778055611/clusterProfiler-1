
##' open KEGG pathway with web browser
##'
##'
##' @title browseKEGG
##' @param x an instance of enrichResult or gseaResult
##' @param pathID pathway ID
##' @return url
##' @importFrom utils browseURL
##' @export
##' @author Guangchuang Yu
browseKEGG <- function(x, pathID) {
    url <- paste0("https://www.kegg.jp/kegg-bin/show_pathway?", pathID, '/', x[pathID, "geneID"])
    browseURL(url)
    invisible(url)
}

##' search kegg organism, listed in https://www.genome.jp/kegg/catalog/org_list.html
##'
##'
##' @title search_kegg_organism
##' @param str string
##' @param by one of 'kegg.code', 'scientific_name' and 'common_name'
##' @param ignore.case TRUE or FALSE
##' @param use_internal_data logical, use kegg_species.rda or latest online KEGG data
##' @return data.frame
##' @export
##' @author Guangchuang Yu
search_kegg_organism <- function(str, by="scientific_name", ignore.case=FALSE, 
                                 use_internal_data = TRUE) {
    if (use_internal_data) {
        by <- match.arg(by, c("kegg_code", "scientific_name", "common_name"))
        kegg_species <- kegg_species_data() 
        # Message <- paste("You are using the internal data. ",
        #               "If you want to use the latest data",
        #               "and your internet speed is fast enough, ",
        #                "please set use_internal_data = FALSE")
        # message(Message)
    } else {
        kegg_species <- get_kegg_species()
    }
    idx <- grep(str, kegg_species[, by], ignore.case = ignore.case)
    kegg_species[idx,]
}


kegg_species_data <- function() {
    utils::data(list="kegg_species", package="clusterProfiler")
    get("kegg_species", envir = .GlobalEnv)
}

get_kegg_species <- function(save = FALSE) {
    url <- "https://rest.kegg.jp/list/organism"
    species <- read.table(url, fill = TRUE, sep = "\t", header = F, quote = "")
    species <- species[, -1]
    scientific_name <- gsub(" \\(.*", "", species[,2])
    common_name <- gsub(".*\\(", "", species[,2])
    common_name <- gsub("\\)", "", common_name)
    kegg_species <- data.frame(kegg_code = species[, 1], 
                            scientific_name = scientific_name, 
                            common_name = common_name)

    if (save) save(kegg_species, file="kegg_species.rda")
    invisible(kegg_species)                                
}


## get_kegg_species <- function() {
##     pkg <- "XML"
##     requireNamespace(pkg)
##     readHTMLTable <- eval(parse(text="XML::readHTMLTable"))
##     x <- readHTMLTable("https://www.genome.jp/kegg/catalog/org_list.html")

##     y <- get_species_name(x[[2]], "Eukaryotes")
##     y2 <- get_species_name(x[[3]], 'Prokaryotes')

##     sci_name <- gsub(" \\(.*$", '', y[,2])
##     com_name <- gsub("[^\\(]+ \\(([^\\)]+)\\)$", '\\1', y[,2])
##     eu <- data.frame(kegg_code=unlist(y[,1]),
##                      scientific_name = sci_name,
##                      common_name = com_name,
##                      stringsAsFactors = FALSE)
##     pr <- data.frame(kegg_code=unlist(y2[,1]),
##                      scientific_name = unlist(y2[,2]),
##                      common_name = NA,
##                      stringsAsFactors = FALSE)
##     kegg_species <- rbind(eu, pr)
##     save(kegg_species, file="kegg_species.rda")
##     invisible(kegg_species)
## }

## get_species_name <- function(y, table) {
##     idx <- get_species_name_idx(y, table)
##     t(sapply(1:nrow(idx), function(i) {
##         y[] = lapply(y, as.character)
##         y[i, idx[i,]]
##     }))
## }


## get_species_name_idx <- function(y, table='Eukaryotes') {
##     table <- match.arg(table, c("Eukaryotes", "Prokaryotes"))
##     t(apply(y, 1, function(x) {
##         ii <- which(!is.na(x))
##         n <- length(ii)
##         if (table == "Eukaryotes") {
##             return(ii[(n-2):(n-1)])
##         } else {
##             return(ii[(n-3):(n-2)])
##         }
##     }))
## }

##' @importFrom downloader download
kegg_rest <- function(rest_url) {
    message('Reading KEGG annotation online: "', rest_url, '"...')
    f <- tempfile()
    
    dl <- mydownload(rest_url, destfile = f)
    
    if (is.null(dl)) {
        message("fail to download KEGG data...")
        return(NULL)
    }

    content <- readLines(f)

    content %<>% strsplit(., "\t") %>% do.call('rbind', .)
    res <- data.frame(from=content[,1],
                      to=content[,2])
    return(res)
}


## https://www.genome.jp/kegg/rest/keggapi.html
## kegg_link('hsa', 'pathway')
kegg_link <- function(target_db, source_db) {
    url <- paste0("https://rest.kegg.jp/link/", target_db, "/", source_db, collapse="")
    kegg_rest(url)
}


kegg_list <- function(db) {
    url <- paste0("https://rest.kegg.jp/list/", db, collapse="")
    kegg_rest(url)
}

##' convert ko ID to descriptive name
##'
##'
##' @title ko2name
##' @param ko ko ID
##' @return data.frame
##' @export
##' @author guangchuang yu
ko2name <- function(ko) {
    p <- kegg_list('pathway')
    ko2 <- gsub("^ko", "path:map", ko)
    ko.df <- data.frame(ko=ko, from=ko2)
    res <- merge(ko.df, p, by = 'from', all.x=TRUE)
    res <- res[, c("ko", "to")]
    colnames(res) <- c("ko", "name")
    return(res)
}


