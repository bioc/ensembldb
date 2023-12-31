\name{EnsDb-class}
\Rdversion{1.1}
\docType{class}
\alias{EnsDb-class}
\alias{dbconn}
\alias{dbconn,EnsDb-method}
\alias{ensemblVersion}
\alias{ensemblVersion,EnsDb-method}
\alias{listColumns}
\alias{listColumns,EnsDb-method}
\alias{metadata}
\alias{metadata,EnsDb-method}
\alias{seqinfo}
\alias{seqinfo,EnsDb-method}
\alias{seqlevels}
\alias{seqlevels,EnsDb-method}
\alias{organism}
\alias{organism,EnsDb-method}
\alias{show}
\alias{show,EnsDb-method}
\alias{listGenebiotypes}
\alias{listGenebiotypes,EnsDb-method}
\alias{listTxbiotypes}
\alias{listTxbiotypes,EnsDb-method}
\alias{listTables}
\alias{listTables,EnsDb-method}
\alias{updateEnsDb}
\alias{updateEnsDb,EnsDb-method}
\alias{returnFilterColumns}
\alias{returnFilterColumns,EnsDb-method}
\alias{returnFilterColumns<-}
\alias{returnFilterColumns<-,EnsDb-method}

\title{Basic usage of an Ensembl based annotation database}
\description{
  The \code{EnsDb} class provides access to an Ensembl-based annotation
  package. This help page describes functions to get some basic
  informations from such an object.
}
\section{Objects from the Class}{
  A connection to the respective annotation database is created upon
  loading of an annotation package created with the
  \code{\link{makeEnsembldbPackage}} function. In addition, the
  \code{\link{EnsDb}} constructor specifying the SQLite database file can be
  called to generate an instance of the object (see
  \code{\link{makeEnsemblSQLiteFromTables}} for an example).
}
\usage{

\S4method{dbconn}{EnsDb}(x)

\S4method{ensemblVersion}{EnsDb}(x)

\S4method{listColumns}{EnsDb}(x, table, skip.keys = TRUE, metadata = FALSE, ...)

\S4method{listGenebiotypes}{EnsDb}(x, ...)

\S4method{listTxbiotypes}{EnsDb}(x, ...)

\S4method{listTables}{EnsDb}(x, ...)

\S4method{metadata}{EnsDb}(x, ...)

\S4method{organism}{EnsDb}(object)

\S4method{returnFilterColumns}{EnsDb}(x)

\S4method{returnFilterColumns}{EnsDb}(x)

\S4method{returnFilterColumns}{EnsDb}(x) <- value

\S4method{seqinfo}{EnsDb}(x)

\S4method{seqlevels}{EnsDb}(x)

\S4method{updateEnsDb}{EnsDb}(x, ...)

}
\arguments{

  (in alphabetic order)

  \item{...}{Additional arguments.
    Not used.
  }

  \item{metadata}{For \code{listColumns}: whether columns from the
    metadata database column should also be returned. Defaults to
    \code{metadata = FALSE}.
  }

  \item{object}{
    For \code{organism}: an \code{EnsDb} instance.
  }

  \item{skip.keys}{
    for \code{listColumns}: whether primary and foreign keys (not
    being e.g. \code{"gene_id"} or alike) should be returned or not. By
    default these will not be returned.
  }

  \item{table}{
    For \code{listColumns}: optionally specify the table name(s) for
    which the columns should be returned.
  }

  \item{value}{
    For \code{returnFilterColumns}: a logical of length one specifying
    whether columns that are used for eventual filters should also be
    returned.
  }

  \item{x}{
    An \code{EnsDb} instance.
  }

}
\section{Slots}{
  \describe{
    \item{ensdb}{
      Object of class \code{"DBIConnection"}: the
      connection to the database.
    }

    \item{tables}{
      Named list of database table columns with the names being the
      database table names. The tables are ordered by their degree,
      i.e. the number of other tables they can be joined with.
    }

    \item{.properties}{
      Internal list storing user-defined properties. Should not be
      directly accessed.
    }
  }
}
\section{Methods and Functions}{
  \describe{

    \item{dbconn}{
      Returns the connection to the internal SQL database.
    }

    \item{ensemblVersion}{
      Returns the Ensembl version on which the package was built.
    }

    \item{listColumns}{
      Lists all columns of all tables in the database, or, if
      \code{table} is specified, of the respective table.
    }

    \item{listGenebiotypes}{
      Lists all gene biotypes defined in the database.
    }

    \item{listTxbiotypes}{
      Lists all transcript biotypes defined in the database.
    }

    \item{listTables}{
      Returns a named list of database table columns (names of the
      list being the database table names).
    }

    \item{metadata}{
      Returns a \code{data.frame} with the metadata information from the
      database, i.e. informations about the Ensembl version or Genome
      build the database was build upon.
    }

    \item{organism}{
      Returns the organism name (e.g. \code{"homo_sapiens"}).
    }

    \item{returnFilterColumns, returnFilterColumns<-}{
      Get or set the option which results in columns that are used for
      eventually specified filters to be added as result columns. The
      default value is \code{TRUE} (i.e. filter columns are returned).
    }

    \item{seqinfo}{
      Returns the sequence/chromosome information from the database.
    }

    \item{seqlevels}{
      Returns the chromosome/sequence names that are available in the
      database.
    }

    \item{show}{
      Displays some informations from the database.
    }

    \item{updateEnsDb}{
      Updates the \code{EnsDb} object to the most recent implementation.
    }

  }
}
\value{
  \describe{
    \item{For \code{connection}}{
      The SQL connection to the RSQLite database.
    }

    \item{For \code{EnsDb}}{
      An \code{EnsDb} instance.
    }

    \item{For \code{lengthOf}}{
      A named integer vector with the length of the genes or transcripts.
    }

    \item{For \code{listColumns}}{
      A character vector with the column names.
    }

    \item{For \code{listGenebiotypes}}{
      A character vector with the biotypes of the genes in the database.
    }

    \item{For \code{listTxbiotypes}}{
      A character vector with the biotypes of the transcripts in the database.
    }

    \item{For \code{listTables}}{
      A list with the names corresponding to the database table names
      and the elements being the attribute (column) names of the table.
    }

    \item{For \code{metadata}}{
      A \code{data.frame}.
    }

    \item{For \code{organism}}{
      A character string.
    }

    \item{For \code{returnFilterColumns}}{
      A logical of length 1.
    }

    \item{For \code{seqinfo}}{
      A \code{Seqinfo} class.
    }

    \item{For \code{updateEnsDb}}{
      A \code{EnsDb} object.
    }
  }
}
\note{
  While a column named \code{"tx_name"} is listed by the
  \code{listTables} and \code{listColumns} method, no such column is
  present in the database. Transcript names returned by the methods are
  actually the transcript IDs. This \emph{virtual} column was only
  introduced to be compliant with \code{TxDb} objects (which provide
  transcript names).
}
\author{
  Johannes Rainer
}
\seealso{
  \code{\link{EnsDb}},
  \code{\link{makeEnsembldbPackage}},
  \code{\link{exonsBy}}, \code{\link{genes}},
  \code{\link{transcripts}},
  \code{\link{makeEnsemblSQLiteFromTables}}

  \code{\link{addFilter}} for globally adding filters to an \code{EnsDb}
  object.

}
\examples{

library(EnsDb.Hsapiens.v86)

## Display some information:
EnsDb.Hsapiens.v86

## Show the tables along with its columns
listTables(EnsDb.Hsapiens.v86)

## For what species is this database?
organism(EnsDb.Hsapiens.v86)

## What Ensembl version if the database based on?
ensemblVersion(EnsDb.Hsapiens.v86)

## Get some more information from the database
metadata(EnsDb.Hsapiens.v86)

## Get all the sequence names.
seqlevels(EnsDb.Hsapiens.v86)

## List all available gene biotypes from the database:
listGenebiotypes(EnsDb.Hsapiens.v86)

## List all available transcript biotypes:
listTxbiotypes(EnsDb.Hsapiens.v86)

## Update the EnsDb; this is in most instances not necessary at all.
updateEnsDb(EnsDb.Hsapiens.v86)

######    returnFilterColumns
returnFilterColumns(EnsDb.Hsapiens.v86)

## Get protein coding genes on chromosome X, specifying to return
## only columns gene_name as additional column.
genes(EnsDb.Hsapiens.v86, filter=list(SeqNameFilter("X"),
                                      GeneBiotypeFilter("protein_coding")),
      columns=c("gene_name"))
## By default we get also the gene_biotype column as the data was filtered
## on this column.

## This can be changed using the returnFilterColumns option
returnFilterColumns(EnsDb.Hsapiens.v86) <- FALSE
genes(EnsDb.Hsapiens.v86, filter=list(SeqNameFilter("X"),
                                      GeneBiotypeFilter("protein_coding")),
      columns=c("gene_name"))


}
\keyword{classes}
