## // get glapd ref target and pretty highlighted primers ####

library(rentrez)      # NCBI entrez get sequence
library(dplyr)        # R's armyknife
library(ggplot2)      # Plotter BOSS
library(patchwork)    # Plots, ASSEMBLE!
library(stringr)      # String stuff
library(ggrepel)      # labels unmessed
library(tibble)       # rules matrix like neo
library(reshape2)     # melt like butter
library(TmCalculator) # primers TM calc
library(stringr)      # strings stuff
library(spgs)         # dna strings stuff
library(tidyr)        # data juggling BOSS


# inform genome id used as ref
id='NC_054688'
# get glapd conv csv files from containing folder
getname<-list.files(path = '..', pattern = paste0(id,".*csv"), recursive = T, include.dirs = T, full.names = T)
# read glapd conv csv
tab<-read.delim2(file = getname)


#inform set number
# setnum<-4
# setnum<-paste0('Set-',setnum)
# 
# tab$set

for (setnum in tab$set) {
#for (setnum in 'Set-5') {
  
  print(paste(id,'; ',setnum))
  
  tab2<-tab|>
    filter(set==setnum)
  
  # rentrez 
  #https://cran.r-project.org/web/packages/rentrez/index.html
  #https://www.ncbi.nlm.nih.gov/books/NBK25499/table/chapter4.T._valid_values_of__retmode_and/
  
  stt<-as.numeric(tab2$F3.stt)-5
  stp<-as.numeric(tab2$B3.stt+tab2$B3.len)+5
  aseq<-entrez_fetch(db="nuccore", id=id, rettype="fasta",
                     seq_start = stt+1, seq_stop = stp)
  
  sequence <- gsub(">", "", unlist(strsplit(aseq, "\n")))
  header <- sequence[1]
  sequence <- paste(sequence[-1], collapse="")
  
  bases<-data.frame(strsplit(sequence, split = ''))
  names(bases)<-'bases'
  flap<-tab2$F3.stt-1
  
  
  tab2<-tab2 |>
    select(!where(~str_detect(., '_')))|>
    mutate(across(
      contains('len')
      , ~as.numeric(.))
    )|>
    mutate(across(
      contains('stt')
      , ~as.numeric(.) - flap))
  
  #str(tab2)
  
  atitle<-paste0('Start:',stt, ' <<< ',header,' >>> End:',stp)
  
  atitleposition<-nchar(sequence)/2
  
  tagplaces<-(tab2[,grep('stt', names(tab2))])
  tagplaces<-as.data.frame(t(tagplaces))
  names(tagplaces)<-'stt'
  tagplaces[,2]<-as.data.frame(t(tab2[,grep('seq', names(tab2))]))
  
  tagplaces[,3]<-t(as.data.frame((tab2[,grep('stt', names(tab2))])+(tab2[,grep('len', names(tab2))]/2)))
  
  names(tagplaces)<-c('stt','seq', 'center')
  #tagplaces<-sort_by(tagplaces,y = tagplaces$stt)
  
  rownames(tagplaces)<-gsub(x = rownames(tagplaces),pattern = '.stt',replacement = '')
  
  sttfact<-(tab2[,grep('stt', names(tab2))])
  sttfact<-as.data.frame(t(sttfact))
  rownames(sttfact)<-gsub(x = rownames(sttfact),pattern = '.stt',replacement = '')
  sttfact$names<-rownames(sttfact)
  sttfact <- sttfact[order(sttfact$V1),]
  sttfact<-factor(sttfact, levels = sttfact$names)
  
  
  #tagseqs<-as.vector(tab2[,grep('seq', names(tab2))])
  tagseqs<-t(tagplaces$seq)
  colnames(tagseqs)<-rownames(tagplaces)
  
  tagplaces$center
  #tagcenter<-(tab2[,grep('stt', names(tab2))])+(tab2[,grep('len', names(tab2))]/2)
  tagcenter<-t(tagplaces$center)
  colnames(tagcenter)<-rownames(tagplaces)
  
  #tagcols<-c("#F8766D","#EA8331","#FF6A98","#39B600","#00BB4E","#00C1A3","#E76BF3","#00BAE0")
  
  
  
  apdf<-paste0(id,'-',setnum,'_prettyseq.pdf')
  apage<-paste0(id,'-',setnum,'_prettyseq')
  
  #gc()
  
  ## //TM CALC ####
  
  # Get TM from primers
  
  # concentration parameters
  # 1X Buffer Components
  # 20 mM Tris-HCl
  # 10 mM (NH4)2SO4
  # 50 mM KCl
  # 2 mM MgSO4
  # 0.1% Tween® 20
  # pH 8.8@25°C
  
  trisconc=20; kconc=50; mgconc=2
  tmfun<-function(inputseq){
    Tm_GC(inputseq,
          ambiguous=F,
          #variant="Primer3Plus", #Empirical constants coefficient
          Tris=trisconc,
          K=kconc,
          Mg = mgconc,
          mismatch=F, outlist = F)}
  
  
  # tmtab<-as.data.frame((tagseqs))
  # tmtab<-as.data.frame(t(tmtab))
  # names(tmtab)<-'seqs'
  # tmtab
  # tmtab$stt<-tagplaces$stt
  
  tmtab<-tagplaces
  
  tmtab$sense<-paste0('.....',tmtab$seq)
  tmtab$sense<-str_extract(sequence, tmtab$sense)
  
  tmtab$asense<-toupper(reverseComplement(tmtab$seq))
  tmtab$asense<-paste0(tmtab$asense,'.....')
  
  
  tmtab$sense<-str_extract(sequence, tmtab$sense)
  tmtab$asense<-str_extract(sequence, tmtab$asense)
  
  
  tmtab<-tmtab|>
    mutate('add_5'=ifelse(
      is.na(sense), #if is NA
      str_sub(asense,end = -1), # keep 
      str_sub(sense,start = 1)) # else, sub
    )|>
    mutate('add_4'=ifelse(
      is.na(sense), #if is NA
      str_sub(asense,end = -2), # keep 
      str_sub(sense,start = 2)) # else, sub
    )|>
    mutate('add_3'=ifelse(
      is.na(sense), #if is NA
      str_sub(asense,end = -3), # keep 
      str_sub(sense,start = 3)) # else, sub
    )|>
    mutate('add_2'=ifelse(
      is.na(sense), #if is NA
      str_sub(asense,end = -4), # keep 
      str_sub(sense,start = 4)) # else, sub
    )|>
    mutate('add_1'=ifelse(
      is.na(sense), #if is NA
      str_sub(asense,end = -5), # keep 
      str_sub(sense,start = 5)) # else, sub
    )|>
    mutate('add_0'=ifelse(
      is.na(sense), #if is NA
      str_sub(asense,end = -6), # keep 
      str_sub(sense,start = 6)) # else, sub
    )|>
    rownames_to_column(var = 'names')
  
  #tmtab <- tmtab[order(tmtab$stt),]
  
  
  tmtab<-tmtab|>
    mutate('tmadd_5'=round(unlist(lapply(tmtab$add_5, tmfun)), digits = 2))|>
    mutate('tmadd_4'=round(unlist(lapply(tmtab$add_4, tmfun)), digits = 2))|>
    mutate('tmadd_3'=round(unlist(lapply(tmtab$add_3, tmfun)), digits = 2))|>
    mutate('tmadd_2'=round(unlist(lapply(tmtab$add_2, tmfun)), digits = 2))|>
    mutate('tmadd_1'=round(unlist(lapply(tmtab$add_1, tmfun)), digits = 2))|>
    mutate('tmadd_0'=round(unlist(lapply(tmtab$add_0, tmfun)), digits = 2))
  
  if (tmtab$names[7]=='LF') {
    tagcols<-c("#F8766D","#EA8331","#FF6A98","#39B600","#00BB4E","#00C1A3","#E76BF3","#00BAE0")
  }
  
  if (tmtab$names[7]=='LB') {
    tagcols<-c("#F8766D","#EA8331","#FF6A98","#39B600","#00BB4E","#00C1A3","#00BAE0","#E76BF3")
  }
  
  tagcols2<-tagcols[1:ncol(tagcenter)]
  
  ypos<-c(.04 ,.02 ,.02 ,.04 ,.04 ,.02 ,.04 ,.02)
  
  if (sum(str_count(tmtab$names,'LF'))<1) {
    ypos[4]<-0 }
  if (sum(str_count(tmtab$names,'LB'))<1) {
    ypos[6]<-0 }
  
  
  #finalfun<-function() {
  try(dev.off(),silent = T)
  
  pdf(file = apdf, width = nchar(sequence)/5.15, height = 25,family = 'mono', title = apage)
  
  ggplot() +
    
    # TARGET
    geom_text(aes(x = 1:nrow(bases), label = bases$bases, y =.17), size = 7, family = 'mono')+
    
    # PRIMERS SEQUENCES
    geom_label(fill='grey',hjust = 0, vjust=0,label.size = 0,label.r = unit(0,'mm'),
               label.padding = unit(-4,'mm'),family = 'mono',show.legend = F,alpha = 0,
               aes(x = as.numeric(tagplaces$stt)+4.45,y = .2,
                   label = as.list(paste('',tagseqs,''))),col=tagcols2, cex = 7)+
    # PRIMERS NAMES
    geom_label(aes(label=rownames(tagplaces),
                   x=as.numeric(tagcenter)+4, y = .3),fontface='bold',family='mono',
               show.legend = F, size=7, fill=tagcols2)+
    # TARGET HEADER
    annotate(geom = 'text', x = atitleposition, y = .4, fontface='bold',label=atitle, size =8,
             family='mono')+
    
    geom_label(fill='grey',hjust = 0, vjust=0,label.size = 0,label.r = unit(0,'mm'),
               position = position_jitter(height = .04*0, seed = 1, width = 0),
               label.padding = unit(-4,'mm'),family = 'mono',show.legend = F,alpha = 0,
               aes(
                 x=ifelse(is.na(tmtab$asense),
                          as.numeric(tagplaces$stt)+.45,
                          as.numeric(tagplaces$stt)+5.45),
                 
                 y = ypos+.1,
                 label = tmtab$add_5), cex = 7,col=tagcols)+
    
    
    scale_y_continuous(name = '', expand = c(0,0), limits = c(0,.5))+
    scale_x_continuous(n.breaks = nchar(sequence), name = '', breaks = NULL)+
    scale_fill_discrete()+
    
    theme_minimal()+
    theme(plot.margin = unit(rep(0,4), 'cm'))->aa
  
  
  
  
  
  # a1<-aa+
  #   geom_label(fill='grey',hjust = 0, vjust=0,label.size = 0,label.r = unit(0,'mm'),
  #              position = position_jitter(height = .04*0, seed = 1, width = 0),
  #              label.padding = unit(-4,'mm'),family = 'mono',show.legend = F,alpha = 0,
  #              aes(
  #                x=ifelse(is.na(tmtab$asense),
  #                         as.numeric(tagplaces$stt)+.45,
  #                         as.numeric(tagplaces$stt)+5.45),
  #                
  #                y = ypos+.1,
  #                label = tmtab$add_5), cex = 7,col=tagcols)
  
  
  #tmtab$names<-factor(tmtab$names, levels = tmtab$names, labels = tmtab$names)
  
  #tmtab$names<-factor(tmtab$names, levels = tmtab$names, labels = tmtab$names)
  
  
  
  #tmtab$namepos<-factor(tmtab$names, levels = tmtab$names, labels = tmtab$names)
  if (sum(str_count(tmtab$names,'LF'))<1) {
    tmtab<-add_row(tmtab)
    tmtab$names[nrow(tmtab)]='LF'
  }
  
  if (sum(str_count(tmtab$names,'LB'))<1) {
    tmtab<-add_row(tmtab)
    tmtab$names[nrow(tmtab)]='LB'
  }
  
  anames<-c('F3','B3','F2','B2','LF','LB','F1','B1')
  
  #anames<-tmtab$names[match(anames, tmtab$names, nomatch = F)]
  #anames
  
  tmtab$namepos<-factor(tmtab$names, levels = anames, labels = anames)
  
  tmtab[,c(13:19)] %>%
    gather(added, Tm, -namepos)|>
    ggplot()+
    geom_text(aes(x=added, y=Tm, label = Tm, color=Tm), size=10)+
    facet_wrap(~namepos, scales = 'fixed', ncol = 2)+
    scale_color_gradient(low = 'blue', high = 'red')+
    theme(text = element_text(size=30))-> bb
  
  
  final<<-(aa / bb)+plot_layout(heights = c(1,3))
  
  print(final)
  #}
  
  #finalfun()
  gc()
  Sys.sleep(.1)
  gc()
}

dev.off()

