#' @include transcriptToX.R

#' @title Map genomic coordinates to transcript coordinates
#'
#' @description
#'
#' `genomeToTranscript` maps genomic coordinates to positions within the
#' transcript (if at the provided genomic position a transcript is encoded).
#' The function does only support mapping of genomic coordinates that are
#' completely within the genomic region at which an exon is encoded. If the
#' genomic region crosses the exon boundary an empty `IRanges` is returned.
#' See examples for details.
#'
#' @details
#'
#' The function first retrieves all exons overlapping the provided genomic
#' coordinates and identifies then exons that are fully containing the
#' coordinates in `x`. The transcript-relative coordinates are calculated based
#' on the relative position of the provided genomic coordinates in this exon.
#'
#' @note
#'
#' The function throws a warning and returns an empty `IRanges` object if the
#' genomic coordinates can not be mapped to a transcript.
#'
#' @param x `GRanges` object with the genomic coordinates that should be
#'     mapped.
#'
#' @param db `EnsDb` object or pre-loaded exons 'CompressedGRangesList' object 
#'     using exonsBy().
#'
#' @return
#'
#' An `IRangesList` with length equal to `length(x)`. Each element providing
#' the mapping(s) to position within any encoded transcripts at the respective
#' genomic location as an `IRanges` object. An `IRanges` with negative start
#' coordinates is returned, if the provided genomic coordinates are not
#' completely within the genomic coordinates of an exon.
#'
#' The ID of the exon and its rank (index of the exon in the transcript) are
#' provided in the result's `IRanges` metadata columns as well as the genomic
#' position of `x`.
#'
#' @md
#'
#' @family coordinate mapping functions
#'
#' @author Johannes Rainer
#'
#' @examples
#'
#' library(EnsDb.Hsapiens.v86)
#'
#' ## Subsetting the EnsDb object to chromosome X only to speed up execution
#' ## time of examples
#' edbx <- filter(EnsDb.Hsapiens.v86, filter = ~ seq_name == "X")
#'
#' ## Define a genomic region and calculate within-transcript coordinates
#' gnm <- GRanges("X:107716399-107716401")
#'
#' res <- genomeToTranscript(gnm, edbx)
#' ## Result is an IRanges object with the start and end coordinates within
#' ## each transcript that has an exon at the genomic range.
#' res
#'
#' ## An IRanges with negative coordinates is returned if at the provided
#' ## position no exon is present. Below we use the same coordinates but
#' ## specify that the coordinates are on the forward (+) strand
#' gnm <- GRanges("X:107716399-107716401:+")
#' genomeToTranscript(gnm, edbx)
#'
#' ## Next we provide multiple genomic positions.
#' gnm <- GRanges("X", IRanges(start = c(644635, 107716399, 107716399),
#'     end = c(644639, 107716401, 107716401)), strand = c("*", "*", "+"))
#'
#' ## The result of the mapping is an IRangesList each element providing the
#' ## within-transcript coordinates for each input region
#' genomeToTranscript(gnm, edbx)
#' 
#' ## If you are tring to calculate within-transcript coordinates of a huge 
#' ## list of genomic region, you shall use pre-loaded exons GRangesList to  
#' ## replace the SQLite db edbx
#'  
#' ## Below is just a lazy demo of querying multiple genomic region 
#' library(parallel)
#' 
#' gnm <- rep(GRanges("X:107715899-107715901"),10)
#' 
#' exons <- exonsBy(EnsDb.Hsapiens.v86)
#' 
#' ## You can pre-define the exons region to further accelerate the code.
#' 
#' exons <- exonsBy(
#'     EnsDb.Hsapiens.v86, by = "tx",
#'     filter = AnnotationFilterList(
#'         SeqNameFilter(as.character(unique(seqnames(gnm)))),
#'         GeneStartFilter(max(end(gnm)), condition = "<="),
#'         GeneEndFilter(min(start(gnm)), condition = ">=")
#'     )
#' )
#' 
#' ## only run in Linux ## 
#' # res_temp <- mclapply(1:10, function(ind){
#' #     genomeToTranscript(gnm[ind], exons)
#' # }, mc.preschedule = TRUE, mc.cores = detectCores() - 1)
#' 
#' # res <- do.call(c,res_temp)
#' 
#' cl <- makeCluster(detectCores() - 1)
#' clusterExport(cl,c('genomeToTranscript','gnm','exons'))
#' 
#' res <- parLapply(cl,1:10,function(ind){
#'    genomeToTranscript(gnm[ind], exons)
#' })
#' stopCluster(cl)
genomeToTranscript <- function(x, db) {
    if (missing(x) || !is(x, "GRanges"))
        stop("Argument 'x' is required and has to be a 'GRanges' object")
    if (missing(db) || !(is(db, "EnsDb") || is(db,"CompressedGRangesList"))) 
        stop("Argument 'db' is required and has to be an 'EnsDb' object or a 'CompressedGRangesList' object") # load the exons priorly
    res <- .genome_to_tx(x, db)
    if (is(res, "IRanges"))
        res <- IRangesList(res)
    not_mapped <- sum(any(start(res) < 0))
    if (not_mapped > 0)
        warning(not_mapped, " genomic region(s) could not be mapped ",
                "to a transcript; hint: see ?seqlevelsStyle if you used ",
                "UCSC chromosome names", call. = FALSE)
    res
}

#' @title Map genomic coordinates to protein coordinates
#'
#' @description
#'
#' Map positions along the genome to positions within the protein sequence if
#' a protein is encoded at the location. The provided coordinates have to be
#' completely within the genomic position of an exon of a protein coding
#' transcript (see [genomeToTranscript()] for details). Also, the provided
#' positions have to be within the genomic region encoding the CDS of a
#' transcript (excluding its stop codon; soo [transcriptToProtein()] for
#' details).
#'
#' For genomic positions for which the mapping failed an `IRanges` with
#' negative coordinates (i.e. a start position of -1) is returned.
#'
#' @details
#'
#' `genomeToProtein` combines calls to [genomeToTranscript()] and
#' [transcriptToProtein()].
#'
#' @param x `GRanges` with the genomic coordinates that should be mapped to
#'     within-protein coordinates.
#'
#' @param db `EnsDb` object.
#' 
#' @inheritParams transcriptToProtein
#'
#' @return
#'
#' An `IRangesList` with each element representing the mapping of one of the
#' `GRanges` in `x` (i.e. the length of the `IRangesList` is `length(x)`).
#' Each element in `IRanges` provides the coordinates within the protein
#' sequence, names being the (Ensembl) IDs of the protein. The ID of the
#' transcript encoding the protein, the ID of the exon within which the
#' genomic coordinates are located and its rank in the transcript are provided
#' in metadata columns `"tx_id"`, `"exon_id"` and `"exon_rank"`. Metadata
#' columns `"cds_ok"` indicates whether the length of the CDS matches the
#' length of the encoded protein. Coordinates for which `cds_ok = FALSE` should
#' be taken with caution, as they might not be correct. Metadata columns
#' `"seq_start"`, `"seq_end"`, `"seq_name"` and `"seq_strand"` provide the
#' provided genomic coordinates.
#'
#' For genomic coordinates that can not be mapped to within-protein sequences
#' an `IRanges` with a start coordinate of -1 is returned.
#'
#' @family coordinate mapping functions
#'
#' @author Johannes Rainer
#'
#' @md
#'
#' @examples
#'
#' library(EnsDb.Hsapiens.v86)
#' ## Restrict all further queries to chromosome x to speed up the examples
#' edbx <- filter(EnsDb.Hsapiens.v86, filter = ~ seq_name == "X")
#'
#' ## In the example below we define 4 genomic regions:
#' ## 630898: corresponds to the first nt of the CDS of ENST00000381578
#' ## 644636: last nt of the CDS of ENST00000381578
#' ## 644633: last nt before the stop codon in ENST00000381578
#' ## 634829: position within an intron.
#' gnm <- GRanges("X", IRanges(start = c(630898, 644636, 644633, 634829),
#'     width = c(5, 1, 1, 3)))
#' res <- genomeToProtein(gnm, edbx)
#'
#' ## The result is an IRangesList with the same length as gnm
#' length(res)
#' length(gnm)
#'
#' ## The first element represents the mapping for the first GRanges:
#' ## the coordinate is mapped to the first amino acid of the protein(s).
#' ## The genomic coordinates can be mapped to several transcripts (and hence
#' ## proteins).
#' res[[1]]
#'
#' ## The stop codon is not translated, thus the mapping for the second
#' ## GRanges fails
#' res[[2]]
#'
#' ## The 3rd GRanges is mapped to the last amino acid.
#' res[[3]]
#'
#' ## Mapping of intronic positions fail
#' res[[4]]
#' 
#' ## Meanwhile, this function can be called in parallel processes if you preload
#' ## the protein, exons and transcripts database.
#' 
#' proteins <- proteins(edbx)
#' exons <- exonsBy(edbx)
#' transcripts <- transcripts(edbx)
#' 
#' genomeToProtein(gnm, edbx, proteins = proteins, exons = exons, transcripts = transcripts)
genomeToProtein <- function(x, db, proteins = NA, exons = NA, transcripts = NA) {
    if (missing(x) || !is(x, "GRanges"))
        stop("Argument 'x' is required and has to be a 'GRanges' object")
    if (missing(db) || !is(db, "EnsDb"))
        stop("Argument 'db' is required and has to be an 'EnsDb' object")
    preload_ranges_missing <- which(c(
        identical(proteins,NA),
        identical(exons,NA),
        identical(transcripts,NA)
    ))
    if(identical(integer(0), preload_ranges_missing))
        txs <- genomeToTranscript(x, exons)
    else if (length(preload_ranges_missing) == 3) {
        txs <- genomeToTranscript(x, db)
    } else {
        stop(paste(
            "Argument", 
            c("'proteins'", "'exons'", "'transcripts'")[preload_ranges_missing],
            'missing.'
            , sep = " "
        ))
    }
    int_ids <- rep(1:length(txs), lengths(txs))
    txs <- unlist(txs, use.names = FALSE)
    if (is.null(names(txs)))
        names(txs) <- ""
    if (identical(integer(0), preload_ranges_missing))
        prts <- transcriptToProtein(txs, db, proteins = proteins, exons = exons, transcripts = transcripts)
    else prts <- transcriptToProtein(txs, db)
    mcols(prts) <- cbind(mcols(prts)[, c("tx_id", "cds_ok")],
                         mcols(txs)[, colnames(mcols(txs)) != "tx_id"])
    prts <- split(prts, int_ids)
    names(prts) <- NULL
    ## Prune the result by removing non-mappable regions from each element
    ## for which we do have correct mappings.
    prts <- IRangesList(lapply(prts, function(x) {
        strts <- start(x)
        if (any(strts < 0) & any(strts > 0))
            x <- x[strts > 0]
        x
    }))
    prts
}

#' This function takes a `GRanges` and a `GRangesList` as input and maps
#' coordinates. We loop through each input range and map that to within
#' transcript positions based on the `exns` argument.
#'
#' @param genome `GRanges` with the genomic positions to be mapped.
#'
#' @param exns `GRangesList` with genomic positions of transcripts' exons, i.e.
#'     a `GRangesList` as the one returned by `exonsBy`.
#'
#' @author Johannes Rainer
#'
#' @md
#'
#' @noRd
.genome_to_tx_ranges <- function(genome, exns) {
    genome_gr <- as(genome, "GRangesList") # preserve the metadata
    genome_gr@unlistData@elementMetadata <- genome@elementMetadata
    IRangesList(unlist(
        lapply(genome_gr, FUN = function(rgn, exns) {
            if (length(exns)) {
                ints <- pintersect(exns, rgn, drop.nohit.ranges = TRUE,
                                   ignore.strand = FALSE)
                ints <- ints[width(ints) == width(rgn)]
                ints <- ints[lengths(ints) > 0]
                ints_map <- mapply(
                    ints, exns[names(ints)], names(ints), FUN = function(int, tx,
                                                                         tx_id,
                                                                         rgn) {
                        exon_idx <- int$exon_rank
                        if (exon_idx > 1)
                            count_up <- sum(width(tx)[1:(exon_idx - 1)])
                        else count_up <- 0
                        if (as.character(strand(int)[1]) == "+")
                            irng <- IRanges(start = count_up + start(rgn) -
                                                start(tx[exon_idx]) + 1,
                                            width = width(rgn))
                        else
                            irng <- IRanges(start = count_up + end(tx[exon_idx]) -
                                                end(rgn) + 1,
                                            width = width(rgn))
                        names(irng) <- tx_id
                        dfrm <- DataFrame(
                            tx_id = tx_id,
                            exon_id = int$exon_id,
                            exon_rank = exon_idx,
                            seq_start = start(rgn),
                            seq_end = end(rgn),
                            seq_name = as.character(seqnames(rgn)),
                            seq_strand = as.character(strand(rgn))
                        )
                        if(!is.null(mcols(rgn))) dfrm <- DataFrame(dfrm, mcols(rgn))
                        mcols(irng) <- dfrm
                        irng
                    }, MoreArgs = list(rgn = rgn), USE.NAMES = FALSE)
            } else ints_map <- NULL
            if (length(ints_map))
                unlist(IRangesList(ints_map))
            else {
                metad <- DataFrame(tx_id = NA_character_,
                                   exon_id = NA_character_,
                                   exon_rank = NA_integer_,
                                   seq_start = start(rgn), seq_end = end(rgn),
                                   seq_name = as.character(seqnames(rgn)),
                                   seq_strand = as.character(strand(rgn)))
                if(!is.null(mcols(rgn))) metad <- DataFrame(metad, mcols(rgn))
                empty_rng <- IRanges(start = -1, width = 1)
                mcols(empty_rng) <- metad
                empty_rng
            }
        }, exns = exns)
      , use.names = FALSE))
}

#' @description
#'
#' Takes a `GRanges` object, identifies all exons overlapping that region,
#' checks if the region is completely included in an exons and returns
#' the position within the transcript for that exon.
#'
#' @param db `EnsDb` or 'CompressedGRangesList' 
#'
#' @param genome `GRanges`
#'
#' @author Johannes Rainer
#'
#' @md
#'
#' @noRd
#'
#' @examples
#'
#' ## Second example: nt 2 of exon 4 of ENST00000554971 (nt 637 of tx)
#' genome <- GRanges("X", IRanges(start = 601735, end = 601735))
#' db <- edbx
#'
#' ## + strand: Last two nt of CDS for ENST00000381578
#' genome <- GRanges("X", IRanges(start = 605370, end = 605374))
#' ## Length of result is 2.
#' ## Position within ENST00000381578: 259 + 709 + 209 + 58 + 89 + 245 = 1569
#'
#' ## - strand: TSC22D3:
#' ## 1) ENST00000486554 nt 1-3:
#' genome <- GRanges("X", IRanges(end = 106959631, start = 106959629))
#' ## Overlaps 2 tx: ENST00000372390, ENST00000486554
#'
#' ## 1) ENST00000486554 nts 5-8 in exon 2
#' ## exon 1: 503nt: region is 508-511
#' genome <- GRanges("X", IRanges(end = 106957975, width = 4))
#' .genome_to_tx(genome, edbx)
#'
#' ## 3) ENST00000372397, last 3nt
#' ## exon 3: 446 + 52 + 1529 total length: 2025-2027
#' genome <- GRanges("X", IRanges(start = 106956451, width = 3))
#' .genome_to_tx(genome, edbx)
#'
#'
#' ## Example with two genes, on two strands!
.genome_to_tx <- function(genome, db) {
    ## Get exonsBy for all input ranges.
    if(is(db, "EnsDb")){
        exns <- exonsBy(
            db, by = "tx",
            filter = AnnotationFilterList(
                SeqNameFilter(as.character(unique(seqnames(genome)))),
                GeneStartFilter(max(end(genome)), condition = "<="),
                GeneEndFilter(min(start(genome)), condition = ">=")
            )
        )
    } else exns <- db
    res <- .genome_to_tx_ranges(genome, exns)
    if (!is.null(names(genome)))
        names(res) <- names(genome)
    if (length(genome) == 1)
        res[[1]]
    else res
}
