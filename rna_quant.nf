params.results_dir = "/mnt/data/prokaryota/safonnikova/fbb/res_1/results/"
SRA_list = params.SRA.split(",")
params.index = "/mnt/data/prokaryota/safonnikova/fbb/index/index.idx"


log.info ""
log.info "  Q U A L I T Y   C O N T R O L  "
log.info "================================="
log.info "SRA number         : ${SRA_list}"
log.info "Results location   : ${params.results_dir}"
log.info "Transcriptome index : ${params.index}"

process DownloadFastQ {
  publishDir "${params.results_dir}"

  input:
    val sra

  output:
    path "${sra}/*"

  script:
    """
    /mnt/data/prokaryota/safonnikova/fbb/sratoolkit.3.0.0-ubuntu64/bin/fasterq-dump ${sra} -O ${sra}/
    """
}

process QC {
  input:
    path x

  output:
    path "qc/*"

  script:
    """
    mkdir qc
    /mnt/data/prokaryota/safonnikova/fbb/FastQC/fastqc -o qc $x
    """
}

process MultiQC {
  publishDir "${params.results_dir}"

  input:
    path x

  output:
    path "multiqc_report.html"

  script:
    """
    multiqc $x
    """
}

process Kallisto {
  publishDir "${params.results_dir}/${sra}/"
  
  input:
    val sra
    path x
    
  output:
    path "kallisto/*"
    
  script:
    """
    /media/eternus1/data/prokaryota/safonnikova/fbb/kallisto/build/src/kallisto quant -i "${params.index}" -o kallisto/ $x
    """
}

workflow {
  data = Channel.of( SRA_list )
  DownloadFastQ(data)
  QC( DownloadFastQ.out )
  MultiQC( QC.out.collect() )
  Kallisto( data, DownloadFastQ.out )
}