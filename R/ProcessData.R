# Get the value of regulation of a trguid from the gene expression
# data (i.e in evidence)
getGeneVals <- function(trguids, evidence){
  trguids <- as.vector(trguids) 
  val <- rep(0, length(trguids))
  ind <- match(trguids, evidence$uid)
  ind2 <- na.omit(ind)
  if(length(ind2) > 0){
    val[which(!is.na(ind))] <- evidence$val[ind2]
  }
  return(val)
}



#' Compute the Quaternary Product Scoring Statistic for a biological causal network.
#' 
#' 
#' @description This function computes the Quaternary Product Scoring Statistic for all source nodes in a  
#'              causal network once new gene expression data is presented. This is a Causal Relation Engine (CRE) 
#'              on the levels of a causal network of predictions and a new set of realizations that
#'              arise in real world situations. 
#' 
#' @usage BioQCREtoNet(relations, evidence, entities, method = "Quaternary", 
#'                     fc.thresh = 1.3, is.Logfc = TRUE, pval.thresh = 0.01) 
#' 
#' @param relations A data frame containing pairs of connected entities in a causal network (e.g Protein-Protein interactions),
#'        and the type of causal relation between them. The data frame must have three columns with column names: \emph{srcuid}, 
#'        \emph{trguid} and \emph{mode} respective of order. \emph{srcuid} stands for source entity, \emph{trguid} stands for target entity and \emph{mode} stands for the
#'        type of relation between \emph{srcuid} and \emph{trguid}. The relation has to be one of \emph{increases}, \emph{decreases} or \emph{regulates}. All three columns must be of type character.
#' @param evidence A data frame of entities which are target nodes in the causal network and have new 
#'        experimental values (e.g gene expression data). The \emph{evidence} data frame must have three columns \emph{entrez}, \emph{fc} and \emph{pvalue}. 
#'        \emph{entrez} denotes the entrez id of a given gene, \emph{fc} denotes
#'        the fold change of a gene, and \emph{pvalue} denotes the p-value. The \emph{entrez} column must be of type
#'        character, and the \emph{fc} and \emph{pvalue} columns must be numeric values.
#' @param entities A data frame of mappings for all entities present in data frame \emph{relations}. \emph{entities} must contain
#'        four columns: \emph{uid}, \emph{id}, \emph{symbol} and \emph{type} respective of order. All four columns must
#'        be of type character. \emph{uid} includes every source and target node in the network (i.e \emph{relations}),
#'        \emph{id} is the id of \emph{uid} (e.g entrez id of an mRNA), \emph{symbol} is the symbol of \emph{id} and \emph{type} is the type
#'        of entity of \emph{id} which can be one of mRNA, protein, drug, compound etc. All target nodes must be of type mRNA.
#' @param method Choose one of \emph{Quaternary}, \emph{Ternary} or \emph{Enrichment}. Default is \emph{Quaternary}.
#' @param is.Logfc Boolean value to indicate if the fold change is in log scale. Default value is TRUE.
#' @param fc.thresh Threshold for fold change in \emph{evidence} data frame. Any row in evidence with abosolute value \emph{fc}
#'        smaller than \emph{fc.thresh} will be ignored. Default value is 1.3. If 
#'        \emph{is.Logfc = TRUE} then \emph{fc.thresh} is set to \emph{log2(fc.thresh)} internally.
#' @param pval.thresh Threshold for p-values in \emph{evidence} data frame. All rows in \emph{evidence} with p-values 
#'        greater than \emph{pval.thresh} will be ingnored. Default value is 0.01. 
#' 
#'        
#' @return This function returns a data frame containing parameters concerning the Quaternary Product
#'         Scoring Statistic. The p-values of each of the source nodes is also computed, and the data frame
#'         is in increasing order of p-values of the goodness of fit score for the given source nodes. The column
#'         names of the data frame are:
#'         
#' \itemize{        
#' \item  \emph{uid} The source node in the network.
#' \item \emph{name} symbols of the source nodes. 
#' \item \emph{regulation} Direction of change of source node.
#' \item \emph{correct.pred} Number of correct predictions in \emph{evidence} when compared to predictions made
#'                     by the network.
#' \item \emph{incorrect.pred} Number of incorrect predictions in \emph{evidence} when compared to predictions made
#'                     by the network.
#' \item \emph{score} Value of the Quaternary Product Scoring Statistic.
#' \item \emph{total.reachable} Total number of \emph{trguid}s connected to a \emph{srcuid}.
#' \item \emph{significant.reachable} number of \emph{trguid}s connected to a \emph{srcuid} that are also regulated in \emph{evidence}.
#' \item \emph{total.ambiguous} Total number of \emph{srcuid} children with relation type \emph{regulates} or children
#'                              which share both \emph{increase} and \emph{decrease} relation with \emph{srcuid}.
#' \item \emph{significant.ambiguous} Total number of similar type of relations as with \emph{total.ambiguous} but 
#'                                    with the restriction that the children are regulated in \emph{evidence}.  
#' \item \emph{unknown} All \emph{trguid}s which do not interact with the given \emph{srcuid}.
#' \item \emph{pvalue} P-value of the score.
#' }
#' 
#' @author Carl Tony Fakhry, Ping Chen and Kourosh Zarringhalam
#' 
#' @references C. T. Fakhry, P. Choudhary, A. Gutteridge, B. Sidders, P. Chen, D. Ziemek, K. Zarringhalam. 
#'             Identifying Transcriptional Regulators in Signed and Unsigned Causal Networks, 2015, In submission.
#'
#' @export

BioQCREtoNet <- function(relations, evidence, entities, method = "Quaternary", fc.thresh = 1.3, is.Logfc = TRUE, pval.thresh = 0.01){
  
  # Check to make sure that data frames are not empty
  if (!is.data.frame(relations)){ 
    stop("Please enter a data frame for relations!")
  }
  
  if (!is.data.frame(evidence)){ 
    stop("Please enter a data frame for evidence!")
  }
  
  if (!is.data.frame(entities)){ 
    stop("Please enter a data frame for entities!")
  }
  
  # Check if data frames are empty
  if (nrow(relations) == 0){
    stop("Please enter a non-empty data frame for relations!")
  }
  
  if (nrow(evidence) == 0){
    stop("Please enter a non-empty data frame for evidence!")
  }
  
  if (nrow(entities) == 0){
    stop("Please enter a non-empty data frame for entities!")
  }
  
  # Check for NAs in evidence
  if (sum(is.na(evidence)) > 0){
    stop("Evidence data frame contains rows with NAs!")
  }
  
  # Check for NAs in relations
  if (sum(is.na(relations)) > 0){
    stop("Relations data frame contains rows with NAs!")
  }
  
  # Check for NAs in relations
  if (sum(is.na(entities)) > 0){
    stop("Entities data frame contains rows with NAs!")
  }
  
  # Do more validation for evidence data frame
  if(ncol(evidence) == 3){
    
    # Check if there are duplicated rows in evidence
    if(nrow(evidence[duplicated(evidence),]) > 0){
      stop("Duplicate rows in evidence found!")
    }
    
    # Check for correct column names
    pval.ind <- which(colnames(evidence) %in% c("pvalue"))
    fc.ind <- which(colnames(evidence) %in% c("fc") )
    id.ind <- which(colnames(evidence) %in% c("entrez"))
    
    # Stop if column names are not correct
    if(length(id.ind) == 0 | length(fc.ind) == 0 | length(pval.ind) == 0){
      stop("Please label evidence column names as entrez, fc, pvalue!")
    }
    
    # Rearrange data
    evidence <- evidence[,c(id.ind, fc.ind, pval.ind)]
    names(evidence) <- c("entrez", "fc", "pvalue")
    
    # Check data types of entities column
    if(!is.character(evidence$entrez)){
      stop("In evidence, column entrez must be of type character!")
    }
    
    if(!is.numeric(evidence$fc)){
      stop("In evidence, column fc must be numeric!")
    }
    
    if(!is.numeric(evidence$pvalue)){
      stop("In entities, column pvalue must be numeric!")
    }

    if (is.Logfc){
      fc.thresh <- log2(fc.thresh)
    }
        
    # Make sure p-values are positive and less than 1
    if(!all(evidence$pvalue >= 0)){
      stop("All P-values in evidence data frame must be greater or equal to zero!")
    }
    
    if(!all(evidence$pvalue <= 1)){
      stop("All P-values in evidence data frame must be smaller than one!")
    }
    
    # Remove duplicate entrez in evidence
    if(any(duplicated(evidence$entrez))){
      stop("Remove duplicated entrez ids in evidence!")
    }
    
    # Filter by p-value and fold-change
    evidence <- evidence[abs(evidence$fc) >= fc.thresh & evidence$pval <= pval.thresh,]
    evidence <- evidence[,c("entrez","fc")]
    
    # Check if any evidence left
    if(nrow(evidence) == 0){
      stop("No rows left in evidence after rows are filtered according to fc.thresh and pval.thresh!")
    }
    
    # Where fc is greater than 0 replace with increase i.e 1 and where fc is negative
    # replace with -1 i.e decreases
    evidence[,2] <- ifelse(evidence[,2] > 0, 1, -1)
    names(evidence) <- c("entrez", "val")
    
  }
  
  else{
    
    stop("Please provide a valid evidence data frame containing columns: entrez, fc, pvalue")
  
  }
  
  # Do validation for entities data frame
  if(ncol(entities) == 4 & all(names(entities) == c("uid", "id", "symbol", "type"))){
    
    # Check if there are duplicated rows in entities
    if(nrow(entities[duplicated(entities),]) > 0){
      stop("Duplicate rows in entities found!")
    }
    
    # Check if there are duplicated uids in entities
    if(any(duplicated(entities$uid))){
      stop("Please remove duplicated uid in entities data frame!")
    }
    
    # Check data types of entities column
    if(!is.character(entities$uid) | !is.character(entities$symbol)){
      stop("In entities, columns uid, id, symbol and type must be of type character!")
    }
    
    if(!is.character(entities$id) | !is.character(entities$type)){
      stop("In entities, columns uid, id, symbol and type must be of type character!")
    }
    
    trg.ents <- entities[entities$type == "mRNA",]
    if(nrow(trg.ents) == 0){
      stop("No target nodes in entities. Please make sure all target uids are of type mRNA and are present in entities!")
    }
    
    # Make sure all evidence entrez are in trg.ents ids
    n.e1 <- nrow(evidence)
    evidence <- evidence[evidence$entrez %in% trg.ents$id,]
    n.e2 <- nrow(evidence)
    if (n.e2 == 0){
      stop("All entrez ids in evidence are not present in entities data frame!")
    }
    print(paste((n.e1-n.e2), " rows from evidence removed due to entrez ids being unrepsented in entities!"))
    
    # Make sure no entrez id in entities maps to two entities in trg.ents
    evidence.tmp = merge(evidence, trg.ents, by.x = "entrez", by.y = "id")
    if(nrow(evidence.tmp) != nrow(evidence)){
      stop("Entrez ids in evidence file mapped to multiple mRNAs in entities, please remove proper duplicated ids in entities!")
    }
    
    evidence <- data.frame(uid = evidence.tmp$uid, val = evidence.tmp$val, stringsAsFactors = F)
  
  }
  else{
    
    stop("Please provide a valid entities data frame containing columns: protein, entrez, symbol!")
    
  }
  
  trg.ents <- entities[entities$type == "mRNA",]
  src.ents <- entities[entities$type != "mRNA",]
  if(nrow(src.ents) == 0){
    stop("No source nodes in entities!")
  }
  
  # Do validation for relations data frame
  if(ncol(relations) == 3 & all(names(relations) == c("srcuid", "trguid", "mode"))){
    
    # Check if there are duplicated rows in relations
    if(nrow(relations[duplicated(relations),]) > 0){
      stop("Duplicate rows in relations found!")
    }
    
    # Check data types of entities column
    if(!is.character(relations$srcuid) | !is.character(relations$trguid) | !is.character(relations$mode)){
      stop("In relations, all columns must be of type character!")
    }
    
    # Make sure all relations are either increases, decreases or regulates
    if(!all(relations$mode %in% c("increases", "decreases", "regulates"))){
      stop("All relations between srcuid and trguid in relations data frame must be either increases, decreases or regulates!")
    }
    
    # Make sure all proteins are in entities
    unique.src.ents <- unique(src.ents$uid)
    unique.trg.ents <- unique(trg.ents$uid)
    unique.srcuids <- unique(relations$srcuid)
    unique.trguids <- unique(relations$trguid)
    
    if(!all(unique.trguids %in% unique.trg.ents)){
      stop("All trguids in relations must be of type mRNA and must be present in uid column of entities data frame!")
    }
    
    if(!all(unique.srcuids %in% unique.src.ents)){
      stop("All srcuids in relations must be present in uid column of entities data frame and must not be of type mRNA!")
    }
    
    # Handle ambiguities if source node affects target node in more than one way
    temp.rels = relations[, c("srcuid", "trguid")]
    indices1 <- which(duplicated(temp.rels))
    indices2 <- which(duplicated(temp.rels, fromLast=TRUE))
    indices <- unique(c(indices1, indices2))
    relations[indices,3] <- "regulates"
    relations <- relations[!duplicated(relations),]
    
  }
  
  else{
    
    stop("Please provide a valid relations data frame containing columns: srcuid, trguid, mode!")
    
  }
  
  # Proteins to be tested
  u.hyps <- unique(relations$srcuid)
  
  # For each protein, get its children
  child.uid <- lapply(u.hyps, function(x) relations$trguid[relations$srcuid == x])
  

  # For each protein, Find if its children are upregulated or downregulated
  child.sgn <- lapply(u.hyps, function(x) ifelse(relations$mode[relations$srcuid == x] == 'increases', 
                                                1, ifelse(relations$mode[relations$srcuid == x] == 'decreases', -1, 0)))
  
  # Get the value of regulation of the children from the gene expression data 
  # (i.e in evidence)
  child.val <- lapply(child.uid, function(x) getGeneVals(x, evidence))
  
  # Get non children for each protein
  non.child.uid <- lapply(child.uid, function(x) unique(trg.ents$uid[which(!(trg.ents$uid %in% x))]))
  
  # Get gene values from evidence for all non children
  non.child.val <- lapply(non.child.uid, function(x) getGeneVals(x, evidence))
  
  
  results <- data.frame(matrix(0, nrow  = 2 * length(u.hyps), ncol = 12), stringsAsFactors = F)
  colnames(results) <- c('uid', 'name', 'regulation', 'correct.pred', 'incorrect.pred', 'score',
                        'total.reachable', 'significant.reachable', 'total.ambiguous', 'significant.ambiguous',
                        'unknown', 'pvalue')
  
  
  for(p.s in 1:length(u.hyps)){
    results[(2*(p.s-1)+1), 1] <- u.hyps[p.s]
    results[(2*p.s), 1]       <- u.hyps[p.s]
    results[(2*(p.s-1)+1), 2] <- src.ents$symbol[which(src.ents$uid == u.hyps[p.s])]
    results[(2*p.s), 2]       <- src.ents$symbol[which(src.ents$uid == u.hyps[p.s])]
    results[(2*(p.s-1)+1), 3] <- 'up'
    results[(2*p.s), 3]       <- 'down'
    
    npp = length(which(child.sgn[[p.s]] == 1 &  child.val[[p.s]] == 1))
    npm = length(which(child.sgn[[p.s]] == 1 &  child.val[[p.s]] == -1))
    npz = length(which(child.sgn[[p.s]] == 1 &  child.val[[p.s]] == 0))
    
    nmp = length(which(child.sgn[[p.s]] == -1 &  child.val[[p.s]] == 1))
    nmm = length(which(child.sgn[[p.s]] == -1 &  child.val[[p.s]] == -1))
    nmz = length(which(child.sgn[[p.s]] == -1 &  child.val[[p.s]] == 0))
    
    nrp = length(which(child.sgn[[p.s]] == 0 &  child.val[[p.s]] == 1))
    nrm = length(which(child.sgn[[p.s]] == 0 &  child.val[[p.s]] == -1))
    nrz = length(which(child.sgn[[p.s]] == 0 &  child.val[[p.s]] == 0))
    
    nzp = length(which(non.child.val[[p.s]] == 1))
    nzm = length(which(non.child.val[[p.s]] == -1))
    nzz = length(which(non.child.val[[p.s]] == 0))
    
    if (method == "Quaternary"){
      pval <- runCRE(npp, npm, npz, nmp, nmm, nmz, nrp, nrm, nrz, nzp, nzm, nzz, method = 'Quaternary')
    }
    else if (method == "Ternary"){
      pval <- runCRE(npp, npm, npz, nmp, nmm, nmz, nrp, nrm, nrz, nzp, nzm, nzz, method = 'Ternary')
    }
    else if (method == "Enrichment"){
      pval <- runCRE(npp, npm, npz, nmp, nmm, nmz, nrp, nrm, nrz, nzp, nzm, nzz, method = 'Enrichment')
    }
    else {
      stop("Select one of methods: Quaternary, Ternary or Enrichment")
    }
    
    qPlus  <- npp + npm + npz
    qMinus <- nmp + nmm + nmz
    qR     <- nrp + nrm + nrz
    qZero  <- nzp + nzm + nzz
    
    results[(2*(p.s-1)+1), 4]  <- npp + nmm
    results[(2*(p.s-1)+1), 5]  <- npm + nmp
    results[(2*(p.s-1)+1), 6]  <- npp + nmm - (npm + nmp)
    results[(2*(p.s-1)+1), 7]  <- qPlus + qMinus + qR
    results[(2*(p.s-1)+1), 8]  <- npp + npm + nmp + nmm + nrp + nrm
    results[(2*(p.s-1)+1), 9]  <- qR
    results[(2*(p.s-1)+1), 10] <- nrp + nrm
    results[(2*(p.s-1)+1), 11] <- qZero
    results[(2*(p.s-1)+1), 12] <- pval$pval.up
    
    results[(2*p.s), 4]  <- nmp + npm
    results[(2*p.s), 5]  <- npp + nmm
    results[(2*p.s), 6]  <- nmp + npm - (npp + nmm)
    results[(2*p.s), 7]  <- qPlus + qMinus + qR
    results[(2*p.s), 8]  <- npp + npm + nmp + nmm + nrp + nrm
    results[(2*p.s), 9]  <- qR
    results[(2*p.s), 10] <- nrp + nrm
    results[(2*p.s), 11] <- qZero
    results[(2*p.s), 12] <- pval$pval.down
  }
  
  
  results <- results[order(as.numeric(results$pvalue)), ]
  rownames(results) <- 1:nrow(results)
  
  return(results)
  
}  



# This function runs the CRE based on the version specified
runCRE = function(npp, npm, npz, nmp, nmm, nmz, nrp, nrm, nrz, nzp, nzm, nzz, method){
  
  if(method == 'Quaternary'){
    
    qR     <- nrp + nrm + nrz
    qZero  <- nzp + nzm + nzz
    nPlus  <- npp + nmp + nrp + nzp
    nMinus <- npm + nmm + nrm + nzm
    nZero  <- npz + nmz + nrz + nzz
    
    ## Assume up-regulated
    qPlus  <- npp + npm + npz
    qMinus <- nmp + nmm + nmz
    score  <- npp + nmm + nrp + nrm - (npm + nmp)
    pval.up <- QP_Pvalue(score = score, q_p = qPlus, q_m = qMinus, q_z = qZero,
                          q_r = qR, n_p = nPlus, n_m = nMinus, n_z = nZero)
    
    ## Assume down-regulated
    qPlus  <- nmp + nmm + nmz
    qMinus <- npp + npm + npz
    score  <- nmp + npm + nrp + nrm - (npp + nmm)
    pval.down <- QP_Pvalue(score = score, q_p = qPlus, q_m = qMinus, q_z = qZero,
                            q_r = qR, n_p = nPlus, n_m = nMinus, n_z = nZero)
    
  }else if(method == 'Ternary'){
    qR     <- 0
    qZero  <- nzp + nzm + nzz
    nPlus  <- npp + nmp + nzp
    nMinus <- npm + nmm + nzm
    nZero  <- npz + nmz + nzz
    
    ## Assume up-regulated
    qPlus  <- npp + npm + npz
    qMinus <- nmp + nmm + nmz
    score  <- npp + nmm - (npm + nmp)
    pval.up <- QP_Pvalue(score = score, q_p = qPlus, q_m = qMinus, q_z = qZero,
                          q_r = qR, n_p = nPlus, n_m = nMinus, n_z = nZero)
    
    ## Assume down-regulated
    qPlus  <- nmp + nmm + nmz
    qMinus <- npp + npm + npz
    score  <- nmp + npm - (npp + nmm)
    pval.down <- QP_Pvalue(score = score, q_p = qPlus, q_m = qMinus, q_z = qZero,
                            q_r = qR, n_p = nPlus, n_m = nMinus, n_z = nZero)
    
    
  }
  else if(method == 'Enrichment'){
    
    nrp    <- npp + nmp + nrp
    nrm    <- npm + nmm + nrm
    nrz    <- npz + nmz + nrz
    
    qPlus  <- 0
    qMinus <- 0
    qR     <- nrp + nrm + nrz
    qZero  <- nzp + nzm + nzz
    
    nPlus  <- nrp + nzp
    nMinus <- nrm + nzm
    nZero  <- nrz + nzz
    
    score  <- nrp + nrm
    
    pval.up <- QP_Pvalue(score = score, q_p = qPlus, q_m = qMinus, q_z = qZero,
                          q_r = qR, n_p = nPlus, n_m = nMinus, n_z = nZero)
    pval.down <- pval.up
    
  }
  
  pval <- list(pval.up = pval.up, pval.down = pval.down)
  
}
