library(rvest)
library(data.table)
# library(stringr)

baseurl <- "http://tel.directory.gov.hk/"
suffixurl <- "?accept_disclaimer=yes"

hasphonetable <- function(urlhtml) {
    return(length(html_nodes(urlhtml, ".row td")) > 0)
}

#teldir <- data.table(fullname = "Herg Gerh", posttitle = "nyaaaah", telno = "2859 4852", email = "a@a.com", department = "The poalis")[0]

textorbr <- function(htmlnode) {
    converttotext <- function(htmlchild) {
        if (html_tag(htmlchild) == "br") {return("<br/>")} else {return(html_text(htmlchild))}
    }
    convertedtext <- lapply(html_children(htmlnode), converttotext)
    return(paste0(convertedtext, collapse=""))
}

teldirlist <- list()
scrape <- function(url, teldirlist) {
    urlhtml <- html(url)
    if (hasphonetable(urlhtml)) {
        phonetablec <- c()
        department <- ""
        h1rowtdnodes <- html_nodes(urlhtml, ".row td, h1")
        for (node in h1rowtdnodes) {
            if (html_tag(node) == "h1") {
                if (!is.null(phonetablec)) {
                    phonetable <- data.table(matrix(phonetablec, ncol=4, byrow=TRUE))
                    setnames(phonetable, c("fullname", "title", "telno", "email"))
                    phonetable[,department := department]
                    teldirlist[[department]] <- phonetable
                }
                department <- textorbr(node)
                phonetablec <- c()
            } else {
                phonetablec <- c(phonetablec, textorbr(node))
            }             
        }
        if (!is.null(phonetablec)) {
            phonetable <- data.table(matrix(phonetablec, ncol=4, byrow=TRUE))
            setnames(phonetable, c("fullname", "title", "telno", "email"))
            phonetable[,department := department]
            teldirlist[[department]] <- phonetable
        }
    }
    
    somelinks <- html_attr(html_nodes(urlhtml, "#tbl_dept_list a"), "href")
    morelinks <- html_attr(html_nodes(urlhtml, "#dept_list_lv2_outline a"), "href")
    links <- c(somelinks, morelinks)
    for (link in links) {
        print(link)
        teldirlist <- scrape(paste0(baseurl, link, suffixurl), teldirlist)
    }
    return(teldirlist)
}

initialurl <- "http://tel.directory.gov.hk/index_ENG.html?accept_disclaimer=yes"
teldirlist <- scrape(initialurl, teldirlist)
teldir <- rbindlist(teldirlist)
save(teldir, file = "teldir.Rdata")
